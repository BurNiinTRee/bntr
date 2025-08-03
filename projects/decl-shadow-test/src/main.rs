#![allow(clippy::mutable_key_type)]
use std::{cell::RefCell, collections::HashMap, future::ready, ops::Deref, rc::Rc};

// use arcdom::{ArcDom, SerializableHandle};
use axum::{
    extract::{Request, State},
    http::header::{CONTENT_LENGTH, CONTENT_TYPE},
    middleware::{self, Next},
    response::Response,
};
use futures_util::StreamExt;
use html5ever::{
    Attribute, QualName, local_name, ns, serialize,
    tendril::{SliceExt, StrTendril, TendrilSink},
};
use tokio::{
    sync::{
        mpsc::{self, UnboundedSender},
        oneshot,
    },
    task::LocalSet,
};
use tower_http::services::ServeDir;

mod rcdom;
use rcdom::{Handle, Node, NodeData, RcDom, SerializableHandle};

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
        let stream = body.into_data_stream();

        let mut parser =
            html5ever::parse_document(RcDom::default(), Default::default()).from_utf8();
        let components_text = std::fs::read("site/_.html").unwrap();
        parser.process(components_text.to_tendril());
        stream
            .for_each(|c| {
                parser.process(c.unwrap().to_tendril());
                ready(())
            })
            .await;
        let dom = parser.finish();

        let dom = inline_facet_components(dom);

        let mut out = vec![];
        let document: SerializableHandle = dom.document.clone().into();
        serialize(&mut out, &document, Default::default()).unwrap();
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

fn inline_facet_components(dom: RcDom) -> RcDom {
    let mut component_definitions = HashMap::new();
    find_components_definitions(&dom.document, &mut component_definitions);
    let component_definitions = component_definitions;

    fill_usages(dom.document.clone(), &component_definitions);

    dom
}

fn fill_usages(
    node: Rc<Node>,
    component_definitions: &HashMap<StrTendril, (StrTendril, Rc<Node>)>,
) {
    for (name, definition) in component_definitions {
        let mut usages = Vec::new();
        find_components_uses(node.clone(), name.clone(), &mut usages);
        for usage in usages {
            fill_usages(definition.1.clone(), component_definitions);
            let decl_shadow_dom = Node::new(NodeData::Element {
                name: QualName::new(None, ns!(), local_name!("template")),
                attrs: RefCell::new(vec![Attribute {
                    name: QualName::new(None, ns!(), local_name!("shadowrootmode")),
                    value: definition.0.clone(),
                }]),
                template_contents: RefCell::new(Some(definition.1.clone())),
                mathml_annotation_xml_integration_point: false,
            });
            usage.children.borrow_mut().push(decl_shadow_dom)
        }
    }
}

fn find_components_definitions(
    node: &Node,
    definitions: &mut HashMap<StrTendril, (StrTendril, Handle)>,
) {
    match &node.data {
        NodeData::Element {
            name,
            attrs,
            template_contents,
            ..
        } if name.local == local_name!("template") => {
            // don't recurse into templates
            if let Some(component_attr) = attrs
                .borrow()
                .deref()
                .iter()
                .find(|&attr| &attr.name.local == "component")
                && let Some(contents) = template_contents.borrow().clone()
            {
                let clean_contents = remove_script_elements(Rc::clone(&contents));
                let component_name = component_attr.value.clone();
                definitions
                    .entry(component_name)
                    .or_insert(("closed".parse().unwrap(), clean_contents));
            }
        }
        _ => {
            for child in node.children.borrow().deref() {
                find_components_definitions(child, definitions);
            }
        }
    };
}

fn find_components_uses(node: Rc<Node>, component_name: StrTendril, usages: &mut Vec<Handle>) {
    match &node.data {
        NodeData::Element { name, .. } => {
            // don't recurse into templates
            if &name.local == component_name.as_ref() {
                usages.push(node);
            } else {
                for child in node.children.borrow().deref() {
                    find_components_uses(child.clone(), component_name.clone(), usages);
                }
            }
        }
        _ => {
            for child in node.children.borrow().deref() {
                find_components_uses(child.clone(), component_name.clone(), usages);
            }
        }
    };
}

fn remove_script_elements(node: Rc<Node>) -> Rc<Node> {
    let out = Node::new(match &node.data {
        NodeData::Element {
            name,
            attrs,
            template_contents,
            mathml_annotation_xml_integration_point,
        } => NodeData::Element {
            name: name.clone(),
            attrs: attrs.clone(),
            template_contents: template_contents.clone(),
            mathml_annotation_xml_integration_point: *mathml_annotation_xml_integration_point,
        },
        NodeData::Document => NodeData::Document,
        NodeData::Doctype {
            name,
            public_id,
            system_id,
        } => NodeData::Doctype {
            name: name.clone(),
            public_id: public_id.clone(),
            system_id: system_id.clone(),
        },
        NodeData::Text { contents } => NodeData::Text {
            contents: contents.clone(),
        },
        NodeData::Comment { contents } => NodeData::Comment {
            contents: contents.clone(),
        },
        NodeData::ProcessingInstruction { target, contents } => NodeData::ProcessingInstruction {
            target: target.clone(),
            contents: contents.clone(),
        },
    });

    for child in node.children.borrow().deref() {
        match &child.data {
            NodeData::Element { name, .. } if name.local == local_name!("script") => {}
            _ => {
                out.children
                    .borrow_mut()
                    .push(remove_script_elements(child.clone()));
            }
        };
    }

    out
}
