fn remove_single_vertices(graph: &mut PtGraph) {
    graph.retain_nodes(|g, n| g.neighbors_undirected(n).next().is_some());
}
