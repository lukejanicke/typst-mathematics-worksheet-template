// Native Typst worksheet components. Lengths are intentionally explicit.
#let line-height = 12pt
#let page-margin = 1.5cm
#let label-width = 1cm
#let column-gutter = 1cm
#let numbered-pages = state("worksheet-numbered-pages", false)
#let q-counter(kind) = counter("worksheet-" + kind)

#let worksheet(title: [], page-numbers: false, text-font: "STIX Two Text", math-font: "STIX Two Math", body) = {
  set document(title: title)
  set page(paper: "a4", margin: page-margin, numbering: none, header: none, footer: none)
  set text(font: text-font, size: 12pt, lang: "en", region: "AU", top-edge: 0.8em, bottom-edge: -0.2em)
  set par(leading: 0pt, spacing: 12pt)
  set block(above: 0pt, below: 0pt)
  set table(stroke: 0.5pt)
  show math.equation: set text(font: math-font)
  show heading: set text(size: 12pt, weight: "regular")
  show heading: it => {
    assert(it.level <= 3, message: "Worksheet headings support levels 1–3 only.")
    block(width: 100%, above: 12pt, below: 12pt, sticky: true, if it.level == 1 { align(center, strong(it.body)) } else if it.level == 2 { strong(it.body) } else { emph(it.body) })
  }
  // Reserve 24 pt inside continuation pages; undo that reserve on page 1.
  set page(margin: (top: page-margin + if page-numbers { 24pt } else { 0pt }, rest: page-margin), header-ascent: 12pt,
      header: context if page-numbers and counter(page).get().first() > 1 {
        align(center, box(height: 12pt, str(counter(page).get().first())))
      })
  if page-numbers { v(-24pt, weak: false) }
  numbered-pages.update(page-numbers)
  q-counter("questions").update(0)
  layout(size => {
    let name-start = size.width * 2 / 3
    grid(columns: (name-start - 2cm, 2cm, size.width - name-start), align: top,
      strong(title), [], [Name: #h(0.3em)#box(width: 1fr, move(dy: 2pt, line(length: 100%, stroke: 0.5pt)))])
  })
  v(12pt, weak: true)
  body
}

#let part(body, ref: none, marks: none, parts: ()) = (body: body, ref: ref, marks: marks, parts: parts)
#let task(body, ref: none, marks: none) = (body: body, ref: ref, marks: marks)
#let reference(value, style) = {
  if type(value) == int { assert(value > 0); value }
  else {
    assert(type(value) == str, message: "References must be positive integers or label strings.")
    let labels = if style == "a" { range(1, 703).map(n => numbering("a", n)) } else { range(1, 400).map(n => numbering("i", n)) }
    let index = labels.position(it => it == value)
    assert(index != none, message: "Invalid part reference: " + value)
    index + 1
  }
}
#let marked(body, marks) = {
  if marks == none { body } else {
    assert(type(marks) == int and marks > 0, message: "Marks must be a positive integer.")
    let mark = "[" + str(marks) + if marks == 1 { " mark]" } else { " marks]" }
    context {
      let reserve = measure(mark).width + 2em
      // The zero-width endpoint follows the final line across page breaks.
      // Align marks to the right content edge of A4.
      pad(right: reserve, [#body#box(width: 0pt, height: 0pt, baseline: 0pt)[
        #context {
          let x = here().position().x
          place(top + left, dx: 21cm - page-margin - x - measure(mark).width, dy: -9.6pt, box(width: measure(mark).width, mark))
        }
      ]])
    }
  }
}
#let labelled(label, body) = grid(columns: (label-width, 1fr), align: top, label, body)

// Metadata is consumed by scripts/compile.py; Typst does not expose a custom
// non-fatal warning primitive. Inspect each equation/word rather than measuring
// a whole paragraph at its unwrapped width.
#let check-width(body, width, label) = context {
  let visit(node) = {
    if node.func() == math.equation {
      let actual = measure(node).width
      if actual > width { [#metadata((kind: "worksheet-caution", message: "Unbreakable mathematics exceeds column width", label: label, width-pt: actual.pt(), available-pt: width.pt())) <worksheet-caution>] }
    } else if node.has("text") {
      for word in node.text.split(regex("\\s+")) {
        if word != "" and measure(text(word)).width > width {
          [#metadata((kind: "worksheet-caution", message: "Unbreakable word exceeds column width", label: label, word: word)) <worksheet-caution>]
        }
      }
    } else if node.has("children") {
      for child in node.children { visit(child) }
    } else if node.has("body") { visit(node.body) }
  }
  visit(body)
}

#let roman-list(items) = {
  let n = 0
  for item in items {
    n = if item.ref == none { n + 1 } else { reference(item.ref, "i") }
    labelled([(#numbering("i", n))], marked(item.body, item.marks))
    if item != items.last() { v(12pt) }
  }
}
#let rows(items, columns, working, kind, question-number) = {
  assert(type(columns) == int and columns > 0, message: "Columns must be a positive integer.")
  let n = 0
  let cells = ()
  for item in items {
    n = if item.ref == none { n + 1 } else { reference(item.ref, "a") }
    assert(columns == 1 or item.marks == none, message: "Marks are not supported on parts in multiple columns.")
    assert(columns == 1 or item.parts.all(it => it.marks == none), message: "Marks are not supported on Roman sub-parts in multiple columns.")
    let label = "(" + numbering("a", n) + ")"
    let cell = layout(size => {
      assert(size.width > label-width, message: "Too many columns: no width remains after the 1 cm part label.")
      check-width(item.body, size.width - label-width, str(question-number) + ". " + label)
      let content = if item.parts.len() > 0 {
        assert(item.body != [] or item.marks == none, message: "Part-level marks require a written prompt; put marks on individual Roman sub-parts when the part has no prompt.")
        [#marked(item.body, item.marks)#if item.body != [] { v(12pt) }#roman-list(item.parts)]
      } else { marked(item.body, item.marks) }
      labelled(label, content)
    })
    cells.push(cell)
  }
  for start in range(0, cells.len(), step: columns) {
    let row = grid(columns: (1fr,) * columns, column-gutter: column-gutter, align: top, ..cells.slice(start, calc.min(start + columns, cells.len())))
    layout(size => {
      let complete = [#row#v(working * line-height)]
      let height = measure(complete, width: size.width).height
      // Conservative numbered-page limit ensures the row can fit on every page.
      let limit = 29.7cm - 2 * page-margin - if numbered-pages.get() and kind == "questions" { 24pt } else { 0pt }
      assert(height <= limit, message: "Question " + str(question-number) + ": a part row and its working space exceed a page's available content height.")
      block(breakable: false, complete)
    })
    v(12pt)
  }
}
#let entry(kind, body, ref: none, parts: (), tasks: (), columns: 1, working: 0, marks: none) = {
  assert(type(working) == int and working >= 0, message: "Working space must be a non-negative whole number of 12 pt lines.")
  assert(kind != "questions" or ref == none, message: "Question numbering is automatic.")
  if ref == none { q-counter(kind).step() } else { q-counter(kind).update(reference(ref, "a")) }
  context {
    let n = q-counter(kind).get().first()
    let keep-working = parts.len() == 0 and working > 0
    // A sticky, breakable prompt keeps its final fragment with the fixed-height
    // working block, while long paragraphs can still flow across pages.
    let prompt = {
      // Keep the number with the first prompt line while permitting paragraph flow.
      if body != [] {
        labelled(str(n) + ".", marked(body, marks))
        if tasks.len() > 0 or parts.len() > 0 { v(12pt) }
      } else {
        assert(marks == none, message: "Question-level marks require a written prompt.")
        // Main label is attached to the first part row below.
      }
      if tasks.len() > 0 { pad(left: label-width, roman-list(tasks)); v(12pt) }
    }
    if keep-working {
      let limit = 29.7cm - 2 * page-margin - if numbered-pages.get() and kind == "questions" { 24pt } else { 0pt }
      assert((working + 1) * line-height <= limit, message: "Question " + str(n) + ": its working space and a prompt line exceed a page's available content height.")
      // Scope stickiness to this question so consecutive prompts stay independent.
      block(breakable: true)[
        #block(sticky: true, prompt)
        #block(height: working * line-height, breakable: false)
      ]
    } else { prompt }
    if parts.len() > 0 {
      if body == [] and tasks.len() == 0 { labelled(str(n) + ".", rows(parts, columns, working, kind, n)) }
      else { pad(left: label-width, rows(parts, columns, working, kind, n)) }
    }
    else { v(12pt) }
  }
}
#let question(body, parts: (), tasks: (), columns: 1, working: 0, marks: none) = entry("questions", body, parts: parts, tasks: tasks, columns: columns, working: working, marks: marks)
#let answer(body, ref: none, parts: (), tasks: (), columns: 1) = entry("answers", body, ref: ref, parts: parts, tasks: tasks, columns: columns)
#let solution(body, ref: none, parts: (), tasks: (), columns: 1) = entry("solutions", body, ref: ref, parts: parts, tasks: tasks, columns: columns)
#let section(kind, title, body) = {
  pagebreak()
  set page(margin: page-margin, header: none, footer: none)
  q-counter(kind).update(0)
  strong(title)
  v(12pt)
  body
}
#let answers(body) = section("answers", "Answers", body)
#let solutions(body) = section("solutions", "Solutions", body)
