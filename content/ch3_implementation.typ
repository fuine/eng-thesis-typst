#import "../utils.typ": (
  algorithm, code-listing-figure, code-listing-file, comment, larrow, my-colors,
)
#import "@preview/cetz:0.4.0": canvas, decorations.brace, draw
#import draw: content, rect
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import "@preview/oxifmt:1.0.0": strfmt

= Implementation
<implementation>
== Language and tooling
<language-and-tooling>
_katome_ project has been entirely written in the Rust language. Below I give a short
overview on Rust, its main features and reasons why I chose it for my project.

=== Rust programming language
<rust-programming-language>
Rust is a new programming language introduced by Mozilla Research. It is built around
three main concepts: memory safety, concurrency and speed. The first stable release of
the Rust @rust compiler was introduced on May 15th, 2015. It is currently developed in
6-week cycle, in a 3-staged approach. At the end of each cycle, a new stable version of
the compiler is released. The Rust language is moderated by the entire community via the
process of RFCs (Request For Comments). The fast pace of development, together with the
unique moderation approach, makes Rust less prone to stagnation. This is an unusual way
of creating the language, as most well established languages are governed by special
committees @cppcom @javacom and new versions of standards are released less frequently.
Despite a rapid release cycle, Rust is meant to be a stable language, which indicates
stability and a lack of breaking changes between stable releases of the compiler.

=== Rust's main features
<rusts-main-features>
===== Memory safety
Memory safety has always been a problem in low-level languages like C or C++. It
influences both security of the programs @war, as well as soundness of the written
algorithms @benign. This problem can also be triggered by compilers themselves:

#quote(block: true)[
  ($...$) conventional compilers can, and do, on rare occasions, introduce
  data races, producing completely unexpected (and unintended) results
  without violating the letter of the specification.
]
as described by #cite(<concmodel>, form: "prose"). Rust resolves these
problems during compilation by introducing a new module called the
'borrow checker'. The Rust language enforces several axioms:

- all data is immutable by default;

- there is always exactly one owner of the piece of data;
- if there is an active mutable reference, then nobody else can have active access to
  the data;
- if there is an active shared, immutable reference, then every other active access to
  the data is also a shared, immutable reference.

These rules allow the borrow checker to satisfy memory safety (most notably it
eliminates errors such as buffer overflow, use-after-free, double dereference,
dereferencing null pointer). Notably, this solution is based purely on compile-time
static analysis and does not introduce run-time overhead. Such an approach leads to very
high performance implementations. It also enforces a sound memory model of the written
algorithm, because any error detected by the borrow checker will fail the compilation
process.

===== Strict typesystem
<strict-typesystem>
Rust's type system is inspired by the ML family of languages. Notable mentions among its
features are:

- algebraic data types;

- pattern matching;
- generics;
- traits;
- automatic type inference for variables.

Traits are similar to the concept of interface known in C/C++, but are baked into the
typesystem itself. They allow programmer to enforce the specific functionality for a
given type in generic functions/methods. User-defined types are called `struct`s in the
language, and are similar to the C structures. Rust does not have a concept of
inheritance, but similar effects can be achieved by trait compositions. \
The language's type system is also used by the borrow checker to enforce a lack of data
races in the written code. It does so by introducing two marker traits: `Send` and
`Sync` which indicate that any type implementing them is safe to share between threads
in the described manner.

===== Performance
<performance>
The Rust language is competitive against the C family of languages in terms of its
performance @cantrip @benchgame. As described in @rusts-main-features, Rust's memory
model makes it possible for the developer to use multi threading without the burden of
typical problems that occur in multi threaded code bases - most notably data races.

=== Development environment
<dev_env>
===== Cargo
<cargo>
Cargo is a package manager and build tool for Rust. It was created in order to
standardize management of external libraries during compilation of the project. Unlike
similar tools in C++ it can automatically fetch dependencies either from `Crates.io` or
provided URLs. Once fetched, dependencies will get compiled and linked automatically
against the project, using the local compiler. Dependencies are described by the local
file `Cargo.toml` in TOML language @toml. Cargo supports versioning.

_katome_ uses Cargo as it's building tool. It is also used to compile and run tests,
format the code with respect to the specified style and perform a static analysis of the
code. Cargo enables easy cross-compilation of both libraries and binary executables for
officially supported platforms @platforms.

===== Crates.io
Libraries in Rust are called `crates`. Crates.io is the global repository of crates,
which allows tools like Cargo for trivial resource management. It supports versioning.
One of its main features is immutability - once a crate is published it cannot be
removed. This fact guarantees non-breakage of existing sources, which rely on specific
crates being hosted on `Crates.io`.

=== Crates
In this section I list notable crates, without which implementation of _katome_ would
have been unachievable, or significantly harder, in the limited time span of this
project.

===== petgraph
`petgraph` @petgraph is a graph structure library. It provides a clean API for graph
creation/modification, as well as various graph algorithms. Its `Graph` structure is the
core of `PtGraph` collection in _katome_ sources.

===== fixedbitset
`fixedbitset` @fixedbitset provides simple implementation of the fixed-size set of bits.
Its main features are low memory overhead and functional API. Some of the methods in the
API have been implemented as the part of this thesis.

===== metrohash
To achieve the best possible performance for hashing compressed data (used in various
hash maps and hash sets throughout modules and collections in _katome_) I settled upon
`metrohash` @metrohash (Rust implementation @rust_metrohash) hasher, as it provides the
lowest run-time from all of the non-cryptographic hash functions that I tested. Tests
have been devised on a fixed number of test organisms (see @eval:performance).
Other tested hash functions are xxHash, SeaHash, FarmHash, SipHash, FnvHash.


===== parking\_lot
To allow parallel/concurrent algorithms for being implemented within the _katome_
library, the global vector of read data (detailed description in @slices and @global_vec)
must be synchronized between
threads/processes. In Rust all synchronization primitives are wrappers around data to
synchronize, rather than being standalone objects (although they can be used as classic
synchronization primitives, by using them with `()` type). This means that global vector
must be wrapped in some kind of synchronization primitive, which will be accessed every
time the vector is being read or written to. Due to the fact that various algorithms
heavily rely on the data in the global vector during graph creation and collapse, it is
crucial that chosen synchronization primitive has the best possible performance, as even
for single thread programs this primitive needs to be locked/unlocked on each access. I
decided to use multiple readers/single writer lock (`RwLock`) to exploit the fact, that
vector is more often read than written to. \
Rust's standard library contains an implementation of this lock, however I found it
lackluster in terms of efficiency. `parking_lot` @parking_lot crate provides its own
implementation of `RwLock`, which has proven to be significantly faster.

== Architecture
<architecture>
_katome_ is divided into library and binary executable. This design allows users to
create different front ends to the `katome` assembler, possibly using different
implementers of the `Assemble` trait.

=== Library
<library>
_katome_ has a modular design. The entire library is written around the concept of De
Bruijn Graph and algorithms that modify it. Such a graph can be represented by a
collection from the collections module @collections. By design graph does not store read
sequences, but uses specialized indices called `slices`, which represent given sequence.
It therefore separates graph representation from genomic data, enabling efficient
reallocation strategies for collections. \
Modules layout of the _katome_ crate is presented on the
@modules.

#figure(
  image("../images/modules_vert.svg", width: 70.0%),
  caption: [Modules layout of the _katome_ crate.],
)<modules>

==== slices
<slices>
When graph representation is created each k-mer should be stored in memory. In order to
achieve this _katome_ stores read k-mers in the global vector of reads. A single read is
represented as `boxed slice` -- a special construct in the Rust language, which can be
thought of as an array on the heap. This global vector should only be interacted with
via `Slice`s. A `Slice` is a structure which wraps operations on global vector, most
notably providing efficient hashing, comparison and decompression for the underlying
read. More detailed description of the global vector of reads is provided in
@global_vec.

_katome_ provides two types of `Slice`s: `NodeSlice` and `EdgeSlice`. During creation of
De Bruijn graph `NodeSlice`s are used to provide information about already seen nodes
(reads of sequences with length $k - 1$, where $k$ is the length of k-mer). `EdgeSlice`s
represent edges in De Bruijn graph. It is important to note that these edges do not have
any fixed size, but can be of any length greater than 2.


==== compress
<compress>
Genomic data that is provided as an input to the compiler tends to use a lot of on-disk
memory. When reading this data into RAM it is crucial to make it as small as possible.
Small amount of data will allow for more data fitting in the cache, as well as making
hashing and comparison significantly faster. Because of those reasons read data in
_katome_ is compressed. Compression assumes that reads exclusively comprise of 4 basic
nucleotides: A, C, G, T. This assumption makes it possible to encode single nucleotide
on 2 bits. Such an approach can approximately compress input data fourfold. More
thorough overview of compression algorithms and compressed data representation is given
in the @global_vec.

==== collections
<collections>
This module defines collections used in the assembler. Most notably there is distinction
between two types of collections --- `Graph` and `GIR`. `Graph` is a trait which
describes De Bruijn Graph representation in the application. `GIR` stands for Graph's
Intermediate Representation, and serves as a collection which is used to filter out
noisy/incorrect data before creating `Graph`. All types of collection implement `Build`
trait, which enables building these collections based on supplied files. Additionally
`GIR` implementers can provide a method to convert `GIR` collection to `Graph`
collection. \ Currently _katome_ provides one implementation of `Graph` for the
representation based on `petgraph` library Graph, called `PtGraph`. It also provides two
`GIR` implementations based on `HashMap` and `HashSet` from Rust's standard library,
which are respectively called `HsGIR` and `HmGIR`. \
It is assumed that any `Graph` trait implementer will represent De Bruijn graph by
storing `EdgeSlice`s for the respective edges.

==== algorithms
<algorithms>
All algorithms that are available in the process of DNA assembly are described in this
module. Notably each of them is represented as a trait which allows for easy
implementation of algorithms for new collections. All algorithms are implemented for
`PtGraph`. Algorithms do not provide generic implementations based on `Graph` trait,
because such approach would hurt the performance for new implementations of `Graph`.
This can be observed in the implementation of `Clean` trait, which provides two methods
--- one for removal of single, disconnected vertices and one for removal of edges with
weights below specified threshold. `Clean` trait is implemented for both `PtGraph` and
`HmGIR` collections and those implementations significantly vary, as seen in the
@clean_ptgraph and @clean_hmgir.

#code-listing-file(
  "clean_ptgraph.rs",
  caption: [`remove_single_vertices()` implementation for `PtGraph`],
)<clean_ptgraph>

#code-listing-file(
  "clean_hmgir.rs",
  caption: [`remove_single_vertices()` implementation for `HmGIR`],
)<clean_hmgir>

==== asm
This module should be regarded as the entry point for the library, as it defines the
trait `Assemble`. `Assemble` exposes a generic API for genome assembly, as shown in
@assemble.

#code-listing-file(
  "assemble.rs",
  caption: [Trait describing public API for genome assembly in _katome_ library.],
)<assemble>
This trait should be used when creating custom assemblers to allow for a robust, unified
API.

Currently there's only one struct which implements `Assemble` trait ---
`BasicAssembler`. This struct is used by the client application to provide genome
assembling functionality.

==== stats
<stats>
`stats` module provides trait `Stats` and implementation of this trait for all
collections and `SerializedContigs`. Trait provides a simple API, which allows user for
acquiring various statistics for collections and generated contigs. These statistics are
used throughout log of the `BasicAssembler`.

==== prelude
<prelude>
Prelude holds definitions for all fundamental types used throughout library, as well as
definition of global static variables and constants. It also provides a method which
changes variable `K_SIZE` (size of the k-mer), along with other related global variables
(`K1_SIZE` and `COMPRESSED_K1_SIZE`).

==== config
<config>
Struct used for configuration (`Config`) of the assembler is implemented in this module.
Trait `RustcDecodable` is derived for this struct, which means that it can be
deserialized from several different configuration files. Currently `TOML` @toml format
is used for the client application. Example of the configuration file is shown in
@config_file.

=== Binary executable
<binary-executable>
Binary executable provides a thin wrapper around _katome_ crate. It parses config file
into the `Config` struct and runs assembler using the `BasicAssembler` implementation of
the `Assemble` trait.

== Code statistics
<code-statistics>
Following code statistics were generated by the 'loc' @loc tool.

```
--------------------------------------------------------------------------------
 Language             Files        Lines        Blank      Comment         Code
--------------------------------------------------------------------------------
 Rust                    32         5670          432          780         4458
 YAML                     1           26            1            0           25
 Toml                     2           70           11           45           14
--------------------------------------------------------------------------------
 Total                   35         5766          444          825         4497
--------------------------------------------------------------------------------
```

Statistics below show total number of insertions and deletions made in the project, as
reported by `Git` version control system, excluding statistics for test data files.

```
16565 insertions(+), 10901 deletions(-), 5664 net
```

== Testing
<testing>
Tests were implemented using Rust's built-in testing features. Unit tests are placed on
the bottom of the file they test, which is a standard pattern in Rust. Additionally each
algorithm is tested in integration tests --- one test file per algorithm. Integration
tests are generally performed in the following steps:

+ collections are built on the various test data;

+ specific algorithm is run on the collection;
+ statistics are compared against correct results.

Due to trait-based design of algorithms (details in @algorithms) it is possible to test
different implementations of the algorithms --- results for different implementations
should not differ. In order to aid the process of testing each algorithm's
implementations a set of macros were created. Each test file provides two macros:
`test_graph!()` and `test_gir()`. These are used to test collection which implements
both the algorithm that file is testing and `Graph` or `GIR` traits accordingly.

#code-listing-file("test_macros.rs", caption: [Example usage of test macros])

During development continuous integration services were used to regularly build and test
project on three tier 1 @platforms 64 bit platforms -- Linux, Windows and MacOS, with
all stages of compiler -- stable, beta, nightly. In total 66 unit tests and 43
integration tests were created. Code coverage is estimated to be 89%.

== Efficient memory layout
<efficient-memory-layout>
The main goal of the thesis is the reduction of the memory used by the assembler.
Important aspect of such optimization is that it should not hurt the time of assembly,
but rather (where possible) make it faster. Because _katome_ does not use physical disk
to store any information, it is of utmost importance that it keeps as low memory profile
as possible --- lower memory usage allows user to assemble genomes of more complicated
organisms.

=== Global vector of read data
<global_vec>
Usually during creation of the graph there is at least one structure which keeps track
of the already considered nodes/edges. In _katome_ it is either hash map or hash set. If
such structure does not have any place left for the new node/edge then it needs to
allocate more memory. New size of of such structure is determined based on the capacity
of the collection prior to the resize. Both hash map and hash sets in Rust have
noticeable spikes during resize, it is therefore best to reduce the size of the single
item in the collection.

Another aspect of presented algorithm is that during the creation of the graph assembler
needs to keep track of the already seen nodes to properly create the graph. However once
the graph is fully build, this information is no longer needed. Nodes are represented as
strings containing FASTA symbols and due to the nature of SSR assembly they are highly
redundant. This means that the standard way of tracking them is usage of hash maps/hash
sets, which guarantees on average $cal(O) (1)$ lookup, insert and remove operations. The
cost here is storing the hash per each item, which influences problem mentioned in the
first paragraph of this subsection.

_katome_ solves both problems. I propose the usage of a HashMap to keep the track of
nodes during creation of the graph, which is deallocated once the graph is created. Both
the graph and the hash map use slices (better described in the @slices). Resize of the
hash map and the graph can be done easily, because both types of slices are lightweight
(8 bytes per node/edge). Graph does not store any `NodeSlice`s, as the full information
is stored within the edge. To achieve that the representation of the read data is
different during the graph building process and after it is fully built, which are
described in this section.

Using global vector further reduces amount of memory used in the hash map/graph, as they
don't need to store any additional reference to the vector of data itself. Memory model
of Rust does not allow to store a single reference to the global vector in each item, as
the vector needs to remain mutable during the process of building the graph. This could
be achieved using 'fat' pointers, or more specifically their equivalent in Rust, but
this implies higher memory usage per item ('fat' pointers use more than 8 bytes of
memory).


==== Data representation during creation of the graph
<opt:repr_before_build>
In general global vector stores arrays of bytes. Slices are used to interpret these
bytes into nodes/edges. During the creation of the graph we store each unique edge as
two binary representations of nodes, one after another. This situation is illustrated on
@repr_during_build.

#figure(
  canvas({
    let cell-size = 3 // Size of each heatmap cell
    let bits = (
      0,
      0,
      0,
      1,
      1,
      0,
      1,
      1,
      0,
      1,
      1,
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      1,
      0,
      1,
      1,
      0,
      1,
      1,
      1,
      1,
      1,
      0,
      0,
      0,
      0,
    )

    // Draw heatmap cells
    for (col, bit) in bits.chunks(8).enumerate() {
      rect(
        ((col + 1) * cell-size - cell-size / 2, .3),
        ((col + 1) * cell-size + cell-size / 2, -.3),
        stroke: 1pt + black,
        name: "cell-" + str(col),
      )
      content(
        ((col + 1) * cell-size, 0),
        text(bit.map(str).join(" ")),
        name: "value-" + str(col),
      )
    }
    brace(
      "cell-0.south-west",
      "cell-0.south-east",
      flip: true,
      name: "brace-byte",
      content-offset: -.75,
    )
    content("brace-byte.content", text[a single byte])
    brace(
      (rel: (0, -.8), to: "cell-0.south-west"),
      (rel: (0, -.8), to: "cell-1.south-east"),
      flip: true,
      content-offset: -.75,
      name: "brace-source",
    )
    content("brace-source.content", text[compressed source node])
    brace(
      (rel: (0, -.8), to: "cell-2.south-west"),
      (rel: (0, -.8), to: "cell-3.south-east"),
      flip: true,
      content-offset: -.75,
      name: "brace-target",
    )
    content("brace-target.content", text[compressed target node])
    brace(
      (rel: (0, -1.6), to: "cell-0.south-west"),
      (rel: (0, -1.6), to: "cell-3.south-east"),
      flip: true,
      content-offset: -.75,
      name: "brace-target",
    )
    content("brace-target.content", text[single continuous array of bytes])
  }),

  caption: [
    Single compressed edge 'ACGTCTT' representation during graph build
    with size of k-mer~=~4.
  ],
)<repr_during_build>

@kmer_compress describes the process of compression of a single k-mer. Compressed data
is zero-padded for both k-mer and edge representations.

#algorithm(caption: [K-mer compression])[
  - *Require:* _kmer_ is a string containing only letters A, C, G, T
  - *Require:* $n$ is the length of _kmer_
  + *function* #smallcaps[Compress K-mer];(_kmer_, $n$)
    + _compressed_source_ #larrow #smallcaps[compress_node];(_kmer_$[0..n-1])$
    + _compressed_target_ #larrow #smallcaps[compress_node];(_kmer_$[1..n])$
    - #comment[return compressed value as a continuous array of bytes]
    + *return* #smallcaps[merge_arrays];(_compressed_source_, _compressed_target_)
  - #line(stroke: .5pt + gray, length: 100%)
  + *function* #smallcaps[compress_sequence];(_sequence_)
    + _compressed_ $<- []$
    + _len_ #larrow length of sequence
    + $i <- 0$
    + *while* $i <$ _len_
      + _compressed_.*push*(#smallcaps[compress_byte];(_sequence_$[i..i+4]$))
      + $i <- i + 1$
    + *if* _len_ mod $4 != 0$ *then* #comment[align last byte to the most significant bits]
      + #smallcaps[shift_left];(_compressed.last_byte_, $4 -$(_len_ mod 4))
    + *return* _compressed_
  - #line(stroke: .5pt + gray, length: 100%)
  - *Require:* _read_ contains at most 4 symbols
  + *function* #smallcaps[compress_byte];(_read_)
    + _carrier_ #larrow 0
    + _symbols_ #larrow {'A': 0, 'C': 1, 'G': 2, 'T': 3}
    + *for each* _symbol_ *in* _read_ *do*
      + _carrier_ #larrow #smallcaps[binary_or];(_carrier_, _symbols_[_symbol_])
      + _carrier_ #larrow #smallcaps[shift_left];(_carrier_)
    + *return* _carrier_
]<kmer_compress>
Notably, because both nodes share almost all symbols (except the first symbol for source
node and the last symbol for target node) this representation could compress such edge
even more. During my work I tried to exploit this fact. It turns out that creating such
representation comes with a cost. I have not been able to create representation, which
would give me a satisfying performance in terms of hashing and comparison. Most notably
while it is easy to hash/compare the source node, to compare/hash the target node the
whole representation needs to be shifted, to properly align the data. While methods for
doing so are implemented in the application, it uses significantly more time. This is a
good example of the trade off between memory usage and run time, the only one in the
entire project in which I opted into run time reduction at the expense of memory usage.


==== Data representation after creation of the graph
<opt:repr_after_build>
After graph is built the information about nodes is unnecessary, and so
for each edge both nodes get merged into the binary, compressed edge
representation. It is worth noting that the first byte in the compressed
edge representation is reserved for the size of padding in the last
byte, calculated as shown in @padding_calc

$ (4 - (e d g e l e n g t h med mod med 4)) med mod med 4 $<padding_calc>

This padding
is necessary to properly decompress data, as during shrinking of the
graph edges can have various length, as they get extended. Example
compression of the edge after graph is built is shown on
@repr_after_build.

#figure(
  canvas({
    let cell-size = 3 // Size of each heatmap cell
    let bits = (0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 1, 0, 0)


    // Draw heatmap cells
    for (col, bit) in bits.chunks(8).enumerate() {
      rect(
        ((col + 1) * cell-size - cell-size / 2, .3),
        ((col + 1) * cell-size + cell-size / 2, -.3),
        stroke: 1pt + black,
        name: "cell-" + str(col),
      )
      content(
        ((col + 1) * cell-size, 0),
        text(bit.map(str).join(" ")),
        name: "value-" + str(col),
      )
    }
    brace(
      "cell-0.south-west",
      "cell-0.south-east",
      flip: true,
      name: "brace-padding",
      content-offset: -.75,
    )
    content("brace-padding.content", text[padding])
    brace(
      (rel: (0, -.5), to: "cell-1.south-west"),
      (rel: (0, -.5), to: "cell-2.south-east"),
      flip: true,
      content-offset: -.75,
      name: "brace-edge",
    )
    content(
      "brace-edge.content",
      text[compressed edge representation without redundancy],
    )
    brace(
      (rel: (0, -1.3), to: "cell-0.south-west"),
      (rel: (0, -1.3), to: "cell-2.south-east"),
      flip: true,
      content-offset: -.75,
      name: "brace-target",
    )
    content("brace-target.content", text[single continuous array of bytes])
  }),
  caption: [
    Single compressed edge 'ACGTCTT' representation after graph is fully
    build, size of #box[k-mer = 4].
  ],
)<repr_after_build>

@edge_compress describes the process of compression of a single
edge.

#algorithm(caption: [Edge compression])[
  - *Require:* _kmer_ is a string containing only letters A, C, G, T
  - *Require:* $n$ is the length of _edge_
  + *function* #smallcaps[Compress Edge];(_kmer_, $n$)
    + _padding_ #larrow $4 - (n "mod" 4)$
    + _compressed_edge_ #larrow #smallcaps[compress_sequence];(_kmer_)
    + *return* #smallcaps[merge_arrays];([_padding_], _compressed_edge_)
]<edge_compress>

=== Graph's Intermediate Representation (GIR)
<graphs-intermediate-representation-gir>
The peak of the memory usage throughout assembly process resides in the graph creation
phase. After all reads are considered algorithms only remove unnecessary nodes, there
are no algorithms which add more nodes to the graph. Therefore in order to reduce the
memory consumption of the entire application, the reduction during the graph building is
needed. While in theory there is a possibility to further reduce the memory usage of the
graph, many times it comes with too much cost in terms of usability further on during
the assembly process. To help aid such situation _katome_ uses collections called
Graph's Intermediate Representation, or 'GIR' in short. 'GIR' is a collection created
solely for the purpose of graph creation, it should implement a trait, which converts
given GIR into some Graph representation. If the conversion step is performant enough in
terms of memory, then user might opt-in to include GIR in the assembly process.

GIR can also serve as filters to the raw input data, and so they might implement basic
traits used to reduce the number of nodes and edges in the graph. 'BFCounter'
application, described in the following subsection, can be thought of as a GIR, which is
implemented outside of _katome_. GIR trait gives the possibility to implement its
features natively in the Rust language.

=== 'BFCounter' input file type
<bfcounter-input-file-type>
Preprocessing of the data can be done outside of the assembler itself, and its results
might be stored on the disk. Assembler can then use such file to construct the graph and
assemble contigs. Currently _katome_ supports raw FASTA and FASTAQ file formats, as well
as output of the 'BFCounter' application @Melsted2011. It is a memory efficient k-mer
counting software, which allows the user to count number of occurrences of each edge in
the provided data. _katome_ can use this information to build the graph more
efficiently, especially if user sets up minimal threshold of the weight of the edge in
the graph. Refer to the @evaluation to see the difference in memory usage / run time
that 'BFCounter' introduces.

== Run time minimalization
<run-time-minimalization>
During implementation of the assembler numerous optimizations of the code were
introduced. Below I describe three most notable optimizations.

=== Compression optimization
<compression-optimization>
As described in @compress subsection basic FASTA nucleotides are mapped into their
respective 2-bit representation. The implementation of this basic functionality can be
found in the @compression_before

#code-listing-file(
  "compression_before.rs",
  caption: [`encode_fasta_symbol()` implementation before optimization],
)<compression_before>

As depicted on the @compression_before_profile this approach has two main problems:

- neither `compress_node` nor `encode_fasta_symbol` are inlined
- compression of the FASTA symbol uses 17% of the application's time

The first problem means that each time the assembler compresses a single FASTA symbol it
has to make a function call. Depending on the data it means that there are at least
several million unnecessary function calls issued.

#figure(image("../images/compression_before.png", width: 30.0%), caption: [
  Part of the call graph before `encode_fasta_symbol` function optimization
])<compression_before_profile>

Second problem means that processor cannot efficiently predict the
if-else statement branch. While there is a phenomena called 'nucleotide
bias', which shows that for some parts of the genome frequency of
occurrence of basic nucleotides may not be evenly distributed
(skew) @lobry1996asymmetric, for the purpose of compression algorithm it
can be assumed that nucleotides are evenly distributed.

In order to optimize this code `match` statement was removed and
replaced with computation of two Boolean functions:
@boolean1~and~@boolean2, where $C$, $D$ and $A$ are bits, shown on the
@compression_after_profile.

$ ~C dot.op D $<boolean1>
$ C + A $<boolean2>

#figure(
  diagram(node-outset: 10pt, {
    let bits_spacing = 0.2
    let rows_spacing = 0.2
    for (group, offset) in (
      ("A", 0),
      ("B", bits_spacing * 3),
      ("C", bits_spacing * 4),
    ) {
      node((6 + offset, -.2), name: label(group), group)
    }
    let a_nodes = array((<A>,))
    let b_nodes = array((<B>,))
    let c_nodes = array((<C>,))
    for (i, letter) in "ACGT".codepoints().enumerate() {
      let ascii = letter.to-unicode()
      let normalized = ascii - "A".to-unicode()
      let binary = strfmt("{0:06b}", normalized).codepoints()
      node((0, i * rows_spacing), letter)
      edge("-|>")
      node((2, i * rows_spacing), str(ascii))
      edge("-|>")
      node((4, i * rows_spacing), str(normalized))
      edge("-|>")
      for (j, bit) in binary.enumerate() {
        let name = label(strfmt("bit-{}-{}", i, j))
        node((6 + bits_spacing * j, i * rows_spacing), name: name, str(bit))
        if j == 0 {
          a_nodes.push(name)
        } else if j == 3 {
          b_nodes.push(name)
        } else if j == 4 {
          c_nodes.push(name)
        }
      }
      node(enclose: a_nodes, fill: my-colors.at(0).lighten(30%), snap: -1, inset: -5pt)
      node(enclose: b_nodes, fill: my-colors.at(1).lighten(30%), snap: -1, inset: -5pt)
      node(enclose: c_nodes, fill: my-colors.at(2).lighten(30%), snap: -1, inset: -5pt)
    }
  }),
  caption: [
    Bits used in the optimized compression algorithm
  ],
)<compression_after_profile>

These functions were created based on the ASCII representation of the symbols. New
implementation is described in the @compression_after.

#code-listing-file(
  "compression_after.rs",
  caption: [`encode_fasta_symbol()` implementation after optimization],
)<compression_after>

After optimization neither `compress_node` nor `encode_fasta_symbol` are found in the
call graph, meaning that their run time is negligible, which is the goal of the
optimization.


=== Node index calculation
<node-index-calculation>
During processing of BFCounter input only `NodeSlice`s are tracked. This is an exploit
of the BFCounter's property --- its output contains only unique edges. The lack of
tracking of `NodeIndex`s (indices of nodes in the actual instance of `PtGraph`) allows
for further memory usage reduction, but requires a method to map `NodeSlice` to
`NodeIndex`. `get_node_index` is a function which implements this functionality. It does
so by keeping the track of unique nodes in the global vector of read data. As described
in @global_vec during creation of the graph edges are represented as two compressed
nodes. It means that if during insertion of the node it already is present in the graph,
the assembler will still compress it and put into the global vector --- the edge is
guaranteed to be unique and so it needs to be inserted. This creates situation where
some of the nodes are duplicated throughout the global vector of sequences.

`NodeSlice` contains a single number, which is an offset on the global vector of reads.
Given such number, if assembler is able to distinguish unique nodes from duplicates,
then it also can create an index on the graph. To do this it needs to count all of the
unique nodes up to the given offset. This algorithm uses the fact that both `NodeSlice`s
and `NodeIndex`s are strictly, linearly increasing.

First implementation of `get_node_index` used bit set of fixed size to keep the track of
unique nodes. Assembler would set the bit on the offset of uniquely inserted node. Code
for the function is shown in the @node_idx_before.

#code-listing-file(
  "node_idx_before.rs",
  caption: [`get_node_idx` implementation before optimization],
)<node_idx_before>

#figure(
  image("../images/node_idx_before.svg"),
  caption: [Call graph of the graph creation of assembler before `get_node_idx` optimization.],
)<node_idx_before_profile>

This implementation was a severe bottleneck of the entire assembler. As shown on the
@node_idx_before_profile `get_node_idx` method is responsible for 99% of the time during
graph building stage. Notably, function which runs for 65% of the time is the
`core::num::count_ones` method for the primitive type `u32`. This function counts set
bits in the binary representation of unsigned, 32-bit number. These numbers are elements
which store bits in the `FixedBitSet` and will be further on referred to as 'blocks'. On
architectures which support `POPCNT` assembly instruction (Intel's SSE4.2 or higher)
`core::num::count_ones` is realized as a single machine instruction, however if such
support is missing then generated assembly uses roughly 15 instructions, as seen in the
@asm, which significantly hurts the performance of the program.

Both percentages are a clear indication that using the `FixedBitSet::count_ones`
function should be avoided, or its usage should be minimized.

#code-listing-figure(
  caption: [`core::num::count_ones` assembly representation],
  ```nasm
  mov     eax, edi
  shr     eax
  and     eax, 0x55555555
  sub     edi, eax
  mov     eax, edi
  and     eax, 0x33333333
  shr     edi, 2
  and     edi, 0x33333333
  add     edi, eax
  mov     eax, edi
  shr     eax, 4
  add     eax, edi
  and     eax, 0xf0f0f0f
  imul    eax, eax, 0x1010101
  shr     eax, 24
  ```,
)<asm>

Proposed solution to this problem is using a vector of numbers, in which each number,
further referred to as a region, stores a count of set per multiple blocks. During
insertion of the node, region representing block of the node is incremented. To get the
desired index of the node algorithm needs to calculate special offset to which it can
sum elements of the vector. The rest of the bits should be calculated by using
`FixedBitSet::count_ones` function, as they can't be derived from the vector of regions
due to its resolution. Changing the number of blocks represented by a single region
gives the control over algorithm --- the more blocks are represented by region, the
faster part of the vector can be summed, but the more bits have to be counted via
`FixedBitSet::count_ones`. On the other hand, setting the granularity too high will
result in longer times needed to sum the part of the vector (especially for high
offsets). Empirically chosen value of $512$ blocks per region seems to be best fitting,
as it offers the best performance. Implementation of the optimized `get_node_idx`
function is presented in the Listing~@node_idx_after. It is worth nothing that the new
implementation is specifically fast on architectures with SIMD support, where the
compiler is able to vectorize the sum of regions.

#code-listing-file(
  "node_idx_after.rs",
  caption: [`get_node_idx` implementation after optimization],
)<node_idx_after>

New implementation is a magnitude faster than the old one, which indicates a very
successful optimization of the code. As depicted on the @node_idx_after_profile
`get_node_idx` is still responsible for roughly 19% of the graph building process. It
could be further optimized by introducing additional vectors, serving the similar role
of the carrier vector, but with much higher number of blocks per carrier. It could also
be completely removed, by introducing a memory overhead, namely 8 bytes per node. In
this scenario `NodeIndex` would be stored as value in the hash map keyed by `NodeSlice`.
This is similar to the current solution, but I decided not to use it in order to further
reduce memory usage of `katome`, although it might be beneficial to provide it as an
opt-in solution for the user, especially if the memory overhead is not an issue
(e.g.~assembling of organisms with relatively short genome length).

#figure(image("../images/node_idx_after.png", width: 50.0%), caption: [
  Part of the call graph of the graph creation of assembler after
  `get_node_idx` optimization
])<node_idx_after_profile>
