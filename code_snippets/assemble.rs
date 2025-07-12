/// Public API for assemblers.
pub trait Assemble {
    /// Assembles given data using specified `Graph` and writes results into the
    /// output file.
    fn assemble<P: AsRef<Path>, G: Graph>(config: Config<P>);

    /// Assembles given data using specified `GIR` and `Graph`, and writes
    /// results into the output file.
    fn assemble_with_gir<P: AsRef<Path>, G, T: GIR>(config: Config<P>)
        where G: Graph + Convert<T>;
}
