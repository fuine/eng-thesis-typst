# Implementation of the de novo genome assembler in the Rust programming language

This repo contains a rewritten version of my bachelor's thesis from Latex to Typst. 
Structure of the thesis is based on the [wut-thesis](https://typst.app/universe/package/wut-thesis) template.
[Rendered version](./build/rendered.pdf)

This thesis includes the following interesting typesetting objects (subjectively chosen):

- Multi-page algorithms
- Several different `cetz` diagrams
- Tables with footnotes and multi-column/multi-row cells
- Mathematical properties and definitions

## Compilation
To compile the thesis [install Typst](https://github.com/typst/typst#installation), make sure you have `Adagio_Slab` font installed as described in the template instructions and run:

```bash
typst c thesis.typ
```

which should produce a `thesis.pdf` file.

## Compilation benchmarks
| Command | Mean [s] | Min [s] | Max [s] | Relative |
|:---|---:|---:|---:|---:|
| `typst c thesis.typ` | 2.472 ± 0.021 | 2.446 | 2.500 | 1.00 |
| ` latexmk -pdflatex="lualatex --shell-escape --interaction=nonstopmode %O %S" -pdf main.tex` | 24.570 ± 0.071 | 24.460 | 24.684 | 9.94 ± 0.09 |
