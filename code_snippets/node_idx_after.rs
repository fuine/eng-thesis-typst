#[inline]
fn get_node_idx(&self, node: NodeSlice) -> NodeIndex {
    let off = node.offset();
    // get the index of the last region and number of bits that need to be
    // counted via `count_ones`
    let (last_region, last_block_offset) = (off / 512, off % 512);
    // sum regions
    let mut idx = self.regions[..last_region].iter().sum::<Idx>();
    // count remainder
    if last_block_offset != 0 {
        idx += self.fb.count_ones(last_region * 512..off) as Idx;
    }
    NodeIndex::new(idx as usize)
}
