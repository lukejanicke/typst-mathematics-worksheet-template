# Typst Mathematics Worksheet Template

A reusable template for high school mathematics worksheets, with familiar question numbering, space for working, and optional answers and worked solutions. Export one PDF for printing or for students to annotate on a tablet.

Designed around Western Australian Year 7–10 Mathematics and Year 11–12 Mathematics Methods classroom practice. The template controls presentation; you supply the questions, answers, and solutions.

## Examples

The example PDFs are included so you can inspect the output without installing Typst. Each PDF contains the worksheet followed by its answer and solution sections.

| Example | Typst source | PDF |
| --- | --- | --- |
| Linear equations: Year 8/9 practice, columns, marks, working space, a diagram, table, and graph | [Source](examples/linear-equations.typ) | [View PDF](examples/linear-equations.pdf) |
| Numbering and optional sections: omitted entries, explicit references, and counter resets | [Source](examples/numbering-subsets.typ) | [View PDF](examples/numbering-subsets.pdf) |

## Requirements

- **Typst 0.15.1**, the version used to develop and verify the template. Other versions have not been verified.
- **STIX Two Text** and **STIX Two Math**, installed where Typst can find them. Run `typst fonts` to check availability. You can select other fonts through the template options.
- **Python 3** for the compilation script and verification suite. No third-party Python packages are required.
- **Poppler's `pdftotext`** for verification only.

The template itself has no Typst package dependencies. The linear-equations example imports `@preview/simple-plot:1.1.0`; compiling it needs internet access on the first run to download that package and its dependencies.

## Quick start

Download or clone this repository. From its root directory, compile an example:

```sh
python3 scripts/compile.py examples/linear-equations.typ output/pdf/linear-equations.pdf
```

Open `output/pdf/linear-equations.pdf`. The script creates the output directory and prints any detected column-overflow cautions.

To create your own worksheet, save this as `my-worksheet.typ` beside `worksheet.typ`:

```typst
#import "worksheet.typ": worksheet, question, part, answers, answer
#show: worksheet.with(title: [Solving equations], page-numbers: true)

#question(working: 4, marks: 2)[Solve $2x + 5 = 19$.]

#question(columns: 2, working: 3, parts: (
  part[$x + 7 = 15$],
  part[$3y = 21$],
))[Solve each equation.]

#answers[
  #answer[$x = 7$]
  #answer(columns: 2, parts: (part[$x = 8$], part[$y = 7$]))[]
]
```

Compile it from the repository root:

```sh
python3 scripts/compile.py my-worksheet.typ output/pdf/my-worksheet.pdf
```

You can also copy `worksheet.typ` into another project and import it there. When compiling a file inside a subdirectory, set the Typst root to a directory containing both the document and the template.

Direct compilation works without Python, but does not print the template's custom overflow cautions:

```sh
typst compile --root . examples/linear-equations.typ output/pdf/linear-equations.pdf
```

## Authoring reference

Use ordinary Typst content blocks for text, mathematics, figures, tables, and images. These are the supported template functions and their defaults:

```typst
worksheet(title: [], page-numbers: false,
  text-font: "STIX Two Text", math-font: "STIX Two Math", body)
question(body, parts: (), tasks: (), columns: 1, working: 0, marks: none)
part(body, ref: none, marks: none, parts: ())
task(body, ref: none, marks: none)
answers(body)
answer(body, ref: none, parts: (), tasks: (), columns: 1)
solutions(body)
solution(body, ref: none, parts: (), tasks: (), columns: 1)
```

`body` is the content block in `#question[Write a prompt here.]`. Supply `[]` when a question or entry begins directly with parts. `part` and `task` create entries for a list; they do not render independently.

- **Questions:** Number automatically from `1.`. Put lettered `part` entries in `parts: (...)`; put Roman `task` entries in a part's `parts` option. A question's `tasks` option supplies shared Roman instructions before all its lettered parts.
- **Columns:** Set a positive whole number. Parts fill equal-width columns across each row, with extra parts continuing on further rows. Roman sub-parts remain a single list within their lettered part.
- **Working space:** Set a non-negative whole number of 12 pt lines per question. For questions with parts, the same space follows every row, in addition to the normal 12 pt gap. A row stays with its working space. Without parts, the end of the prompt stays with the complete working space. A space or row too tall to fit on a page causes a compilation error.
- **Marks:** Set a positive whole number for `[1 mark]` or `[3 marks]`. Marks align at the right edge beside the prompt's final line. Marks on lettered or Roman parts require a single-column layout. A question or lettered part needs a written prompt to carry overall marks; otherwise put marks on its Roman tasks. Totals are not calculated.
- **Page breaks:** Use native `#pagebreak()` when you want a new page, including to keep a prompt with its first row of parts.

### Answers, solutions, and omitted entries

Append `#answers[...]` and/or `#solutions[...]` after the questions. Each begins on a new page with its own title and numbering, without a name field or page numbers. Supply the content manually; the template does not generate answers or repeat question text.

Inside each section, use `#answer[...]` or `#solution[...]`. Each section starts at question `1`, and each question resets its lettered and Roman sequences. Choose answer and solution column counts independently of the worksheet.

To omit entries, use `ref` to select the next displayed label. Subsequent implicit entries continue from that reference:

```typst
#answers[
  #answer[Answer to question 1.]
  #answer(ref: 5, parts: (
    part(ref: "b")[Answer to part (b).],
    part[Answer to part (c).],
  ))[]
  #answer[Answer to question 6.]
]
```

Use positive integers for question references, and positive integers or label strings such as `"b"` and `"iii"` for lettered and Roman references. Keep references in answer and solution sections; worksheet questions use automatic numbering.

## Layout

- A4 portrait with 1.5 cm of clear space on every edge, suitable for single- or double-sided printing.
- A bold title at the top left and a name field at the top right, appearing only on the first page. Optional page numbers appear at the top centre of subsequent worksheet pages.
- 12 pt text, titles, and headings. Ordinary text baselines are 12 pt apart; taller mathematics receives the extra height it needs.
- Main labels `1.`, lettered labels `(a)`, and Roman labels `(i)`, with 1 cm indentation steps and 1 cm gutters between columns.
- Level 1 headings centred and bold, level 2 left aligned and bold, and level 3 left aligned and italic.
- Native table borders default to 0.5 pt. Use native Typst layout for figures and graphs; the template does not provide dedicated drawing helpers.

Long equations and other unbreakable content can exceed a narrow column. The compilation script reports detected equation and word overflow, but arbitrary custom widgets may not be detected. Inspect the PDF, particularly diagrams, tables, graphs, and page breaks, before distributing it.

## Development and verification

Run from the repository root:

```sh
python3 tests/verify.py
python3 scripts/compile.py examples/linear-equations.typ examples/linear-equations.pdf
python3 scripts/compile.py examples/numbering-subsets.typ examples/numbering-subsets.pdf
```

Verification covers margins, text spacing, numbering, pagination, final-line marks, working-space protection, and error/caution diagnostics. Visual inspection supplements these checks.

The repository contains the template, compilation script, verification suite, and paired example sources/PDFs. Keep the two published PDFs in sync with their sources when changing the template or examples. Local builds in `output/`, review material in `tmp/`, and other generated PDFs are ignored by Git.

## Licence

This template and its examples are available under the [MIT licence](LICENSE).
