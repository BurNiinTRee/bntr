use std::future::ready;

use axum::{
    body::Bytes,
    extract::{Request, State},
    http::header::{CACHE_CONTROL, CONTENT_LENGTH, CONTENT_TYPE},
    middleware::{self, Next},
    response::Response,
};
use futures_util::{StreamExt, stream};
use tokio::sync::{
    mpsc::{self, UnboundedSender},
    oneshot,
};
use tower_http::services::ServeDir;

use crate::dom_rewriter::{DomRewriter, rewrite_stream};

pub(crate) struct Settings {
    pub port: u16,
}

impl Settings {
    pub fn new() -> Self {
        Self { port: 8080 }
    }
}

pub(crate) async fn run_server(http_dom_rewriter: HttpDomRewriter, settings: Settings) {
    let app = axum::Router::new()
        .fallback_service(ServeDir::new("site"))
        .layer(middleware::from_fn_with_state(http_dom_rewriter, ssr_facet))
        .layer(middleware::from_fn(set_cache_control));
    axum::serve(
        tokio::net::TcpListener::bind(("0.0.0.0", settings.port))
            .await
            .unwrap(),
        app,
    )
    .await
    .unwrap()
}

#[derive(Clone)]
pub(crate) struct HttpDomRewriter {
    pub(crate) handle: UnboundedSender<(Response, oneshot::Sender<Response>)>,
}

impl HttpDomRewriter {
    pub(crate) fn new<R>(mut rewriter: R) -> (Self, impl Future<Output = ()>)
    where
        R: DomRewriter,
        R::Err: std::fmt::Debug,
    {
        let (send, mut recv) = mpsc::unbounded_channel();

        (Self { handle: send }, async move {
            while let Some((response, ret)) = recv.recv().await {
                ret.send(rewrite(&mut rewriter, response).await).unwrap();
            }
        })
    }

    pub(crate) async fn rewrite(&self, response: Response) -> Response {
        let (send, ret) = oneshot::channel();
        self.handle.send((response, send)).unwrap();
        ret.await.unwrap()
    }
}

pub(crate) async fn rewrite<R>(rewriter: &mut R, response: Response) -> Response
where
    R: DomRewriter,
    R::Err: std::fmt::Debug,
{
    if response
        .headers()
        .get(CONTENT_TYPE)
        .and_then(|hv| hv.to_str().ok())
        .map(|ct| ct.contains("text/html"))
        .unwrap_or(false)
    {
        let (mut parts, body) = response.into_parts();
        let components_text = std::fs::read("site/_.html").unwrap();
        let stream =
            stream::once(ready(Ok(Bytes::from(components_text)))).chain(body.into_data_stream());

        let out = rewrite_stream(stream, rewriter).await.unwrap();
        parts.headers.insert(CONTENT_LENGTH, out.len().into());
        Response::from_parts(parts, out.into())
    } else {
        response
    }
}

pub(crate) async fn ssr_facet(
    State(rewriter): State<HttpDomRewriter>,
    req: Request,
    next: Next,
) -> Response {
    let response = next.run(req).await;
    rewriter.rewrite(response).await
}

async fn set_cache_control(req: Request, next: Next) -> Response {
    let add_cache_control = req
        .uri()
        .query()
        .iter()
        .flat_map(|q| q.split('&'))
        .flat_map(|q| q.split_once('='))
        .any(|pair| pair.0 == "cachebust");
    let mut res = next.run(req).await;
    if add_cache_control {
        res.headers_mut().insert(
            CACHE_CONTROL,
            "max-age=31536000,immutable".try_into().unwrap(),
        );
    } else {
        res.headers_mut()
            .insert(CACHE_CONTROL, "no-cache".try_into().unwrap());
    }
    res
}
