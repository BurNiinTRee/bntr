use axum::body::Bytes;
use futures_util::TryStreamExt;
use html5ever::serialize;
use tendril::{SliceExt, TendrilSink};

use std::future::ready;

use rcdom::{RcDom, SerializableHandle};

mod facet;
mod rcdom;

pub(crate) use facet::FacetInliner;

pub(crate) async fn rewrite_stream<S, R>(stream: S, rewriter: &mut R) -> Result<Vec<u8>, R::Err>
where
    S: TryStreamExt<Ok = Bytes>,
    S::Error: std::fmt::Debug,
    R: DomRewriter,
    R::Err: std::fmt::Debug,
{
    let mut parser = html5ever::parse_document(RcDom::default(), Default::default()).from_utf8();
    stream
        .try_for_each(|c| {
            parser.process(c.to_tendril());
            ready(Ok(()))
        })
        .await
        .unwrap();
    let dom = parser.finish();

    rewriter.rewrite(&dom).await.unwrap();

    let mut out = vec![];
    let document: SerializableHandle = dom.document.clone().into();
    serialize(&mut out, &document, Default::default()).unwrap();
    Ok(out)
}

pub(crate) trait DomRewriter {
    type Err;
    async fn rewrite(&mut self, dom: &RcDom) -> Result<(), Self::Err>;
}

macro_rules! impl_dom_rewriter {
    ($($idx:tt $t:tt),+) => {
        impl<$($t,)+> DomRewriter for ($($t,)+)
        where
            $($t: DomRewriter, <$t as DomRewriter>::Err: std::error::Error + 'static,)+
        {
            type Err = Box<dyn std::error::Error>;

            async fn rewrite(&mut self, dom: &RcDom) -> Result<(), Self::Err> {
                ($(
                    self.$idx.rewrite(&dom).await?,
                )+);
                Ok(())
            }
        }
    };
}

impl_dom_rewriter!(0 A, 1 B, 2 C, 3 D, 4 E);

impl_dom_rewriter!(0 A, 1 B, 2 C, 3 D);

impl_dom_rewriter!(0 A, 1 B, 2 C);

impl_dom_rewriter!(0 A, 1 B);

impl_dom_rewriter!(0 A);
