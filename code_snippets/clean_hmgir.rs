fn remove_single_vertices(gir: &mut HmGIR) {
    let mut keys_to_remove: Vec<NodeSlice> = gir.iter()
        .filter(|&(_, val)| val.is_empty())
        .map(|(key, _)| *key)
        .collect();
    keys_to_remove = keys_to_remove.into_iter()
        .filter(|x| !has_incoming_edges(gir, x))
        .collect();
    for key in keys_to_remove {
        gir.remove(&key);
    }
}
