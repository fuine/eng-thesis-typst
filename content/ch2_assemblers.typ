#import "@preview/subpar:0.2.2"
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import "../utils.typ": algorithm, comment, definition, larrow, my-colors, property

= DNA assembling
<dna-assembling>
Current technology does not allow for reading entire genome at once, but rather it reads
shorter fragments of the DNA sequence, referred to as 'reads'. DNA assembling is a
process of aligning and merging reads in order to create longer sequences, ideally
representing entire chromosomes. There are two main approaches to reading DNA data.

===== Whole genome shotgun sequencing
<whole-genome-shotgun-sequencing>
Because of read length limitation, one of the most popular techniques used to obtain
genome data is shotgun sequencing genomic DNA @adams2008complex @weber1997human. This
technique randomly divides DNA data into fragments small enough to get its symbols and
create reads. Division and read is performed multiple times to statistically ensure that
read data is of specific coverage. Coverage is defined as an average number of reads
representing given nucleotide. In this thesis I will be describing assemblers using
shotgun sequencing technique.

===== Hierarchical shotgun sequencing
<hierarchical-shotgun-sequencing>
Hierarchical shotgun sequencing first divides the DNA data into larger fragments
(roughly 50-200 kb) of known order and then uses shotgun sequencing to sequence each
fragment. It is worth noting that in order to sort these fragments, special libraries
are used. While this technique relies less on the computational algorithms in the
assembler, it requires already created libraries and is generally slower than whole
genome shotgun sequencing technique.

===== Sequence reading techniques
<sequence-reading-techniques>
Independently from DNA sequencing technique used, it is important to
choose proper technique for reading the sequence from the organism.
Currently there are three leading techniques, each with its own
advantages and disadvantages:

- Sanger sequencing --- older technique, which provides high accuracy reads over longer
  lengths, but is expensive and slow;
- Next Generation Sequencing (NGS) --- fast and cost effective method, provides high
  output, with lower quality. Usually paired with high coverage to ensure fixed
  accuracy;
- Single Molecule, Real-Time (SMRT) --- offers longer reads which come with a cost of
  more errors in the reads, when compared to NGS and Sanger.

== DNA Assemblers
<dna-assemblers>
There are two main approaches to genome assembly.

=== Mapping assembly
<mapping-assembly>
Mapping assemblers use reference genome, against which they align data from the
sequencers. Reads are independently assigned the most likely position in the genome.
Mapping alignment does not assume any synergy between reads. While this technique can be
efficient, it has some major downfalls, such as:

- inability to handle situations in which reference genome contains duplicate regions;

- different strategies when read has multiple, equally valid positions of placement;
- reads which vary greatly from the reference genome will not be aligned properly.

Despite these pitfalls, there are different implementations of mapping assemblers, most
notably:

- BLAST @altschul1990basic;

- BWA @li2009fast;
- Bowtie 1 + 2 @Langmead2009 @langmead2012fast.

=== De Novo assembly
<de-novo-assembly>
De Novo assembly process does not require any reference material to assemble genetic
material. Such assemblers use graph structures to merge reads of nucleotides sequences
into bigger sequences called contigs. One of the most popular graph structures used by
different implementations of de novo assembly process is De Bruijn graph. De Bruijn
graph is a directed graph, which represents overlaps of sequences of nucleotides. De
Bruijn graph is defined as a complete graph of the overlapping sequences, and so most
assemblers use the subgraph of the De Bruijn graph, called the Pevzner graph. Despite
this fact most of the sources refer to this subgraph as De Bruijn graph, and I will also
follow this convention to provide consistency with the established terminology. Second
important thing to note here is that canonically De Bruijn graph stores sequences in its
nodes, whereas solution used by my implementation stores sequences in the edges of the
graph. \ Subsequences which are building blocks for De Bruijn graphs are called
‘k-mer's, where k is the length of the subsequence, typically set by the user. They are
created by a sliding window on the given read, as depicted on @kmer_create.
Single k-mer denotes an edge in the De Bruijn Graph, in which substring of length $k -
1$ beginning at the offset $0$ represents source node and substring of length $k - 1$
starting at the offset $1$ represents target node of the edge. Each edge has the counter
denoting number of its occurrences in the input data. These counters are further used to
eliminate erroneous reads, created by the imperfect nucleotide-reading technique. On
average, after graph is fully built, edge should have the weight of the coverage of
input data. Example of creating both source and target node, with the edge connecting
the two are shown on the @kmer_nodes. Red and yellow colors mark symbols
exclusive to source and target nodes respectively, while blue color marks the common
part of k-mer. \

#let colorize(color, content) = text(
  fill: color,
  weight: "bold",
  font: "Adagio_Slab",
  content,
)
#let rainbow(content, start: 0) = {
  let colors = (red, ..my-colors)
  for (color, letter) in colors.slice(start).zip(content.split("")) {
    colorize(color, letter)
  }
}

#figure(
  diagram(node-stroke: 1pt, node-corner-radius: 2pt, node-outset: 1pt, {
    let origin = (1.5, 0)
    let read = "CAAAGCT"
    node(origin, rainbow(read))
    for i in range(4) {
      let placement = (i, 1)
      node(placement, rainbow(read.slice(i, count: 4), start: i))
      edge(origin, (1.5, 0.5), (i, 0.5), placement, "..|>")
    }
  }),
  caption: [
    Creation of k-mers from a single read. K-mer size is 4.
  ],
)<kmer_create>

#figure(
  diagram(node-stroke: 1pt, node-corner-radius: 2pt, node-outset: 1pt, {
    let origin = (1, 0)
    let a = (0, 1)
    let b = (2, 1)
    let read = (
      colorize(my-colors.at(0), "G"),
      colorize(my-colors.at(1), "TTCAGTAGG"),
      colorize(my-colors.at(2), "C"),
    )
    node(origin, name: <origin>, read.join())
    node(a, name: <a>, read.slice(0, 2).join())
    node(b, name: <b>, read.slice(1).join())
    edge(
      a,
      b,
      "-|>",
      label: [edge in the De Bruijn graph],
      label-side: left,
      label-sep: 0pt,
    )
    edge(a, b, none, label: [with weight = 1], label-side: right, label-sep: 0pt)
    edge(<origin.south>, <a.north>, "..|>")
    edge(<origin.south>, <b.north>, "..|>")
  }),
  caption: [
    Source and target node, with respective edge, derived from the
    original k-mer of length 11.
  ],
)<kmer_nodes>

Graph is created from reads, using the @graph_creation.

#algorithm(caption: [De Bruijn graph creation])[
  - *Require:* _input_ is the array of reads
  - *Require:* $k$ is the length of _kmer_
  - *Require:* Length of each read in the _input_ is greater than or equal to $k$
  + initialize _graph_
  + *for each* _read_ *in* _input_ *do*
    + $n <-$ _len_(_read_)
    + *for* $i <- 0$ *to* $(n - k + 1)$ *do*
      + _kmer_ #larrow _read_$[i..(i + k - 1)]$
      + _source_node_ #larrow _kmer_$[0..(k - 2)]$
      + _target_node_ #larrow _kmer_$[1..(k - 1)]$
      + _edge_ #larrow #smallcaps[create_edge];(_source_node_, _target_node_)
      + *if* _source_node_ *not in* _graph_ *then*
        + #smallcaps[add_node];(_graph_, _source_node_)
      + *if* _target_node_ *not in* _graph_ *then*
        + #smallcaps[add_node];(_graph_, _target_node_)
      + *if* _edge_ *not in* _graph_ *then*
        + #smallcaps[add_edge];(_graph_, _edge_)
      + *else*
        + #smallcaps[updage_weight];(_graph_, _edge_)
]<graph_creation>
Example graph created from the set of given reads can be seen on @example_graph.

#figure(
  diagram(node-stroke: 1pt, node-shape: "circle", node-outset: 1pt, {
    node((0, 0), [0])
    edge("-|>", label: [(TGG, 1)])
    node((3, 0), name: <left>, [1])
    edge("-|>", label: [(GGC, 3)])
    node((6, 0), name: <right>, [2])
    edge("-|>", label: [(GCA, 2)])
    node((9, 0), [4])
    node((4.5, -1.5), name: <top>, [3])
    edge(<right>, <top>, "-|>", label: [(GCG, 1)], label-angle: auto)
    edge(<top>, <left>, "-|>", label: [(CGG, 1)], label-angle: auto)
  }),
  caption: [
    Example graph for k-mer of size 3, created from reads: 'TGGCG',
    'CGGCA', 'GGCA'.
  ],
)<example_graph>

Main advantage of De Novo assembly, as opposed to reference mapping, is
its ability to assemble DNA data of organisms, for which there are no
known reference genomes created. Repeated sequences can also be
assembled properly. The biggest problem associated with the De Novo
assembly technique is its extensive memory usage.

== Repetitive sequences
<repetitive-sequences>
One area in which most well-known assemblers fail to deliver long, uncut
contigs are organisms with repetitive sequences in their genome. This
fact is a consequence of how graph is turned into contigs. \
In the classic implementation of DNA assembler based on the De Bruijn
graph, after the graph has been built and corrected all nodes, which
have incoming degree (number of incoming edges) or outgoing degree
(number of outgoing edges) greater than 1, are called ambiguous nodes.
Each ambiguous node marks a place in which contig is ended, and new
contigs are started during the contig creation. \
Repetitive sequences are represented in the De Bruijn graph as cycles.
This means that even if such cycle is a loop, one of its nodes will be
marked as ambiguous and in turn result in several contigs. \
Solution to this problem was described
by~#cite(<rn:bbe2015assembler>, form: "prose");. According to that paper
it is possible to prevent artificial breakage of the contig by changing
the definition of node's ambiguity.

== _katome_ DNA assembler
<dna-assembler>
Based on the new definition of ambiguity the application called _dnaasm_@dnaasm was
developed on Warsaw University of Technology, created by Wiktor Kusmirek and Robert
Nowak. While _dnaasm_ correctly assembles genomes with repetitive regions it does
however suffer from the extensive memory usage. While most of the De Novo assemblers use
persistent, on-disk graph structures, _dmaasm_ stores entire graph in RAM. This approach
makes the application sufficiently faster, as it does not have to perform any I/O
operations interfacing hard disks. However _dnaasm_ is not optimized in terms of memory
usage, which can be observed during assembling of organisms with complex genomes (for an
example of its scaling refer to @eval:performance). It is also not
designed to support parallelism or concurrency throughout assembling process.

In order to mitigate these issues I have implemented a new application called _katome_.
It strives to be highly efficient both in terms of memory, as well as in terms of run
time. Its design is modular, with rich API, allowing users to easily implement their own
representation of graph, data filters and custom implementations of algorithms. It also
enables easy creation of new assemblers using provided algorithms and collections as
basic building blocks, effectively creating a custom pipeline of data transformation.

Moreover _katome_ has its data representation guarded by a synchronization primitive,
making it easy to share across multiple threads/processes. Application is implemented in
the Rust programming language, which by design guarantees memory safety.

_katome_ uses similar algorithms to the ones introduced by _dnaasm_, with two
exceptions, which are described in the following sections.

== Shrinking algorithm
<shrinking-algorithm>
After graph is built, pruned and standardized, it should be collapsed. Before collapsing
can take place the graph should be reduced in size. Shrinking is a simple technique,
which greatly simplifies underlying graph representation while maintaining information
necessary to create contigs. In order to describe shrinking I introduce the concept of
@strand in graph. To define @strand I present @cycle~and~@not_cycle. @strand is
defined in @strand_def.

#property[
  We say a cycle $C$ has @cycle if it has at most 1 vertex which has an edge not included
  in $C$.
]<cycle>

#property[
  Let $X$ be a directed path of the form $v_0 e_0 v_1 e_1 dots.h.c thin e_(n - 1) v_n$. We
  say that $X$ has @not_cycle if the following conditions are met:

  - Each vertex in $v_0 v_1 ... thin v_(n - 1)$ has exactly one
    outgoing edge;

  - Each vertex in ${v_1, v_2, ..., v_n}$ has exactly one
    incoming edge.
]<not_cycle>

#definition[
  Let $G = (V, E)$ be a directed graph. We call directed path $S$ in $G$ a *@strand* if it
  is a directed path such that the following holds:

  - if $S$ is a cycle, then $S$ must satisfy @cycle;

  - if $S$ is not a cycle, then $S$ must satisfy @not_cycle.
]<strand_def>
Examples of strands are shown in @strand_examples.


#subpar.grid(
  figure(caption: [], diagram(
    node-stroke: 1pt + blue,
    edge-stroke: blue,
    node-shape: "circle",
    node-outset: 1pt,
    label-sep: -1pt,
    {
      node((-1, 0), name: <start>, text(blue)[3])
      edge("<|-", bend: 30deg, label: text(blue)[CGTA])
      node((0, -1), text(blue)[2])
      edge("<|-", bend: 30deg, label: text(blue)[ACGT])
      node((1, 0), text(blue)[1])
      edge("<|-", bend: 30deg, label: text(blue)[TACG])
      node((0, 1), name: <end>, text(blue)[4])
      edge((), <start>, "<|-", bend: 30deg, label: text(blue)[GTAC])
    },
  )),
  figure(
    diagram(
      node-stroke: 1pt + blue,
      edge-stroke: blue,
      node-shape: "circle",
      node-outset: 1pt,
      label-sep: -1pt,
      {
        node((-1, 0), name: <start>, text(blue)[3])
        edge("<|-", bend: 30deg, label: text(blue)[CGTA])
        node((0, -1), text(blue)[2])
        edge("<|-", bend: 30deg, label: text(blue)[ACGT])
        node((1, 0), text(blue)[1])
        edge(
          "<|-",
          bend: 30deg,
          label: text(blue)[TACG],
          label-angle: auto,
          label-side: right,
          label-sep: 0pt,
        )
        node((0, 1), name: <end>, text(blue)[4])
        edge(
          (),
          <start>,
          "<|-",
          bend: 30deg,
          label: text(blue)[GTAC],
          label-angle: auto,
          label-side: right,
          label-sep: 0pt,
        )
        node((2, 1), [5], stroke: black)
        edge(<end>, "<|-", stroke: black)
        node((-2, 1), [0], stroke: black)
        edge((), <end>, "-|>", stroke: black)
      },
    ),
    caption: [],
  ),
  grid.cell(colspan: 2, align: center, figure(
    diagram(
      node-stroke: 1pt + blue,
      edge-stroke: blue,
      node-shape: "circle",
      node-outset: 1pt,
      {
        let reads = "ACGTCAA"
        for i in range(5) {
          node((1.5 * i, 0), text(blue)[#i])
          if i != 4 {
            edge("-|>", label: text(blue, reads.slice(i, count: 4)))
          }
        }
      },
    ),
    caption: [],
  )),
  columns: (1fr, 1fr),
  caption: [Examples of strands],
  label: <strand_examples>,
)

Shrinking algorithm maps strands with at least 3 nodes into a single edge with source
and target nodes. It is described in @graph_shrinking. Shrunk representation of
strands shown in @strand_examples is presented in @strands_shrunk.

#algorithm(caption: [Graph shrinking])[
  - *Require:* _graph_ is the built De Bruijn Graph
  - *Require:* Sequences are stored in edges
  - *Require:* $k$ is the length of the k-mer
  + *procedure* #smallcaps[shrink_graph];(_graph_)
    + _k1_size_ $<- k - 1$
    + *for each* _vertex_ *in* _graph_ *do*
      + *if* #smallcaps[out_degree];(_vertex_) $= 1$ *and* #smallcaps[in_degree];(_vertex_) $= 1$ *then*
        + _base_edge_ #larrow _vertex.in_edge_
        + _out_edge_ #larrow _vertex.out_edge_
        + _source_ #larrow _base_edge.source_
        + _target_ #larrow _base_edge.target_
        + *if* _source_ $!=$ _target_ *then*
          + _tmp_seq_ #larrow _base_edge.sequence_
          + _tmp_seq_.extend(_out_edge.sequence_[_k1_size_..])
          + #smallcaps[remove_edge];(_base_edge_)
          + #smallcaps[remove_edge];(_out_edge_)
          + #smallcaps[remove_node];(_vertex_)
          + #smallcaps[add_edge];(_source_, _target_, _tmp_seq_)
]<graph_shrinking>

#subpar.grid(
  figure(caption: [], diagram(
    node-stroke: 1pt,
    node-shape: "circle",
    node-outset: 1pt,
    {
      node([1])
      edge((), (), "-|>", bend: 130deg, [ACGTACG])
    },
  )),
  figure(
    diagram(node-stroke: 1pt, node-shape: "circle", node-outset: 1pt, {
      node((0, 0), [0])
      edge("-|>")
      node((1, 0), [4])
      edge((), (), "-|>", bend: 130deg, label: [TCCATCC])
      edge("-|>")
      node((2, 0), [5])
    }),
    caption: [],
  ),
  grid.cell(
    // colspan: 2,
    align: center,
    figure(
      diagram(node-stroke: 1pt, node-shape: "circle", node-outset: 1pt, {
        node([0])
        edge("-|>", label: [ACGTCAA])
        node((3, 0), [4])
      }),
      caption: [],
    ),
  ),
  columns: (1fr, 1fr, 1fr),
  caption: [Examples of shrunk strands],
  label: <strands_shrunk>,
)


== Collapsing algorithm
<collapsing>
To create the result of the assembly collapsing algorithm is used. It
converts the shrunk graph to build a set of resulting contigs. In order
to present collapsing algorithm I need to introduce definitions of two
different loops, namely @self-loop~(@self-loop_def) and
@simple-loop~(@simple-loop_def).

#definition[
  Let $G = (V, E)$ be a directed graph. Let $v in V$ and
  $e in E$, we call the pair $(v, e)$ a *self-loop* if the source
  and target of $e$ is $v$.
]<self-loop_def>

#definition[
  Let $G = (V, E)$ be a weighted, directed graph, with
  edge weights $w : E -> RR$. Let $X$ be a directed path of the
  form $v_0 e_0 v_1 e_1 v_0$. We call the path $X$ in $G$ a
  *simple-loop* if the following conditions are met:

  - $w (e_0) > w (e_1)$;

  - node $v_1$ has exactly one incoming edge and two outgoing edges;
  - node $v_0$ has exactly two incoming edges and one outgoing edge.

]<simple-loop_def>


Collapsing algorithm assumes that contigs in the graph are standardized (standardization
algorithm introduced by~#cite(<dnaasm>, form: "prose");), and that the graph is shrunk
prior to collapse. @collapse describes the process of collapse. In the core of the
algorithm each considered node is checked, if it is ambiguous. If it has not been marked
as one, then we need to determine whether it is a part of a simple-loop or a self-loop.
If it is, then algorithm should collapse such loops without breaking the contig,
otherwise the classic approach should be used.

#{
  show figure: set block(breakable: true)
  [#algorithm(caption: [Graph collapse])[
      - *Require:* _graph_ is shrunk
      - *Require:* All contigs in graph are standardized
      - *Require:* All nodes are marked as non-ambiguous
      + *function* #smallcaps[collapse_graph];(_graph_)
        + _contigs_ $<- []$
        + *loop*
          + _externals_ #larrow All nodes with in degree 0, or nodes in the highest topologically sorted cycle for any weakly connected component which doesn't contain nodes of in degree 0
          + *if* _externals_ is empty *then*
            *break*
          + *for each* _node_ *in* _externals_ *do*
            + _tmp_ #larrow #smallcaps[contigs_from_node];(_graph_, _node_)
            + #smallcaps[extend];(_contigs_, _tmp_)
            + #smallcaps[remove_single_nodes];(_graph_)
        + *return* _contigs_
      - #line(stroke: .5pt + gray, length: 100%)
      + *procedure* #smallcaps[add_contig];(_contigs_, _contig_)
        + *if* _contig_ $!= []$ *then*
          + #smallcaps[push];(_contigs_, _contig_) #comment[Add contig to contigs]
          + _contig_ $<- []$
      - #line(stroke: .5pt + gray, length: 100%)
      - *Require:* $k$ is the size of k-mer
      + *function* #smallcaps[congigs_from_node];(_graph_, _node_)
        + _contig_ $<- []$
        + _contigs_ $<- []$
        + _current_node_ #larrow _node_
        + _in_num_ #larrow in degree of _node_
        + *loop*
          + _out_num_ #larrow out degree of _current_node_
          + *if* _out_num_ $= 0$ *then*
            + #smallcaps[add_contig];(_contigs_, _contig_)
            + *return* _contigs_
          + _current_edge_ #larrow first outgoing edge of _current_node_
          + *if* _current_edge_ is marked as ambiguous *then*
            + #smallcaps[add_contig];(_contigs_, _contig_)
          + *else*
            + *switch* (_in_num_, _out_num_)
              + *case* $(2, 1)$
                + *if* _current_vertex_ hasn't got @self-loop *then*
                  + #comment[get the $e_0$ from the @simple-loop]
                  + _second_edge_ #larrow #smallcaps[simple_loop];(_graph_, _current_edge_index_)
                  + *if* _second_edge_ $!= emptyset$ *then*
                    + #smallcaps[insert];(_ambiguous_nodes_, _current_vertex_)
                    + #smallcaps[add_contig];(_contigs_, _contig_)
              + *case* $(1, 2) || (2, 2)$
                + *if* _current_vertex_ has @self-loop *then*
                  + _current_edge_index_ #larrow _self_loop_
                + *else*
                  + #smallcaps[insert];(_ambiguous_nodes_, _current_vertex_)
                  + #smallcaps[add_contig];(_contigs_, _contig_)
              + *case* $(0, 1) || (1, 1)$ #comment[do nothing]
              + *case* _default_
                + #smallcaps[insert];(_ambiguous_nodes_, _current_vertex_)
                + #smallcaps[add_contig];(_contigs_, _contig_)
          + #comment[Add remainder of the edge's symbols to the current contig.]
          + #smallcaps[extend];(_contig_, _current_edge.sequence_[_k_size_..])
          + _target_ #larrow _current_edge.target_
          + _in_num_ #larrow in degree of _target_
          + *if* _second_edge_ $!= emptyset$ *then*
            + #smallcaps[extend];(_contig_, _second_edge.sequence_[_k_size_..])
            + #smallcaps[decrease_weight];(_second_edge_)
          + #smallcaps[decrease_weight];(_current_edge_)
          + _current_node_ #larrow _target_
        + *return* _contigs_
    ]<collapse>
  ]
}

Example of the collapsing algorithm usage is shown in the @collapse_example. Notably
assemblers without the support for repetitive sequences would yield 6 contigs instead of
one.

#figure(
  diagram(node-stroke: 1pt, node-shape: "circle", node-outset: 1pt, {
    let reads = "ACGTCAA"
    for i in range(4) {
      node((3 * i, 0), name: "node-" + str(i), str(i))
    }
    edge(<node-0>, <node-1>, "-|>", label: [(ACGT, 1)])
    edge(<node-1>, <node-2>, bend: -20deg, "-|>", label: [(CGTT, 2)])
    edge(<node-2>, <node-1>, bend: -20deg, "-|>", label: [(GTTCGT, 1)])
    edge(<node-2>, <node-3>, "-|>", label: [(GTTA, 1)])
    edge(<node-3>, <node-3>, "-|>", bend: 130deg, label: [(TTAG, 2)])
  }),
  caption: [
    Example graph, each edge contains a sequence and a weight, collapsing it should
    yield the contig 'ACGTTCGTTAGG' for k-mer size 4.
  ],
)<collapse_example>
