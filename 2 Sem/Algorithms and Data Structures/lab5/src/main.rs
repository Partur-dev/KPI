struct Node {
    value: char,
    children: Vec<Node>,
}

impl Node {
    fn new(value: char) -> Self {
        Node {
            value,
            children: Vec::new(),
        }
    }

    fn add_child(&mut self, child: Node) {
        self.children.push(child);
    }

    fn print_leaves(&self) {
        if self.children.is_empty() {
            print!("{} ", self.value);
        } else {
            for child in &self.children {
                child.print_leaves();
            }
        }
    }
}

fn main() {
    //        'A'
    //       /   \
    //     'B'   'C'
    //     / \     \
    //  'D'  'E'   'F'

    let mut root = Node::new('A');

    let mut b = Node::new('B');
    b.add_child(Node::new('D'));
    b.add_child(Node::new('E'));

    let mut c = Node::new('C');
    c.add_child(Node::new('F'));

    root.add_child(b);
    root.add_child(c);

    root.print_leaves();
    println!()
}
