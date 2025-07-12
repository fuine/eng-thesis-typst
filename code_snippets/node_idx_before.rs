fn get_node_idx(&self, node: NodeSlice) -> NodeIndex {
    let off = node.offset();
    // count set bits up to the given offset
    NodeIndex::new(self.fb.count_ones(..off))
}
