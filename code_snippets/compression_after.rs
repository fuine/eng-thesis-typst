#[inline]
pub fn encode_fasta_symbol(mut symbol: u8, mut carrier: u8) -> u8 {
    // make room for the new symbol
    carrier <<= 2;

    // make 'A' 0
    symbol -= b'A';
    // shift so that second bit is first
    symbol >>= 1;
    let c_masked = (symbol & 2) >> 1;
    let a_masked = (symbol & 8) >> 3;
    let d_masked = symbol & 1;
    let first_bit = (c_masked ^ 1) & d_masked;
    let second_bit = c_masked | a_masked;
    carrier | ((second_bit << 1) | first_bit)
}

