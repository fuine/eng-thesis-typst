= Summary
<summary>
== Conclusions
<conclusions>
As shown in the @evaluation, _katome_ outperforms all of the assemblers on almost all of
the data. While the overall difference in the run time is not big, it can be speculated
that other assemblers are more mature than _katome_ and their developers had more time
to tune and optimize them accordingly. In my opinion there is still a possibility of
significant speed up and memory usage reduction in the _katome_ project.

Notably the new assembler is comparable to the _dnaasm_ project in terms of quality ---
_dnaasm_ and _katome_ have overall lower number of mismatches per 100 bp and indels per
100 bp, while 'Velvet' and 'ABySS' assemblers create less contigs. Judging by the
statistics for _katome_ it creates a lot of small (less than 1000 bp) contigs, although
created longer contigs are similar to other assemblers, thus other statistics are
similar to other assemblers.

Additionally further speed-up is possible at the cost of the memory, if
the user chooses to opt into that.

The goals, described in @goals have been successfully achieved. I was able to construct
a modular, safe and well-performing library, which has been designed with parallelism in
mind. Rust enables strong memory safety and parallel/concurrent safety, as well as the
ease of extending the library, by introduction of implementers of the proposed traits.

Throughout the project Rust was a significant improvement to the usual workflow, as the
language puts a strong emphasis on memory safety. I found its tooling simple, effective
and intuitive. Furthermore the language's strong type system made refactoring notably
easier than in the weakly typed languages.

== Future work
<future-work>
Although _katome_ is currently a functional and working assembler there are many ways to
improve it. Below I list several ideas which might be expanded further to improve the
quality of its output, as well as its performance, both in terms of speed and memory
usage.

=== Quality improvements
<quality-improvements>
===== Reduction of the number of created small contigs
<reduction-of-the-number-of-created-small-contigs>
In the number of assembled contigs it is clearly shown that _katome_ creates more
contigs than _dnaasm_ (up to roughly 2 times more). Further analysis of the data shows,
that most of these contigs are short (less than 1000 bp). I think that this difference
can come up from the way _katome_ handles subgraphs in which all nodes have at least one
incoming edge. Reducing number of created contigs would lead to improving various
statistics and would lead to the general improvement of the assembly.

===== Implementation of the bubble removal
<implementation-of-the-bubble-removal>
Authors of 'Velvet' assembler introduced the Tour Bus algorithm, which removes so called
'bubbles' --- two paths that start and end at the same node. By looking at the graphs
created by _katome_ for various organisms, it is clearly shown that bubbles make up for
a lot of ambiguous nodes, which in turn directly influence number of created contigs. I
haven not implemented this algorithm due to the lack of time in the current project, but
I am convinced that it could significantly reduce number of created contigs.

===== Merge of reverse complement k-mers representations
<merge-of-reverse-complement-k-mers-representations>
Currently _katome_ stores k-mers and their reverse complements as distinct edges in the
created graph. There exist methods to merge both representations into one, effectively
reducing the memory usage of the entire application.

===== Support for paired-end reads
<support-for-paired-end-reads>
Using information about paired-end reads greatly improves the quality of assembly. While
most assemblers, including _dnaasm_ supports it, _katome_ does not use this information
during assembly. The challenge in using this technique is memory usage, as in the naive
form, implemented in the _dnaasm_ assembler, it doubles the memory used by the
assembler. Efficient, RAM-only implementation of this method is an interesting problem
both from in terms of algorithm design and optimization of the implementation, but in my
opinion it would yield significant improvement of the quality of assembler.

=== Performance improvements
<performance-improvements>
===== Introduction of parallelization into different algorithms
<introduction-of-parallelization-into-different-algorithms>
Application is written in a fashion that should allow parallelized algorithms to operate
on the Graph and GIR implementers. The most important thing to note is that due to the
nature of the algorithms (operating on a single, big collection) usually algorithms
would get divided into the parallel section, which operates on non-mutable references to
the collection and gathers information, and a single-threaded code which would mutate
the collection accordingly, using information from the parallel part.

While in theory it would be possible to process input in parallel by building several
separate collections and merge them, in my opinion this approach is not feasible. It
would almost certainly use more memory due to the redundancy in the data it would
potentially introduce. As such I think that parallelization of the graph creation is a
challenging, and possibly unachievable goal, at least if the application will stay
RAM-exclusive.

===== GIR based on Bloom filter
<gir-based-on-bloom-filter>
'BFCounter' application uses Bloom filter to effectively count k-mers in the given
input, which appear more times than given threshold. Using the GIR trait it would be
easy to implement such functionality within katome. This could prove beneficial to the
application, because Bloom filter is known to be a memory-optimal solution to the
input-tracking problem, which all assemblers need to solve to create contigs.
Furthermore, 'BFCounter' uses disk to store the intermediate structures during counting,
which most probably influences its run time. By storing these structures in memory we
are looking at the potential speed-up of the input processing.

===== Run time optimization at the cost of memory usage
<run-time-optimization-at-the-cost-of-memory-usage>
For small organisms users might opt-in into faster assembly, at the cost of memory
usage, which for small algorithms could be negligible. I observed a speed-up of at least
30% of the entire assembly time in _katome_ on varied data, after adding an already-seen
nodes tracking hash map to the 'BFCounter' input type graph building algorithm. I
believe that there are places in the code, in which similar trade-offs could be
beneficial to the user. It would therefore be a good idea to design and implement robust
API for the user to choose between run time reduction and memory usage reduction.
