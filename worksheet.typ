// Native Typst worksheet components. Lengths are intentionally explicit.
#let line-height = 12pt
#let page-margin = 1.5cm
#let label-width = 1cm
#let column-gutter = 1cm
// Optional example style, not a worksheet-wide default or graph requirement.
// Use, adapt, or omit it in native simple-plot 1.1.0 calls: `plot(..graph-options, ...)`.
// Its axis arrows are end markers: position the second at the path's start
// and reverse it. Disable shortening for that marker to preserve the axis line.
#let graph-options = (
  axis-x-extend: (0.3cm, 0.3cm),
  axis-y-extend: (0.3cm, 0.3cm),
  tick-label-size: 12pt,
  axis-label-size: 12pt,
  style: (
    axis: (
      stroke: black + 0.5pt,
      arrow: (
        (symbol: "stealth", fill: black, scale: 0.55, pos: 0%),
        (symbol: "stealth", fill: black, scale: 0.55, pos: 100%, reverse: true, shorten-to: none),
      ),
    ),
    ticks: (stroke: black + 0.5pt),
  ),
)
#let numbered-pages = state("worksheet-numbered-pages", false)
#let page-capacity(numbered) = 29.7cm - 2 * page-margin - if numbered { 2 * line-height } else { 0pt }
#let q-counter(kind) = counter("worksheet-" + kind)
#let check-keys = sys.inputs.at("worksheet-check-keys", default: "false") == "true"
#let key-numbers(kind) = state("worksheet-key-numbers-" + kind, ())

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
  if check-keys {
    for kind in ("answers", "solutions") { key-numbers(kind).update(()) }
  }
  layout(size => {
    let name-start = size.width * 2 / 3
    grid(columns: (name-start - 2cm, 2cm, size.width - name-start), align: top,
      strong(title), [], [Name: #h(0.3em)#box(width: 1fr, move(dy: 2pt, line(length: 100%, stroke: 0.5pt)))])
  })
  v(12pt, weak: true)
  body
}

#let validate-working(working) = {
  assert(working == none or (type(working) == int and working >= 0),
    message: "Part working space must be none or a non-negative whole number of 12 pt lines.")
}
#let part(body, ref: none, marks: none, parts: (), working: none) = {
  validate-working(working)
  (body: body, ref: ref, marks: marks, parts: parts, working: working)
}
#let task(body, ref: none, marks: none, working: none) = {
  validate-working(working)
  (body: body, ref: ref, marks: marks, working: working)
}
// Resolve only in the rendering context: the same constructors also serve
// shared instructions, answers, and solutions, where overrides are invalid.
#let resolve-working(working, inherited, role) = {
  assert(role == "questions" or working == none,
    message: "Explicit part working space is not supported in " + role + ".")
  if role != "questions" { 0 } else if working == none { inherited } else { working }
}
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
#let next-part-number(n, ref, style, kind) = {
  assert(kind != "questions" or ref == none,
    message: "Question parts and shared instructions are numbered automatically. Use ref in answers or solutions.")
  if ref == none { n + 1 } else { reference(ref, style) }
}
#let mark-text(marks) = {
  assert(type(marks) == int and marks > 0, message: "Marks must be a positive integer.")
  "[" + str(marks) + if marks == 1 { " mark]" } else { " marks]" }
}
#let mark-reserve(marks) = if marks == none { 0pt } else { measure(mark-text(marks)).width + 2 * text.size }
#let marked(body, marks, after: []) = {
  if marks == none { body + after } else {
    let mark = mark-text(marks)
    context {
      let reserve = mark-reserve(marks)
      // The zero-width endpoint follows the final line across page breaks.
      // Align marks to the right content edge of A4.
      pad(right: reserve, [#body#box(width: 0pt, height: 0pt, baseline: 0pt)[
        #context {
          let x = here().position().x
          place(top + left, dx: 21cm - page-margin - x - measure(mark).width, dy: -9.6pt, box(width: measure(mark).width, mark))
        }
      ]#after])
    }
  }
}
// Typst's measure() exposes size, but not the first baseline. A zero-width
// probe with a known descent lets us recover it from an inline measurement.
// Only the measured copy is boxed; the rendered prompt remains breakable.
#let first-baseline(body, width) = {
  let wrapped = box(width: width, body)
  let depth = measure(wrapped).height + line-height
  measure([#wrapped#box(width: 0pt, height: depth, baseline: top)]).height - depth
}
#let labelled(label, body, baseline: none) = layout(size => {
  let label-baseline = first-baseline(label, label-width)
  let body-baseline = if baseline == none { first-baseline(body, size.width - label-width) } else { baseline }
  let shared-baseline = calc.max(label-baseline, body-baseline)
  grid(columns: (label-width, 1fr), align: top,
    pad(top: shared-baseline - label-baseline, label),
    pad(top: shared-baseline - body-baseline, body))
})

// Metadata is consumed by scripts/compile.py; Typst does not expose a custom
// non-fatal warning primitive. Inspect each equation/word rather than measuring
// a whole paragraph at its unwrapped width.
#let check-width(body, width, label, marks: none) = context {
  let width = width - mark-reserve(marks)
  let visit(node) = {
    if node.func() == math.equation {
      let natural = measure(node)
      if natural.width > width {
        let fitted = measure(node, width: width)
        // Typst caps the reported width of an overflowing line at the available
        // width. A wrapped equation with a shorter widest line fits cleanly.
        if fitted.width >= width - 0.01pt {
          let message = if fitted.height <= natural.height + 0.01pt {
            "Unbreakable mathematics exceeds column width"
          } else { "Mathematics wraps at the column limit; inspect the widest line" }
          [#metadata((kind: "worksheet-caution", message: message, label: label, width-pt: natural.width.pt(), available-pt: width.pt())) <worksheet-caution>]
        }
      }
    } else if node.has("text") {
      for word in node.text.split(regex("\\s+")) {
        if word != "" and measure(text(word)).width > width {
          [#metadata((kind: "worksheet-caution", message: "Unbreakable word exceeds column width", label: label, word: word)) <worksheet-caution>]
        }
      }
    } else if node.has("children") {
      for child in node.children { visit(child) }
    } else if node.has("child") { visit(node.child) }
    else if node.has("body") and type(node.body) == content { visit(node.body) }
  }
  visit(body)
}

#let standalone(label, body, marks, working, number) = layout(size => {
  let space = working * line-height
  let limit = page-capacity(numbered-pages.get())
  let message = "Question " + str(number) + ": the end of its prompt and the requested working space exceed a page's available content height."
  assert(line-height + space <= limit, message: message)
  let content = marked(body, marks)
  let prompt = labelled(label, content)
  let with-space(it) = block(breakable: false)[#it#block(height: space)]
  if measure(prompt, width: size.width).height + space <= limit {
    with-space(prompt)
  } else {
    // Extend only the final line of a long paragraph. Opposite baseline probes
    // recover its actual ascent and descent, including fractions and subscripts.
    let available = size.width - label-width
    let reserve = mark-reserve(marks)
    let height(it) = measure(it, width: available - reserve).height
    let total = height(body)
    let probe = total + line-height
    let strut(h, anchor) = box(width: 0pt, height: h, baseline: anchor)
    let ascent = total + probe - height(body + strut(probe, bottom))
    let descent = total + probe - height(body + strut(probe, top))
    let baseline = first-baseline(content, available)
    if ascent + descent > 0.01pt {
      assert(ascent + descent + space <= limit, message: message)
      labelled(label, marked(body, marks, after: strut(descent + space, top)), baseline: baseline)
    } else {
      // An inline probe following a display occupies a new line. Keep the
      // display itself with the writing area while earlier content can flow.
      let pieces = if body.func() == [].func() { body.children } else { (body,) }
      while pieces.len() > 1 and pieces.last().func() in ([ ].func(), parbreak) { let _ = pieces.pop() }
      let last = pieces.pop()
      let suffix = last
      // Keep trailing labels or metadata with the actual printed display.
      while pieces.len() > 0 and height(suffix) == 0pt {
        last = pieces.pop()
        suffix = last + suffix
      }
      let tail = marked(suffix, marks)
      let tail-height = measure(tail, width: available).height
      let ending = if tail-height + space <= limit {
        with-space(tail)
      } else {
        // A flowing paragraph, table or automatic-height block may itself be
        // longer than a page. Leave room in its fragments for the writing area.
        // Fixed-height figures must travel as a unit even if Typst would split
        // a fixed-height block into a printed fragment and an empty fragment.
        let flows(it) = {
          if it.func() == block { it.at("height", default: auto) == auto and it.at("breakable", default: true) }
          else if it.func() in (par, grid, table) { true }
          else if it.has("child") { flows(it.child) }
          else if it.func() in (align, pad) { flows(it.body) }
          else { false }
        }
        assert(flows(last), message: message)
        pad(bottom: space)[#tail#context {
          assert(here().position().y + space <= 29.7cm - page-margin + 0.01pt, message: message)
        }]
      }
      let prefix = pieces.join([], default: [])
      labelled(label, [
        #if prefix != [] { pad(right: reserve, prefix) }
        #ending
      ], baseline: baseline)
    }
  }
})
#let roman-list(items, kind, prefix, available, working: 0, shared: false, first-label: none, ending-space: 0) = {
  let n = 0
  for (index, item) in items.enumerate() {
    let resolved = resolve-working(item.working, working, if shared { "shared instructions" } else { kind })
    n = next-part-number(n, item.ref, "i", kind)
    let roman = "(" + numbering("i", n) + ")"
    check-width(item.body, available, prefix + roman, marks: item.marks)
    let label = if index == 0 and first-label != none {
      [#h(-label-width)#box(width: label-width, first-label)#roman]
    } else { roman }
    if ending-space > 0 and index + 1 == items.len() {
      standalone(label, item.body, item.marks, ending-space, prefix)
    } else { labelled(label, marked(item.body, item.marks)) }
    if resolved > 0 { v(resolved * line-height) }
    if index + 1 < items.len() { v(12pt) }
  }
}
#let rows(items, columns, working, kind, question-number, first-label: none) = {
  assert(type(columns) == int and columns > 0, message: "Columns must be a positive integer.")
  let n = 0
  let cells = ()
  for item in items {
    n = next-part-number(n, item.ref, "a", kind)
    assert(columns == 1 or item.marks == none, message: "Marks are not supported on parts in multiple columns.")
    assert(columns == 1 or item.parts.all(it => it.marks == none), message: "Marks are not supported on Roman sub-parts in multiple columns.")
    let label = "(" + numbering("a", n) + ")"
    assert(item.parts.len() == 0 or item.body != [] or item.marks == none, message: "Part-level marks require a written prompt; put marks on individual Roman sub-parts when the part has no prompt.")
    cells.push((label: label, item: item))
  }
  for start in range(0, cells.len(), step: columns) {
    layout(size => {
      let width = (size.width - label-width - (columns - 1) * column-gutter) / columns
      assert(width > label-width, message: "Too many columns: no width remains after the 1 cm part label.")
      let label-baseline = first-baseline([1.], label-width)
      let row-cells = cells.slice(start, calc.min(start + columns, cells.len())).map(cell => {
        let item = cell.item
        let address = str(question-number) + cell.label
        let resolved = resolve-working(item.working, working, kind)
        let content = if item.parts.len() > 0 {
          assert(width > 2 * label-width, message: address + ": no width remains after the Roman label. Use fewer columns.")
          [#marked(item.body, item.marks)#if item.body != [] { v(12pt) }#roman-list(item.parts, kind, address, width - 2 * label-width, working: resolved)]
        } else {
          [#marked(item.body, item.marks)#if resolved > 0 { v(resolved * line-height) }]
        }
        // Grids do not propagate their first baseline. For a promptless part,
        // take it from the first Roman task before nesting the label grids.
        let baseline = if item.body == [] and item.parts.len() > 0 {
          let first = item.parts.first()
          calc.max(label-baseline, first-baseline(marked(first.body, first.marks), width - 2 * label-width))
        } else { first-baseline(marked(item.body, item.marks), width - label-width) }
        let body = [#check-width(item.body, width - label-width, address, marks: item.marks)#labelled(cell.label, content, baseline: baseline)]
        (body: body, baseline: calc.max(label-baseline, baseline))
      })
      let shared-baseline = calc.max(..row-cells.map(cell => cell.baseline))
      let row = grid(columns: (1fr,) * columns, column-gutter: column-gutter, align: top,
        ..row-cells.map(cell => pad(top: shared-baseline - cell.baseline, cell.body)))
      let label = if start == 0 and first-label != none {
        pad(top: shared-baseline - label-baseline, first-label)
      } else { [] }
      // Each cell owns its working areas. Measure the tallest complete cell,
      // rather than adding a shared allowance below the tallest content.
      let complete = grid(columns: (label-width, 1fr), align: top, label, row)
      let height = measure(complete, width: size.width).height
      // Conservative numbered-page limit ensures the row can fit on every page.
      let limit = page-capacity(numbered-pages.get() and kind == "questions")
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
  // During Typst's initial layout pass the counter can still be zero. Wait for
  // the real label before rendering or issuing a question-specific diagnostic.
  context if q-counter(kind).get().first() > 0 {
    let n = q-counter(kind).get().first()
    if check-keys and kind != "questions" {
      assert(n <= q-counter("questions").get().first(),
        message: "The " + kind + " refer to question " + str(n) + ", which does not exist.")
      let seen = key-numbers(kind)
      assert(n not in seen.get(), message: "Duplicate entry for question " + str(n) + " in " + kind + ".")
      seen.update(numbers => numbers + (n,))
    }
    let keep-working = parts.len() == 0 and working > 0
    if body != [] {
      if keep-working and tasks.len() == 0 {
        standalone(str(n) + ".", body, marks, working, n)
      } else { labelled(str(n) + ".", marked(body, marks)) }
      if tasks.len() > 0 or parts.len() > 0 { v(12pt) }
    } else {
      assert(marks == none, message: "Question-level marks require a written prompt.")
      if kind == "questions" and tasks.len() == 0 and parts.len() == 0 {
        if keep-working { standalone(str(n) + ".", [], none, working, n) }
        else { labelled(str(n) + ".", []) }
      }
    }
    if tasks.len() > 0 {
      layout(size => pad(left: label-width, roman-list(tasks, kind, str(n), size.width - 2 * label-width,
        shared: true, first-label: if body == [] { str(n) + "." },
        ending-space: if keep-working { working } else { 0 })))
      if parts.len() > 0 or not keep-working { v(12pt) }
    }
    if parts.len() > 0 {
      rows(parts, columns, working, kind, n, first-label: if body == [] and tasks.len() == 0 { str(n) + "." } else { none })
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
