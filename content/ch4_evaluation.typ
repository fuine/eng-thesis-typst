#import "../utils.typ": table-with-notes

= Evaluation
<evaluation>
Evaluation of genome assemblers can be split into two categories:
- Quality
- Performance
I compare _katome_ to three other assemblers, two assemblers chosen by me, as
subjectively leading solutions on the current market:
- Abyss~@simpson2009abyss;
- Velvet~@zerbino2008velvet;
and the assembler _dnaasm_~@dnaasm. Rough size of the original genome for all of the
organisms is given, in both quality and performance evaluations.

== Quality
<quality>
Quality of genome assembly can be assessed by comparing four statistics:

- number of created contigs;

- N50 statistic --- the shortest contig length at 50% of the genome;
- length of the longest contig;
- number of misassemblies
  #block(inset: (left: 1em))[
    The number of misassemblies, using Plantagora's definition. Plantagora defines a
    misassembly breakpoint as a position in the assembled contigs where the left
    flanking sequence aligns over 1 kb away from the right flanking sequence on the
    reference, or they overlap by >1kb, or the flanking sequences align on opposite
    strands or different chromosomes;
  ]
- mismatches per 100 kbp (kilo base pairs)
  #block(inset: (left: 1em))[
    The average number of mismatches per 100 000 aligned bases. (…) This metric does not
    distinguish between single-nucleotide polymorphisms, which are true differences in
    the assembled genome versus the reference genome, and single-nucleotide errors,
    which are due to errors in reads or errors in the assembly algorithm;
  ]
- indels per 100 kbp
  #block(inset: (left: 1em))[
    The average number of single nucleotide insertions or deletions per
    100 000 aligned bases.
  ]

Definitions for No.~of misassemblies, mismatches per 100kbp and indels per 100kbp
after #cite(<gurevich2013quast>, form: "prose");. Generally assemblers strive to achieve
the least number of long contigs. Ideal assembler running on perfect read data should
yield one contig per chromosome, which would represent entire chromosome.

Currently both _katome_ and _dnaasm_ generate contigs and their reverse complement,
meaning that generated data is redundant, as each contig can be found twice --- once in
the coding strand and once in the complementary strand. In the following quality
assessment I will show the number of contigs created by both _katome_ and _dnaasm_ as
divided by two, to fairly compare redundant data.

Evaluation of created contigs has been performed with the 'QUAST' --- quality assessment
tool for genome assemblers~@gurevich2013quast.

Presented results are generated using the following settings for all assemblers:

- k-mer size: $55$;
- reverse complement sequence generation: yes;
- use of paired sequences: no;
- graph correction where possible: yes.


#let dataset-table(organism: none, ..args) = {
  figure(
    table(
      columns: 5,
      align: center,
      table.header(
        [size of the genome \[bp\]], [number of chromosomes], [number of reads], [mean length of read], [coverage],
      ),
      ..args
    ),
    caption: [Dataset description for bacteria #emph(organism) genome],
  )
}

#let quality-table(organism: none, ..args) = {
  figure(
    kind: table,
    table-with-notes(
      columns: 7,
      align: center + horizon,
      inset: 3pt,
      notes: [
        #super[1] Length of the longest contig.
        #super[2] Mismatches per 100 kbp.
        #super[3] Indels per 100 kbp.
      ],
      table.header(
        [assembler], [number of contigs], "N50 [bp]", [longest#super[1] \[bp\]], [misassemblies], [mismatches#super[2]], [indels#super[3]]
      ),
      ..args,
    ),
    caption: [Quality of assembly on synthetic reads based on #emph(organism) genome],
  )
}

=== Synthetic data generated on the basis of natural data
<synthetic-data-generated-on-the-basis-of-natural-data>
Reads for assemblers have been randomly generated, with uniform distribution (standard
deviation 20), based on the reference genome of the bacteria Escherichia Coli. All reads
are perfect, meaning they don't contain any read errors. The dataset for the bacteria
Escherichia coli is described in the @ecoli_dataset and the results of the quality
evaluation are described in the @qual_coli.

#dataset-table(
  organism: [Escherichia coli],
  [4M], [1], [3180956], [100], [80],
)<ecoli_dataset>

#quality-table(
  organism: [Escherichia coli],
  [katome], [576], [118966], [265135], [0], [0.00], [0.00],
  [dnaasm], [427], [118966], [265135], [0], [0.00], [0.00],
  [velvet], [160], [118966], [265135], [0], [0.05], [0.03],
  [ abyss], [279], [118966], [265135], [0], [0.05], [0.00],
)<qual_coli>

=== Natural data
<natural-data>
==== Saccharomyces cerevisiae
<saccharomyces-cerevisiae>
Data for strain `S288C` of the yeast genome. The dataset for the yeast is described in
the @yeast_dataset and the results of the quality evaluation are described in the
@qual_yeast.

#dataset-table(
  organism: [Saccharomyces cerevisiae],
  [12M], [16], [4862828], [100], [43]
)<yeast_dataset>

#quality-table(
  organism: [Saccharomyces cerevisiae],
  [katome], [15584], [38353], [140369], [0], [0.22], [0.08],
  [dnaasm], [6448], [38353], [140369], [0], [0.26], [0.05],
  [velvet], [1982], [38520], [140369], [0], [0.58], [0.02],
  [abyss], [3527], [38520], [140369], [0], [1.62], [0.14],
)<qual_yeast>

==== Caenorhabditis elegans
<caenorhabditis-elegans>
The dataset for the Caenorhabditis elegans is described in the @roundworm_dataset and
the results of the quality evaluation are described in the @qual_roundworm.

#dataset-table(
  organism: [Caenorhabditis elegans],
  [100M], [6], [40114554], [100], [42]
)<roundworm_dataset>

#quality-table(
  organism: [Caenorhabditis elegans],
  [katome], [380424], [14051], [130755], [0], [0.10], [0.07],
  [dnaasm], [154391], [14051], [130755], [0], [0.15], [0.04],
  [velvet], [43802], [14363], [130755], [0], [0.22], [0.02],
  [abyss],  [104271], [13943], [130755], [0], [2.30], [0.28],
)<qual_roundworm>

== Performance
<eval:performance>
In this section I present performance results of _katome_, in comparison to other
solutions. Unless stated otherwise size of the k-mer for these evaluations is $55$. Each
cell in the table contains mean time of execution, standard deviation of that time and
peak memory usage of the application. Data that assemblers are tested on is too big to
perfectly measure memory usage (e.g.~via 'valgrind'), and so the memory usage of the
application is probed every 1 millisecond and the peak is reported. While this approach
is not ideal (it can miss the exact peak and report lower usage) in practice this method
turns out to be good enough to estimate the memory usage of the assemblers.

All benchmarks have been performed using the hardware and software listed in the
@smyrna_hw_sw.

#figure(
  table(
    columns: 3,
    align: center + horizon,
    stroke: none,
    inset: 5pt,
    table.hline(),
    table.cell(rowspan: 2, [System]), [Kernel], "3.16.0-4-amd64 x86_64 (64 bit)",
    table.hline(start: 2, stroke: 0.5pt),
    [Distro], [Debian GNU/Linux 8],
    table.hline(start: 2, stroke: 0.5pt),
    table.cell(colspan: 2, [CPUs]), [2 Octa core Intel Xeon E5-2630 v3s cache: 40 MB],
    table.hline(start: 2, stroke: 0.5pt),
    table.cell(colspan: 2, [Drives]), [2 WDC\_WD1000DHTZ size: 1 TB, working in RAID 1],
    table.hline(start: 2, stroke: 0.5pt),
    table.cell(colspan: 2, [Memory]), [252 GB],
    table.hline()
  ),
  caption: [Software and hardware used for performance evaluations of assemblers.],
)<smyrna_hw_sw>

==== Escherichia coli
<escherichia-coli>
Size of the original genome: 4M. Results are shown in the @performance_coli.

#let empty-cell = table.cell(rowspan: 3, line(length: 20%))
#let algo-line = table.hline(start: 2, stroke: 0.3pt)
#let performance-table(organism: none, ..args) = {
  figure(
    kind: table,
    table-with-notes(
      columns: 6,
      align: center + horizon,
      stroke: none,
      inset: 5pt,
      notes: [
        1 Without reverse complement generation.\
        2 With reverse complement generation.
      ],
      table.hline(),
      table.cell(rowspan: 2, colspan: 2, []), table.cell(colspan: 2, [FASTQ]), table.cell(colspan: 2, [BFCounter]),
      algo-line,
      [1], [2], [1], [2],
      table.hline(),
      ..args,
      table.hline()
    ),
    caption: [Performance of assemblers for #emph(organism) genome],
  )
}

#performance-table(
  organism: [E. coli],
  table.cell(rowspan: 9, [katome]), table.cell(rowspan: 3, [PtGraph]), [104.9s], [180.8s], [12.0s], [35.6s],
  [std=0.67s], [std=3.68s], [std=0.16s], [std=0.00s],
  [1392 MB], [1396 MB], [605 MB], [1194 MB],
  algo-line,
  table.cell(rowspan: 3, [HmGIR]), [136.1s], [193.2s], empty-cell, empty-cell,
  [std=1.01s], [std=3.90s],
  [1592 MB], [1590 MB],
  algo-line,
  table.cell(rowspan: 3, [HsGIR]), [165.3s],  [293.7s], empty-cell, empty-cell,
  [std=0.11s], [std=0.04s],
  [1724 MB], [1724 MB],
  algo-line,
  table.cell(colspan: 2, rowspan: 3, [dnaasm]), [136.9s], [226.6s], [41.9s], [41.9s],
  [std=0.66s], [std=0.19s], [std=1.05s], [std=0.21s],
  [1367 MB], [1364 MB], [1363 MB], [1364 MB],
  algo-line,
  table.cell(colspan: 2, rowspan: 3, [velvet]), [140.2s],  empty-cell, empty-cell, empty-cell,
  [std=0.69s],
  [582 MB],
  algo-line,
  table.cell(colspan: 2, rowspan: 3, [abyss]), [95.29s],  empty-cell, empty-cell, empty-cell,
  [std=0.2687s],
  [516 MB],
)<performance_coli>

==== Saccharomyces cerevisiae
<saccharomyces-cerevisiae>
Size of the original genome: 12M. Results are shown in the @performance_yeast.

#performance-table(
  organism: [Saccharomyces cerevisiae],
  table.cell(rowspan: 9, [katome]), table.cell(rowspan: 3, [PtGraph]), [170.1s], [299.0s], [36.8s], [96.2s],
  [std=0.12s], [std=0.41s], [std=0.16s], [std=2.63s],
  [3594 MB], [3595 MB], [2054 MB], [3077 MB],
  algo-line,
  table.cell(rowspan: 3, [HmGIR]), [249.6s], [370.2s], empty-cell, empty-cell,
  [std=0.11s], [std=1.88s],
  [4710 MB], [4502 MB],
  algo-line,
  table.cell(rowspan: 3, [HsGIR]), [288.4s],  [465.2s], empty-cell, empty-cell,
  [std=0.43s], [std=0.17s],
  [5192 MB], [5063 MB],
  algo-line,
  table.cell(colspan: 2, rowspan: 3, [dnaasm]), [231.5s], [468.4s], [132.0s], [131.9s],
  [std=0.57s], [std=1.33s], [std=0.45s], [std=0.74s],
  [3923 MB], [3926 MB], [3928 MB], [3922 MB],
  algo-line,
  table.cell(colspan: 2, rowspan: 3, [velvet]), [218.0s],  empty-cell, empty-cell, empty-cell,
  [std=0.566s],
  [1026 MB],
  algo-line,
  table.cell(colspan: 2, rowspan: 3, [abyss]), [174.9s],  empty-cell, empty-cell, empty-cell,
  [std=0.417s],
  [822 MB],
)<performance_yeast>

==== Caenorhabditis elegans
Size of the original genome: 100M. Results are shown in the @performance_roundworm.

#performance-table(
  organism: [Caenorhabditis elegans],
  table.cell(rowspan: 9, [katome]), table.cell(rowspan: 3, [PtGraph]), [1622.0s], [2776.0s], [432.2], [1183.0s],
  [std=14.9s], [std=8.1s], [std=0.37s], [std=5.0s],
  [28784 MB], [28788 MB], [16533 MB], [25052 MB],
  algo-line,
  table.cell(rowspan: 3, [HmGIR]), [2416.0s],  [3683.0s], empty-cell, empty-cell,
  [std=40.06s], [std=10.47s],
  [38277 MB], [38244 MB],
  algo-line,
  table.cell(rowspan: 3, [HsGIR]), [3001.0s],  [4516.1s], empty-cell, empty-cell,
  [std=306.06s], [std=19.46s],
  [41246 MB], [41231 MB],
  algo-line,
  table.cell(colspan: 2, rowspan: 3, [dnaasm]), [2129.0s], [3864.0s], [1288.0s], [1298.0s],
  [std=4.01s], [std=29.2s], [std=8.59s], [std=10.87s],
  [32648 MB], [32645 MB], [32620 MB], [32621 MB],
  algo-line,
  table.cell(colspan: 2, rowspan: 3, [velvet]), [3035.0s],  empty-cell, empty-cell, empty-cell,
  [std=5.62s],
  [7277 MB],
  algo-line,
  table.cell(colspan: 2, rowspan: 3, [abyss]), [1807.0s],  empty-cell, empty-cell, empty-cell,
  [std=11.26s],
  [3378 MB],
)<performance_roundworm>
