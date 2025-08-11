use std::{
    convert::Infallible,
    fs,
    future::ready,
    io::{Read, Write},
    path::PathBuf,
};

use axum::body::Bytes;
use futures_util::stream::once;

use crate::{Cachebuster, FacetInliner, dom_rewriter::rewrite_stream};

#[derive(Clone)]
pub(crate) struct Settings {
    pub source_dir: PathBuf,
    pub output_dir: PathBuf,
}

impl Settings {
    pub fn new() -> Self {
        Self {
            source_dir: PathBuf::from("./site"),
            output_dir: PathBuf::from("./out"),
        }
    }
}

impl Default for Settings {
    fn default() -> Self {
        Self::new()
    }
}

pub(crate) async fn build(settings: Settings, html_prefix: &[u8]) {
    let _ = fs::remove_dir_all(&settings.output_dir);
    copy_rewrite(settings, html_prefix).await;
}

async fn copy_rewrite(settings: Settings, html_prefix: &[u8]) {
    for entry in fs::read_dir(&settings.source_dir).unwrap() {
        let entry = entry.unwrap();
        let ty = entry.file_type().unwrap();
        if ty.is_dir() {
            let mut new_settings = settings.clone();
            new_settings.source_dir.push(entry.file_name());
            new_settings.output_dir.push(entry.file_name());
            Box::pin(copy_rewrite(new_settings, html_prefix)).await;
        } else if entry.path().extension().and_then(|e| e.to_str()) == Some("html") {
            let mut contents = html_prefix.to_vec();
            let mut file = fs::File::open(entry.path()).unwrap();
            file.read_to_end(&mut contents).unwrap();
            let out = rewrite_stream(
                once(ready(Result::<_, Infallible>::Ok(Bytes::from(contents)))),
                &mut (Cachebuster, FacetInliner),
            )
            .await
            .unwrap();

            let mut out_path = settings.output_dir.clone();
            out_path.push(entry.file_name());

            fs::create_dir_all(&settings.output_dir).unwrap();
            let mut out_file = fs::File::create(out_path).unwrap();
            out_file.write_all(&out).unwrap();
        } else {
            fs::create_dir_all(&settings.output_dir).unwrap();
            let mut out_path = settings.output_dir.clone();
            out_path.push(entry.file_name());
            fs::copy(entry.path(), out_path).unwrap();
        }
    }
}
