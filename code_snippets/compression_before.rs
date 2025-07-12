pub fn encode_fasta_symbol(symbol: u8, carrier: u8) -> u8 {
    // make room for the new symbol in the carrier
    let x = carrier << 2;
    // encode the new symbol
    match symbol {
        b'A' => x,
        b'C' => x | 1,
        b'G' => x | 2,
        b'T' => x | 3,
        _ => unreachable!(),
    }
}
