#![feature(uniform_paths)]
#![allow(unused_parens)]
#![allow(dead_code)]
#![allow(unused_macros)]

use std::path::Path;
use std::path::PathBuf;
// use std::sync::Arc;
// use std::collections::HashMap;

pub type Line = String;
pub type LineVec = Vec <Line>;
pub type ElementVec = Vec <Element>;
pub type PropertyVec = Vec <Property>;

pub enum Element {
    N (Node),
    B (Block),
    T (Text),
    L (List),
}

pub struct Root {
    path: Option <PathBuf>,
    property_vec: PropertyVec,
    body: ElementVec,
}

pub struct Node {
    headline: Line,
    property_vec: PropertyVec,
    body: ElementVec,
}

pub struct List {
    list_type: ListType,
    content: Vec <(Text, Option <List>)>,
}

pub enum ListType {
    DashMark,
    PlusMark,
    Numbered,
}

pub struct Text {
   line_vec: LineVec,
}

pub struct Block {
   block_type: BlockType,
   property_vec: PropertyVec,
   line_vec: LineVec,
}

pub enum BlockType {
    CodeBlock,
}

pub struct Property {
    name: String,
    value: String,
}
