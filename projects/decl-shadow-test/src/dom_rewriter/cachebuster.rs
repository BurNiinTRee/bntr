use std::{
    collections::HashMap,
    convert::Infallible,
    fs,
    ops::Deref,
    path::{Path, PathBuf},
};

use base64::{Engine, prelude::BASE64_URL_SAFE};
use sha2::{Digest as _, Sha256};
use tendril::StrTendril;

use super::{
    DomRewriter,
    rcdom::{Handle, NodeData},
};

pub(crate) struct Cachebuster {
    pub base_path: PathBuf,
}

impl DomRewriter for Cachebuster {
    type Err = Infallible;

    async fn rewrite(&mut self, dom: &super::rcdom::RcDom) -> Result<(), Self::Err> {
        fix_link_elements(dom.document.clone(), &self.base_path);
        Ok(())
    }
}

pub(crate) fn fix_link_elements(node: Handle, base_path: &Path) {
    match &node.data {
        NodeData::Element {
            name,
            attrs,
            template_contents,
            ..
        } => {
            // don't recurse into templates
            if &name.local == "link" {
                if let Some(attr) = attrs
                    .borrow_mut()
                    .iter_mut()
                    .find(|a| &a.name.local == "href")
                    && is_local_url(&attr.value)
                {
                    process_url(&mut attr.value, base_path);
                }
            } else if &name.local == "script"
                && let Some(_attr) = attrs
                    .borrow_mut()
                    .iter_mut()
                    .find(|a| &a.name.local == "type" && *a.value == *"importmap")
            {
                if let NodeData::Text { contents } =
                    &node.children.borrow().iter().next().unwrap().data
                {
                    process_importmap(&mut contents.borrow_mut(), base_path)
                }
            } else if &name.local == "script"
                && let Some(attr) = attrs
                    .borrow_mut()
                    .iter_mut()
                    .find(|a| &a.name.local == "src")
                && is_local_url(&attr.value)
            {
                process_url(&mut attr.value, base_path);
            } else if &name.local == "style" {
                if let NodeData::Text { contents } =
                    &node.children.borrow().iter().next().unwrap().data
                {
                    process_css_imports(&mut contents.borrow_mut(), base_path);
                }
            } else {
                if let Some(child) = &*template_contents.borrow() {
                    fix_link_elements(child.clone(), base_path);
                }

                for child in node.children.borrow().deref() {
                    fix_link_elements(child.clone(), base_path);
                }
            }
        }
        _ => {
            for child in node.children.borrow().deref() {
                fix_link_elements(child.clone(), base_path);
            }
        }
    };
}
fn is_local_url(url: &str) -> bool {
    matches!(
        url::Url::parse(url),
        Err(url::ParseError::RelativeUrlWithoutBase)
    )
}

fn process_url(url: &mut StrTendril, base_path: &Path) {
    let mut file_path = base_path.to_owned();
    file_path.push(url.strip_prefix("/").unwrap_or(url));
    let mut file = fs::File::open(file_path).unwrap();
    let mut hasher = Sha256::new();
    std::io::copy(&mut file, &mut hasher).unwrap();
    let digest = BASE64_URL_SAFE.encode(hasher.finalize());

    if url.contains("?") {
        url.push_slice(&format!("&cachebust={digest}"));
    } else {
        url.push_slice(&format!("?cachebust={digest}"));
    }
}

fn process_importmap(import_map_tendril: &mut StrTendril, base_path: &Path) {
    #[derive(serde::Deserialize, serde::Serialize, Debug)]
    struct ImportMap {
        imports: HashMap<String, String>,
    }

    let mut import_map: ImportMap = serde_json::from_str(import_map_tendril).unwrap();
    for value in import_map.imports.values_mut() {
        let mut tendril = value.clone().parse().unwrap();
        process_url(&mut tendril, base_path);
        *value = tendril.into();
    }
    *import_map_tendril = serde_json::to_string_pretty(&import_map)
        .unwrap()
        .parse()
        .unwrap();
}

fn process_css_imports(css: &mut StrTendril, base_path: &Path) {
    let mut lines = css.lines();
    let mut new_css = StrTendril::new();
    while let Some(line) = lines.next() {
        new_css.push_tendril(&line.parse().unwrap());
        new_css.push_char('\n');
        if line.contains("begin assetreplace") {
            let line_to_process = lines.next().unwrap();
            let path = line_to_process.trim();
            let path = path.strip_prefix('"').unwrap_or(path);
            let path = path.strip_suffix('"').unwrap_or(path);

            let mut path_tendril = path.parse().unwrap();
            process_url(&mut path_tendril, base_path);
            new_css.push_char('"');
            new_css.push_tendril(&path_tendril);
            new_css.push_char('"');
            new_css.push_char('\n');
        }
    }
    *css = new_css;
}
