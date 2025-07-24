#{
  import "@preview/wut-thesis:0.1.1": wut-thesis, acknowledgements, figure-outline, table-outline, appendix
  import "utils.typ": todo, glossary-outline, show-theorion, show-property
  import "glossary.typ": glossary
  import "@preview/glossarium:0.5.6": make-glossary, register-glossary, print-glossary, gls, glspl
  import "@preview/drafting:0.2.2": note-outline, set-margin-note-defaults

  show: show-theorion
  show: show-property
  show: make-glossary
  register-glossary(glossary)

  /** Drafting

    Set the boolean variables `draft` and `in-print` inside utils.typ.

    The "draft" variable is used to show DRAFT in the header and the title and TODOs.
    This should be true until the final version is handed-in.

    The "in-print" variable is used to generate a PDF file for physical printing (it adds
    bigger margins on the binding part of the page). If you want to create a PDF file for
    reading on screen (e.g. to upload to onedrive for the final thesis hand-in) set this
    variable to false.

  **/
  let draft = false
  let in-print = false
  set-margin-note-defaults(hidden: not draft)

  // Set the languages of your studies and thesis
  let lang = (
    // language in which you studied, influences the language of the titlepage
    studies: "pl",
    // language in which your thesis is written, influences the rest of the text (i.e.
    // abstracts order, captions/references supplements, hyphenation etc)
    thesis: "en"
  )

  show: wut-thesis.with(
    draft: draft,
    in-print: in-print,
    lang: lang,
    // Adjust the following fields accordingly to your thesis
    titlepage-info: (
      thesis-type: "engineer", // or "master" or "bachelor"
      program: "Informatyka", // or ""
      specialisation: "Inżynieria Systemów Informatycznych",
      institute: "Instytut Informatyki",
      supervisor: "dr hab. inż. Robert M. Nowak",
      advisor: none, // or `none` if there were no advisors
      faculty: "weiti",
      index-number: "261479",
      date: datetime(year: 2017, month: 1, day: 31), // or datetime.today()
    ),
    author: "Łukasz Neumann",
    // Note that irregardless of the language of your thesis you need to fill in all the
    // fields below - both *-en and *-pl
    title: (
      en: "Implementation of the de novo genome assembler in the Rust programming language",
      pl: "Implementacja asemblera genomu w języku programowania Rust",
    ),
    abstract: (
      en: [
        // max 1 page
        This thesis describes the design and the implementation of the de novo sequence
        assembler, written in the Rust programming language. The assembler is designed
        with respect to future parallelization of the algorithms, run time and memory usage
        optimization, and exclusive RAM usage. Moreover the application uses new
        algorithms for the correct assembly of repetitive sequences.

        Performance and quality tests were performed on various data, showing
        that the new assembler improves run time and memory usage in comparison to
        the `dnaasm`, `ABySS` and `Velvet` genome assemblers. Additionally, benchmarks
        indicate that the Rust-based implementation is comparable to the `dnaasm`
        project written in C++ concerning quality of created contigs, while
        outperforming it in terms of assembly time and memory usage.

        Quality tests indicate that the new assembler creates more contigs than
        well-established solutions, but the contigs have better quality with regard to
        mismatches per 100kbp and indels per 100kbp. Furthermore N50 statistics of
        created contigs are similar between different assemblers. All assemblers yield
        the same longest contig for each dataset.
      ],
      pl: [
        // max 1 page
        Niniejsza praca opisuje projekt i implementację asemblera DNA dla sekwencerów
        nowej generacji. Asembler został napisany w języku Rust. Jego architekturę
        oparto o możliwość zrównoleglenia algorytmów, optymalizację czasu działania i
        używanej pamięci, oraz wyłączne użycie pamięci RAM. Dodatkowo aplikacja pozwala
        na poprawne odtwarzanie powtarzalnych sekwencji. Program inspirowany był
        istniejącym asemblerem `dnaasm`.

        Przeprowadzone zostały testy jakości i wydajności dla kilku wybranych
        organizmów, porównując nowo powstały asembler z 3 innymi rozwiązaniami.
        Wyniki pokazują, że nowy asembler jest wydajniejszy od asemblera
        `dnaasm`, zarówno pod względem używanej pamięci, jak i czasu działania. Ponadto
        stwierdzono porównywalność jakości wyników aplikacji zaimplementowanej w języku Rust
        z aplikacją `dnaasm`, napisaną w języku C++, przy jednoczesnym mniejszym czasie
        działania i ilości zużytej pamięci.

        Testy jakości dowiodły, że nowy asembler tworzy więcej kontigów niż wiodące
        rozwiązania na rynku, jednakże tworzone kontigi mają lepszą jakość pod względem
        kryteriów `mismatches` oraz `indels` na 100 tys. par zasad. Dodatkowo statystyki
        N50 tworzonych kontigów są podobne do wyników innych asemblerów. Wszystkie
        asemblery utworzyły identyczne najdłuższe kontigi dla wszystkich danych
        testowych.
      ],
    ),
    keywords: (
      en: ("DNA assembling", "contigs", "optimization", "Rust"),
      pl: ("asembler DNA", "kontigi", "optymalizacja", "Rust"),
    )
  )

  // --- Custom Settings ---
  // if you want to override any settings from the template here is the place to do so,
  // e.g.:
  // set text(font: "Comic Sans MS")
  show heading.where(level: 5): set heading(outlined: false, numbering: none)
  set table(
    stroke: (x, y) => (
      top: if y <= 1 { 1pt } else { 0pt },
      bottom: 1pt,
    ),
    inset: (x: 5pt, y: 3pt),
  )

  // --- Main Chapters ---
  include "content/ch1_intro.typ"
  include "content/ch2_assemblers.typ"
  include "content/ch3_implementation.typ"
  include "content/ch4_evaluation.typ"
  include "content/ch5_summary.typ"

  // --- Acknowledgements ---
  // comment out if not needed
  // acknowledgements[
  //   We gratefully acknowledge Poland's high-performance Infrastructure PLGrid
  //   #text(fill: red)[(wybierz właściwy ośrodek z listy: ACK Cyfronet AGH, PCSS, CI TASK,
  //     WCSS)] for providing computer facilities and support within computational grant no
  //   #text(fill: red)[(numer grantu)]
  //   #todo[Numer grantu i typ ośrodka]
  // ]

  // --- Bibliography ---
  bibliography("bibliography.bib", style: "ieee")

  // List of Acronyms - comment out, if not needed (no abbreviations were used).
  glossary-outline(glossary)

  // List of figures - comment out, if not needed.
  figure-outline()

  // List of tables - comment out, if not needed.
  table-outline()

  // --- Appendices ---
  appendix(lang.thesis, include "content/ch6_manual.typ")

  if draft {
    set heading(numbering: none)
    note-outline(title: "TODOs")
  }
}
