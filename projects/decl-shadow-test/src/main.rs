use std::future::ready;

// use arcdom::{ArcDom, SerializableHandle};
use axum::{
    body::Bytes,
    extract::{Request, State},
    http::header::{CONTENT_LENGTH, CONTENT_TYPE},
    middleware::{self, Next},
    response::Response,
};
use dom_rewriter::{FacetInliner, rewrite_stream};
use futures_util::{StreamExt, stream};
use tokio::{
    sync::{
        mpsc::{self, UnboundedSender},
        oneshot,
    },
    task::LocalSet,
};
use tower_http::services::ServeDir;

mod dom_rewriter;

#[tokio::main(flavor = "current_thread")]
async fn main() {
    let local_set = LocalSet::new();
    let (send, mut recv) = mpsc::unbounded_channel();
    let app = axum::Router::new()
        .fallback_service(ServeDir::new("site"))
        .layer(middleware::from_fn_with_state(send, ssr_facet));

    local_set.spawn_local(async move {
        while let Some((response, ret)) = recv.recv().await {
            ret.send(rewriter(response).await).unwrap();
        }
    });

    local_set
        .run_until(async move {
            axum::serve(
                tokio::net::TcpListener::bind("0.0.0.0:8080").await.unwrap(),
                app,
            )
            .await
            .unwrap()
        })
        .await
}

async fn rewriter(response: Response) -> Response {
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

        let out = rewrite_stream(stream, FacetInliner).await.unwrap();
        parts.headers.insert(CONTENT_LENGTH, out.len().into());
        Response::from_parts(parts, out.into())
    } else {
        response
    }
}

async fn ssr_facet(
    State(responder): State<UnboundedSender<(Response, oneshot::Sender<Response>)>>,
    req: Request,
    next: Next,
) -> Response {
    let response = next.run(req).await;
    let (send, ret) = oneshot::channel();
    responder.send((response, send)).unwrap();
    ret.await.unwrap()
}
