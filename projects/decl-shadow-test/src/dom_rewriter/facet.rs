#![allow(clippy::mutable_key_type)]
use std::{cell::RefCell, collections::HashMap, convert::Infallible, ops::Deref, rc::Rc};

use html5ever::{Attribute, QualName, local_name, ns};
use tendril::StrTendril;

use super::{
    DomRewriter,
    rcdom::{Handle, Node, NodeData, RcDom},
};

pub(crate) struct FacetInliner;

impl DomRewriter for FacetInliner {
    type Err = Infallible;

    async fn rewrite(&mut self, dom: &RcDom) -> Result<(), Self::Err> {
        inline_facet_components(dom);
        Ok(())
    }
}

pub(crate) fn inline_facet_components(dom: &RcDom) -> &RcDom {
    let mut component_definitions = HashMap::new();
    let mut global_mixins = Vec::new();
    find_components_definitions(
        &dom.document,
        &mut component_definitions,
        &mut global_mixins,
    );
    let component_definitions = component_definitions;
    let global_mixins = global_mixins;

    fill_usages(dom.document.clone(), &component_definitions, &global_mixins);

    dom
}

fn fill_usages(
    node: Rc<Node>,
    component_definitions: &HashMap<StrTendril, (StrTendril, Rc<Node>)>,
    global_mixins: &Vec<Handle>,
) {
    for (name, definition) in component_definitions {
        let mut usages = Vec::new();
        find_components_uses(node.clone(), name.clone(), &mut usages);
        for usage in usages {
            fill_usages(definition.1.clone(), component_definitions, global_mixins);
            let decl_shadow_dom = Node::new(NodeData::Element {
                name: QualName::new(None, ns!(), local_name!("template")),
                attrs: RefCell::new(vec![Attribute {
                    name: QualName::new(None, ns!(), local_name!("shadowrootmode")),
                    value: definition.0.clone(),
                }]),
                template_contents: RefCell::new(Some(definition.1.clone())),
                mathml_annotation_xml_integration_point: false,
            });
            for mixin in global_mixins {
                decl_shadow_dom.children.borrow_mut().push(mixin.clone());
            }
            usage.children.borrow_mut().push(decl_shadow_dom);
        }
    }
}

pub(crate) fn find_components_definitions(
    node: &Node,
    definitions: &mut HashMap<StrTendril, (StrTendril, Handle)>,
    global_mixins: &mut Vec<Handle>,
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
                .iter()
                .find(|&attr| &attr.name.local == "component")
                && let Some(contents) = template_contents.borrow().clone()
            {
                let clean_contents = remove_script_elements(contents.clone());
                let component_name = component_attr.value.clone();
                let shadowroot_mode = attrs
                    .borrow()
                    .iter()
                    .find(|&attr| &attr.name.local == "shadow")
                    .map(|attr| attr.value.clone())
                    .unwrap_or_else(|| "closed".parse().unwrap());
                definitions
                    .entry(component_name)
                    .or_insert((shadowroot_mode.clone(), clean_contents));
            } else if let Some(_) = attrs
                .borrow()
                .iter()
                .find(|&attr| &attr.name.local == "mixin")
                && let Some(_) = attrs
                    .borrow()
                    .iter()
                    .find(|&attr| &attr.name.local == "global")
                && let Some(contents) = template_contents.borrow().clone()
            {
                let clean_contents = remove_script_elements(Rc::clone(&contents));
                global_mixins.push(clean_contents)
            }
        }
        _ => {
            for child in node.children.borrow().deref() {
                find_components_definitions(child, definitions, global_mixins);
            }
        }
    };
}

pub(crate) fn find_components_uses(
    node: Rc<Node>,
    component_name: StrTendril,
    usages: &mut Vec<Handle>,
) {
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

pub(crate) fn remove_script_elements(node: Rc<Node>) -> Rc<Node> {
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
