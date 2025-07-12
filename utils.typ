#import "@preview/drafting:0.2.2": inline-note
#import "@preview/glossarium:0.5.6": print-glossary
#import "@preview/lovelace:0.3.0": *
#import "@preview/theorion:0.3.3": *
#import cosmos.rainbow: *

#let definition = definition.with(fill: blue.darken(10%))
#let definition-box = definition-box.with(fill: blue.darken(10%))
#let (property-counter, property-box, property, show-property) = make-frame(
  "property",
  "Property", // supplement, string or dictionary like `(en: "Theorem")`, or `theorion-i18n-map.at("theorem")` for built-in i18n support
  inherited-levels: 2, // useful when you need a new counter
  inherited-from: heading, // heading or just another counter
  render: render-fn.with(fill: orange),
)

#let glossary-outline(glossary) = {
  context {
    let lang = text.lang
    let glossary-text = if lang == "en" { "List of Symbols and Abbreviations" } else {
      "Wykaz symboli i skrótów"
    }
    heading(numbering: none, glossary-text)
    show figure: it => [#v(-1em) #it #v(-1em)]
    print-glossary(glossary, show-all: true, disable-back-references: true)
  }
}

#let todo(it) = [
  #let caution-rect = rect.with(inset: 1em, radius: 0.5em)
  #inline-note(rect: caution-rect, stroke: color.fuchsia, fill: color.fuchsia.lighten(
    80%,
  ))[
    #align(center + horizon)[#text(fill: color.fuchsia, weight: "extrabold")[TODO:] #it]
  ]
]

#let table-with-notes(notes: none, ..args) = layout(size => {
  let tbl = table(..args)
  let w = measure(..size, tbl).width
  stack(dir: ttb, spacing: 0.5em, tbl, align(left + top, block(width: w, notes)))
})

#let code-listing-figure(caption: none, content) = {
  figure(caption: caption, rect(stroke: (y: 1pt + black), align(left, content)))
}

#let code-listing-file(filename, caption: none) = {
  let extension = filename.split(".").last()
  code-listing-figure(
    raw(block: true, lang: extension, read("code_snippets/" + filename)),
    caption: caption,
  )
}

#let algorithm(content, caption: none, ..args) = {
  figure(
    pseudocode-list(..args, booktabs: true, hooks: .5em, content),
    caption: caption,
    kind: "algorithm",
    supplement: [Algorithm],
  )
}

#let comment(body) = {
  text(size: .85em, fill: gray.darken(30%), sym.triangle.stroked.r + sym.space + body)
}

#let larrow = sym.arrow.l

// Tab10 from matplotlib
#let my-colors = (
  rgb("#1f77b4"),
  rgb("#ff7f0e"),
  rgb("#2ca02c"),
  rgb("#d62728"),
  rgb("#9467bd"),
  rgb("#8c564b"),
  rgb("#e377c2"),
  rgb("#7f7f7f"),
)
