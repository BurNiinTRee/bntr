mod dom_rewriter;
mod server;
mod ssg;

use dom_rewriter::{Cachebuster, FacetInliner};
use tokio::{select, task::LocalSet};

#[tokio::main(flavor = "current_thread")]
async fn main() {
    let mut args = std::env::args().skip(1);
    while let Some(arg) = args.next() {
        match arg.as_str() {
            "serve" => {
                let mut settings = server::Settings::new();
                while let Some(arg) = args.next() {
                    match arg.as_str() {
                        "-p" | "--port" => {
                            settings.port = args.next().unwrap().parse().unwrap();
                        }
                        _ => panic!("Unrecognized argument to `serve`."),
                    }
                }
                let local_set = LocalSet::new();
                let (http_dom_rewriter, local_task) = server::HttpDomRewriter::new((
                    Cachebuster {
                        base_path: "./site".into(),
                    },
                    FacetInliner,
                ));

                local_set.spawn_local(local_task);

                select! {
                    _ = local_set => (),
                    _ = server::run_server(http_dom_rewriter, settings) => (),
                }
            }
            "build" => {
                let mut settings = ssg::Settings::default();
                while let Some(arg) = args.next() {
                    match arg.as_str() {
                        "-s" | "--source" => settings.source_dir = args.next().unwrap().into(),
                        "-o" | "--out" => settings.output_dir = args.next().unwrap().into(),
                        _ => panic!("Unrecognized argument to `build`."),
                    }
                }

                let _guard = LocalSet::new().enter();
                let mut html_prefix_path = settings.source_dir.clone();
                html_prefix_path.push("_.html");
                let html_prefix = std::fs::read(html_prefix_path).unwrap();
                ssg::build(settings, &html_prefix).await;
            }
            _ => panic!("Unrecognized argument."),
        }
    }
}
