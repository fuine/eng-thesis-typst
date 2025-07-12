= Introduction
<introduction>
== Goals
<goals>
The goal of this work was to propose redesign of the in-memory de novo genome assembler
for next generation sequencers. Main assumptions about the new design are as follow:

- efficient memory layout --- lowering the memory usage to the minimum;

- on-par speed --- memory optimization should not hurt the performance of the assembler,
  as tested against previous implementation;
- support for parallelism/concurrency in the algorithms within assembler;
- modular design allowing user to easily change the internal layout of the assembler.

== Structure
<structure>
This thesis is divided into 7 chapters:

+ Introduction --- goals and the structure of the thesis;

+ DNA Assembling --- overview of the assembling techniques and de novo assemblers,
  depiction of the data structures used throughout the project;
+ Algorithms --- definitions of new algorithms introduced in this thesis;
+ Implementation --- language, tooling and layout of the created assembler. Contains
  statistics for the code as well as testing summary;
+ Optimization --- description of memory and run-time optimizations implemented in the
  project;
+ Evaluation --- quality and performance assessments of the implemented assembler on
  different datasets;
+ Summary --- conclusions and future work sketch.

Additionally @user_manual is provided, which holds the user manual for the created assembler.
