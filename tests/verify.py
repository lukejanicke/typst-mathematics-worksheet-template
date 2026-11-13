#!/usr/bin/env python3
"""Exercise worksheet geometry, numbering, and failure diagnostics."""
from pathlib import Path
import subprocess
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
PREFIX = '#import "../worksheet.typ": *\n#show: worksheet.with(title: [Layout verification], page-numbers: true)\n'


def run(source, name, directory, *, page_numbers=True, check_keys=False):
    fixture_dir = Path(tempfile.mkdtemp(prefix="fixture-", dir=ROOT / "tests"))
    path = fixture_dir / (name + ".typ")
    # Temporary fixtures live inside project so relative template imports work.
    prefix = PREFIX.replace("../worksheet.typ", "../../worksheet.typ")
    if not page_numbers:
        prefix = prefix.replace("page-numbers: true", "page-numbers: false")
    path.write_text(prefix + source)
    try:
        out = Path(directory) / (name + ".pdf")
        options = ["--check-keys"] if check_keys else []
        result = subprocess.run(["python3", str(ROOT / "scripts/compile.py"), *options, str(path), str(out)], capture_output=True, text=True)
        return result, out
    finally:
        path.unlink(missing_ok=True)
        fixture_dir.rmdir()


def words(pdf):
    result = subprocess.run(["pdftotext", "-bbox", str(pdf), "-"], check=True, capture_output=True, text=True)
    root = ET.fromstring(result.stdout)
    ns = {"x": "http://www.w3.org/1999/xhtml"}
    return [[(w.text, {k: float(v) for k, v in w.attrib.items()}) for w in p.findall("x:word", ns)] for p in root.findall(".//x:page", ns)]


def assert_baselines(items, *tokens):
    """Compare text-font probe words, avoiding math-font bounding-box differences."""
    positions = {token: [bounds for text, bounds in items if text == token] for token in tokens}
    assert all(len(matches) == 1 for matches in positions.values()), positions
    baselines = [matches[0]["yMin"] for matches in positions.values()]
    assert max(baselines) - min(baselines) < .1, positions


def verify_tall_baselines(directory):
    result, pdf = run(r'''#question[$frac(1, frac(2, 3))$ TallQuestion]
#pagebreak()
#question(parts: (part([$frac(1, frac(2, 3))$ TallPart]),))[]
#pagebreak()
#question(parts: (part([], parts: (task([$frac(1, frac(2, 3))$ TallRoman], marks: 2),)),))[]
#pagebreak()
#question(parts: (
  part([ShortColumn]),
  part([$frac(1, frac(2, 3))$ TallColumn]),
  part([$frac(2, 3)$ MediumColumn]),
), columns: 3)[]
#pagebreak()
#question(tasks: (task([$frac(1, frac(2, 3))$ SharedTask]),), parts: (part([Item]),))[Prompt]
#pagebreak()
#question(marks: 3)[FirstLine \
$frac(1, frac(2, 3))$ FinalLine]
#solutions[
#solution[$ frac(1, frac(2, 3)) = #text(font: "STIX Two Text", "DisplayProbe") $]
]
''', "tall-baselines", directory)
    assert result.returncode == 0, result.stderr
    pages = words(pdf)
    assert len(pages) == 7, len(pages)
    assert_baselines(pages[0], "1.", "TallQuestion")
    assert_baselines(pages[1], "2.", "(a)", "TallPart")
    assert_baselines(pages[2], "3.", "(a)", "(i)", "TallRoman", "marks]")
    assert_baselines(pages[3], "4.", "(a)", "(b)", "(c)", "ShortColumn", "TallColumn", "MediumColumn")
    assert_baselines(pages[4], "(i)", "SharedTask")
    assert_baselines(pages[5], "6.", "FirstLine")
    assert_baselines(pages[5], "FinalLine", "marks]")
    assert_baselines(pages[6], "1.", "DisplayProbe")

    # Baseline alignment must retain tall mathematics' extra height and the
    # specified three working lines plus normal row gap.
    result, pdf = run(r'''#question(parts: (
  part([$frac(71, frac(82, 93))$ TallRow]),
  part([FollowingRow]),
), working: 3)[]
''', "tall-row-space", directory)
    assert result.returncode == 0, result.stderr
    items = words(pdf)[0]
    tall = next(b for t, b in items if t == "TallRow")
    following = next(b for t, b in items if t == "FollowingRow")
    assert following["yMin"] - tall["yMin"] > 60, (tall, following)

    result, pdf = run(r'''#v(22cm)
#question(parts: (part([KeptShort]), part([$frac(1, frac(2, 3))$ KeptTall])), columns: 2, working: 12)[]
''', "tall-row-keep", directory)
    assert result.returncode == 0, result.stderr
    pages = words(pdf)
    locations = {t: i for i, page in enumerate(pages) for t, _ in page if t in ("KeptShort", "KeptTall")}
    assert locations == {"KeptShort": 1, "KeptTall": 1}, locations
    assert_baselines(pages[1], "1.", "(a)", "(b)", "KeptShort", "KeptTall")
    content_bottom = max(b["yMax"] for t, b in pages[1] if t != "2")
    assert content_bottom + 144 <= 28.2 * 72 / 2.54 + .1, content_bottom

    # The same working-space request fits with one ordinary line, but not
    # after adding a tall fraction. Height checks must include the expansion.
    result, _ = run('#question(parts: (part([Ordinary]),), working: 60)[]', "maximum-ordinary-row", directory)
    assert result.returncode == 0, result.stderr
    result, _ = run(r'#question(parts: (part([$frac(1, frac(2, 3))$ Tall]),), working: 60)[]', "oversized-tall-row", directory)
    assert result.returncode != 0 and "exceed a page" in result.stderr, result.stderr


def verify_working_overrides(directory):
    def compile_words(source, name):
        result, pdf = run(source, name, directory)
        assert result.returncode == 0, result.stderr
        return words(pdf)

    def assert_steps(items, tokens, distances):
        bounds = [next(b for t, b in items if t == token) for token in tokens]
        for before, after, distance in zip(bounds, bounds[1:], distances):
            assert abs(after["yMin"] - before["yMin"] - distance) < .1, (before, after, distance)

    # Omitted and explicit none both inherit; zero replaces rather than falls
    # back to the default. Every working allowance is separate from the gap.
    pages = compile_words('''#question(working: 3, parts: (
  part[Inherited], part(working: none)[ExplicitNone],
  part(working: 1)[Smaller], part(working: 5)[Larger],
  part(working: 0)[Zero], part[AfterZero],
))[]''', "lettered-overrides")
    assert_steps(pages[0], ["Inherited", "ExplicitNone", "Smaller", "Larger", "Zero", "AfterZero"], [60, 60, 36, 84, 24])

    pages = compile_words('''#question(working: 3, parts: (
  part(working: 2, parts: (
    task[Inherited], task(working: none)[ExplicitNone],
    task(working: 1)[Smaller], task(working: 5)[Larger],
    task(working: 0)[Zero], task[FinalChild],
  ))[ParentPrompt],
  part(working: 0)[FollowingPart],
))[]''', "roman-overrides")
    assert_steps(pages[0], ["ParentPrompt", "Inherited", "ExplicitNone", "Smaller", "Larger", "Zero", "FinalChild", "FollowingPart"], [24, 48, 48, 36, 84, 24, 48])

    # No parent prompt or trailing parent allowance. A child can increase a
    # zero parent, and the final child still owns its complete working area.
    pages = compile_words('''#question(working: 100, parts: (
  part(working: 0, parts: (
    task(working: 3, marks: 2)[PositiveChild],
    task[InheritedZero], task(working: 2, marks: 1)[FinalChild],
  ))[],
  part(working: 0)[FollowingPart],
))[]''', "zero-parent")
    assert_baselines(pages[0], "1.", "(a)", "(i)", "PositiveChild", "marks]")
    assert_baselines(pages[0], "FinalChild", "mark]")
    assert_steps(pages[0], ["PositiveChild", "InheritedZero", "FinalChild", "FollowingPart"], [60, 24, 48])

    # Resolved question defaults reach Roman items through a none parent.
    # This is the intentional change from one allowance below the whole list.
    pages = compile_words('''#question(working: 3, parts: (
  part(working: none, parts: (task[FirstChild], task(working: none)[LastChild]))[],
  part(working: 0)[FollowingPart],
))[]''', "roman-question-default")
    assert_steps(pages[0], ["FirstChild", "LastChild", "FollowingPart"], [60, 60])

    # A tall zero-space figure determines the row, rather than the tallest
    # content PLUS a neighbouring cell's largest allowance (which gives 120).
    pages = compile_words('''#question(columns: 2, working: 3, parts: (
  part(working: 0)[#block(height: 72pt)[FigureProbe]],
  part[ShortAlgebra], part(working: 0)[FollowingRow],
))[]''', "complete-cell-height")
    assert_baselines(pages[0], "1.", "(a)", "(b)", "FigureProbe", "ShortAlgebra")
    assert_steps(pages[0], ["FigureProbe", "FollowingRow"], [84])

    pages = compile_words('''#question(columns: 3, working: 100, parts: (
  part(working: 1, parts: (task[NestedFirst], task[NestedLast]))[],
  part(working: 5)[Unnested], part(working: 0)[ZeroPeer],
  part(working: 0)[IncompleteFinal],
))[]
#question[AfterFinal]''', "mixed-incomplete-rows")
    assert_baselines(pages[0], "1.", "(a)", "(b)", "(c)", "(i)", "NestedFirst", "Unnested", "ZeroPeer")
    assert_steps(pages[0], ["NestedFirst", "IncompleteFinal", "AfterFinal"], [84, 24])
    assert_steps(pages[0], ["NestedFirst", "NestedLast"], [36])
    assert "(d)" in [t for t, _ in pages[0]]

    pages = compile_words('''#question(columns: 2, working: 100, parts: (
  part(working: 0)[FirstZero], part(working: 0)[ZeroPeer],
  part(working: 0)[FinalZero],
))[]
#question[AfterZero]''', "all-zero-rows")
    assert_steps(pages[0], ["FirstZero", "FinalZero", "AfterZero"], [24, 24])

    pages = compile_words(r'''#question(columns: 2, working: 2, parts: (
  part(parts: (task(working: 0)[$frac(1, frac(2, 3))$ TallRoman], task[NextRoman]))[],
  part(working: 0)[ShortPeer],
))[]''', "tall-roman-overrides")
    assert_baselines(pages[0], "1.", "(a)", "(b)", "(i)", "TallRoman", "ShortPeer")
    tall = next(b for t, b in pages[0] if t == "TallRoman")
    following = next(b for t, b in pages[0] if t == "NextRoman")
    assert following["yMin"] - tall["yMin"] > 24, (tall, following)

    for numbered in (True, False):
        result, pdf = run('''#v(23cm)
#question(columns: 2, working: 3, parts: (
  part(parts: (task[KeptFirst], task(working: 5)[KeptLast]))[],
  part(working: 0)[KeptPeer],
))[]''', "nested-keep", directory, page_numbers=numbered)
        assert result.returncode == 0, result.stderr
        pages = words(pdf)
        locations = {t: i for i, page in enumerate(pages) for t, _ in page if t in ("KeptFirst", "KeptLast", "KeptPeer")}
        assert locations == {"KeptFirst": 1, "KeptLast": 1, "KeptPeer": 1}, locations
        final = next(b for t, b in pages[1] if t == "KeptLast")
        assert final["yMax"] + 60 <= 28.2 * 72 / 2.54 + .1, final
        assert_baselines(pages[1], "1.", "(a)", "(b)", "(i)", "KeptFirst", "KeptPeer")

    for name, source in {
        "oversized-lettered-override": '#question(parts: (part(working: 100)[TooTall],))[]',
        "oversized-roman-override": '#question(parts: (part(parts: (task(working: 100)[TooTall],))[],))[]',
        "oversized-accumulated-roman": '#question(working: 30, parts: (part(parts: (task[One], task[Two], task[Three]))[],))[]',
    }.items():
        result, _ = run(source, name, directory)
        assert result.returncode != 0 and "a part row and its working space exceed a page" in result.stderr, result.stderr

    # An unused default must not participate in either measurement or failure.
    for source in (
        '#question(working: 100, parts: (part(working: 0)[Fits],))[]',
        '#question(parts: (part(working: 100, parts: (task(working: 0)[Fits],))[],))[]',
    ):
        pages = compile_words(source, "reduced-space-fits")
        assert len(pages) == 1

    # Continuation numbering reserves 24 pt even when the row starts on page 1.
    source = '#question(parts: (part(working: 61)[NearLimit],))[]'
    result, _ = run(source, "numbered-limit", directory)
    assert result.returncode != 0 and "exceed a page" in result.stderr, result.stderr
    result, _ = run(source, "unnumbered-limit", directory, page_numbers=False)
    assert result.returncode == 0, result.stderr

    for constructor in ("part", "task"):
        for invalid in ("-1", "1.5", "true", '"3"', "12pt"):
            item = f'{constructor}(working: {invalid})[Invalid]'
            if constructor == "task":
                item = f'part(parts: ({item},))[]'
            result, _ = run(f'#question(parts: ({item},))[]', "invalid-override", directory)
            assert result.returncode != 0 and "Part working space must be none or a non-negative whole number" in result.stderr, result.stderr

    # Supplying even zero must fail at non-question rendering sites, rather
    # than being silently ignored. Explicit none remains backwards compatible.
    for section, entry in (("answers", "answer"), ("solutions", "solution")):
        for value in (0, 3):
            for item in (f'part(working: {value})[Invalid]', f'part(parts: (task(working: {value})[Invalid],))[]'):
                result, _ = run(f'#{section}[#{entry}(parts: ({item},))[]]', "section-override", directory)
                assert result.returncode != 0 and f"not supported in {section}" in result.stderr, result.stderr
    for value in (0, 3):
        result, _ = run(f'#question(tasks: (task(working: {value})[Invalid],), parts: (part[Item],))[Prompt]', "shared-override", directory)
        assert result.returncode != 0 and "not supported in shared instructions" in result.stderr, result.stderr

    source = '''#question(working: 3, tasks: (task[SharedFirst], task[SharedLast]), parts: (part[Item],))[Prompt]
#answers[#answer(parts: (part(parts: (task[AnswerFirst], task[AnswerLast]))[], part[AnswerNext]))[]]
#solutions[#solution(parts: (part(parts: (task[SolutionFirst], task[SolutionLast]))[], part[SolutionNext]))[]]'''
    pages = compile_words(source, "boundary-defaults")
    explicit_none = source.replace("task[", "task(working: none)[").replace("part[", "part(working: none)[").replace("part(parts:", "part(working: none, parts:")
    assert compile_words(explicit_none, "boundary-none") == pages
    assert_steps(pages[0], ["SharedFirst", "SharedLast", "Item"], [24, 24])
    assert_steps(pages[1], ["AnswerFirst", "AnswerLast", "AnswerNext"], [24, 24])
    assert_steps(pages[2], ["SolutionFirst", "SolutionLast", "SolutionNext"], [24, 24])


def verify_question_numbers_and_keys(directory):
    result, pdf = run('''#question(tasks: (task[$frac(1, frac(2, 3))$ First], task[Second]),
      parts: (part[Item],))[]
#question[Next]''', "shared-first", directory)
    assert result.returncode == 0, result.stderr
    items = words(pdf)[0]
    assert_baselines(items, "1.", "(i)", "First")
    assert_baselines(items, "2.", "Next")
    for index, token in enumerate(("1.", "(i)")):
        x = next(b["xMin"] for t, b in items if t == token)
        assert abs(x - (1.5 + index) * 72 / 2.54) < .1
    for args in ('parts: (part(ref: "d")[Bad],)',
                 'parts: (part(parts: (task(ref: "iii")[Bad],))[],)',
                 'tasks: (task(ref: "iii")[Bad],)'):
        result, _ = run(f"#question({args})[Prompt]", "automatic-references", directory)
        assert result.returncode != 0 and "numbered automatically" in result.stderr, result.stderr

    questions = "#question[First]\n#question[Second]\n#question[Third]\n"
    for section, entry in (("answers", "answer"), ("solutions", "solution")):
        for keys, error in (("ref: 99", "does not exist"), ("ref: 1", "Duplicate entry")):
            source = questions + f"#{section}[#{entry}[First]\n#{entry}({keys})[Other]]"
            result, _ = run(source, "checked-keys", directory, check_keys=True)
            assert result.returncode != 0 and error in result.stderr and section in result.stderr, result.stderr
            result, _ = run(source, "unchecked-keys", directory)
            assert result.returncode == 0, result.stderr
    result, _ = run(questions + "#answers[#answer(ref: 2)[Two] #answer[Three]]"
                    "\n#solutions[#solution(ref: 2)[Two]]", "partial-keys", directory, check_keys=True)
    assert result.returncode == 0, result.stderr


def verify_column_cautions(directory):
    atomic = '$upright("ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLM")$'
    for cell, label in ((f"part[{atomic}]", "1(a)"),
                        (f"part(parts: (task[{atomic}],))[]", "1(a)(i)")):
        result, _ = run(f"#question(columns: 2, parts: ({cell}, part[Peer]))[]", "wide-math", directory)
        assert result.returncode == 0 and f"caution: {label}: Unbreakable" in result.stderr, result.stderr
    # About 183 pt fits the 198 pt lettered column, but exceeds its 170 pt Roman inset.
    narrow = '$upright("MMMMMMMMMMMMMMMMM")$'
    source = f"#question(columns: 2, parts: (part[{narrow}], part(parts: (task[{narrow}],))[]))[]"
    result, _ = run(source, "extra-roman-inset", directory)
    assert result.returncode == 0 and result.stderr.count("caution:") == 1 and "1(b)(i)" in result.stderr, result.stderr
    # This equation breaks at its operators and all its lines fit.
    result, _ = run("#question(columns: 3, parts: (part[$123456789x + 123456789x + "
                    "123456789x = 123456789$], part[Peer]))[]", "wrapped-math", directory)
    assert result.returncode == 0 and "caution:" not in result.stderr, result.stderr


def verify_final_figure(directory):
    body = "[Draw this.\n\n#block(height: 3cm, stroke: 0.5pt)[Figure]#metadata(1)]"
    for numbered in (True, False):
        result, _ = run("#question[First]\n#question(working: 58)" + body, "oversized-figure",
                        directory, page_numbers=numbered)
        assert result.returncode != 0 and "Question 2:" in result.stderr and "exceed a page" in result.stderr, result.stderr
        # The earlier paragraphs can stay behind. The figure and 600 pt of space must fit together.
        result, pdf = run("#question(working: 50)[Start " + "A line of ordinary words. " * 100
                          + "\n\n#block(height: 3cm)[Figure]]\n#question[Following]",
                          "final-figure", directory, page_numbers=numbered)
        assert result.returncode == 0, result.stderr
        pages = words(pdf)
        assert any(t == "Start" for t, _ in pages[0])
        fig_page, fig = next((i, b) for i, page in enumerate(pages) for t, b in page if t == "Figure")
        following = next(b for t, b in pages[fig_page] if t == "Following")
        assert fig_page > 0 and abs(following["yMin"] - fig["yMin"] - 3 * 72 / 2.54 - 612) < .2
    tall = "#question(working: 60)[$frac(1, frac(2, 3))$ Tall]"
    result, _ = run(tall, "tall-final-numbered", directory)
    assert result.returncode != 0 and "Question 1:" in result.stderr, result.stderr
    result, _ = run(tall, "tall-final-unnumbered", directory, page_numbers=False)
    assert result.returncode == 0, result.stderr
    result, pdf = run("#question(working: 5)[#table(columns: 1, ..range(100).map(i => [Row #i]))]"
                      "\n#question[Following]", "flowing-final-table", directory)
    assert result.returncode == 0, result.stderr
    pages = words(pdf)
    assert len(pages) > 1
    final = next(b for t, b in pages[-1] if t == "99")
    following = next(b for t, b in pages[-1] if t == "Following")
    assert following["yMin"] - final["yMax"] >= 60


def verify_grid_example(directory):
    pdf = Path(directory) / "accessible-grid.pdf"
    subprocess.run(["typst", "compile", "--root", str(ROOT), "--pdf-standard", "ua-1",
                    "--input", "worksheet-check-keys=true", str(ROOT / "examples/Subsets Example.typ"), str(pdf)], check=True)
    pages = words(pdf)
    assert len(pages) == 3 and [p[0][0] for p in pages[1:]] == ["Answers", "Solutions"]
    items = pages[0]
    assert_baselines(items, "2.", "3.")
    positions = [next(b["xMin"] for t, b in items if t == token) for token in ("2.", "3.")]
    assert abs(positions[1] - positions[0] - 9.5 * 72 / 2.54) < .1, positions
    assert {t for t, _ in items}.issuperset({"1.", "2.", "3.", "4.", "5.", "6."})
    structure = subprocess.run(["pdfinfo", "-struct-text", str(pdf)], check=True, capture_output=True, text=True).stdout
    probes = ('Formula ["x plus one equals three"]', "THead", '"Input"', '"Output"', 'Figure ["The line joins (0, 0)')
    offsets = [structure.index(probe) for probe in probes]
    assert offsets == sorted(offsets) and structure.count("/Scope /Column") == 2
    assert structure.index('P (block)', offsets[-1]) < structure.index('"The line joins', offsets[-1] + len(probes[-1]))


def main():
    with tempfile.TemporaryDirectory(prefix="worksheet-check-") as directory:
        result, pdf = run('''#question[BaselineAlpha \\
BaselineBeta \\
BaselineGamma]
#answers[
#answer[First]
#answer(ref: 5, parts: (part([D], ref: "d"), part([E])) )[]
#answer[Sixth]
]
#solutions[
#solution(parts: (part([A], parts: (task([One]), task([Two]))), part([B], parts: (task([Reset]),))))[]
]
''', "geometry", directory)
        assert result.returncode == 0, result.stderr
        pages = words(pdf)
        all_words = [w for page in pages for w in page]
        positions = {t: b for t, b in all_words if t in ("BaselineAlpha", "BaselineBeta", "BaselineGamma")}
        assert len(positions) == 3, positions
        assert abs(positions["BaselineBeta"]["yMin"] - positions["BaselineAlpha"]["yMin"] - 12) < .02
        assert abs(positions["BaselineGamma"]["yMin"] - positions["BaselineBeta"]["yMin"] - 12) < .02
        cm = 72 / 2.54
        assert abs(positions["BaselineAlpha"]["xMin"] - 2.5 * cm) < .1
        answer_text = [t for t, _ in pages[1]]
        assert "1." in answer_text and "5." in answer_text and "6." in answer_text, answer_text
        assert "(d)" in answer_text and "(e)" in answer_text, answer_text
        solution_text = [t for t, _ in pages[2]]
        assert solution_text.count("(i)") == 2 and "(ii)" in solution_text, solution_text
        assert "1." in solution_text and "Name:" not in solution_text
        for page in pages:
            for text, bounds in page:
                assert bounds["xMin"] >= 1.5 * cm - .1, (text, bounds)
                assert bounds["xMax"] <= 19.5 * cm + .1, (text, bounds)
                assert bounds["yMin"] >= 1.5 * cm - .1, (text, bounds)
                assert bounds["yMax"] <= 28.2 * cm + .1, (text, bounds)
        verify_tall_baselines(directory)
        verify_working_overrides(directory)
        result, _ = run('#question(parts: (part([$x+1=2$]),), working: 100)[]', "oversized", directory)
        assert result.returncode != 0 and "exceed a page" in result.stderr, result.stderr
        verify_question_numbers_and_keys(directory)
        verify_column_cautions(directory)
        verify_final_figure(directory)
        verify_grid_example(directory)
        result, _ = run('#question(parts: (part([Short normal words form a long paragraph which should wrap into its allocated column without an overflow caution.]), part([Second normal paragraph for wrapping.])), columns: 2)[]', "wrap", directory)
        assert result.returncode == 0 and "caution:" not in result.stderr, result.stderr
        result, pdf = run('#question(marks: 3)[First paragraph.\n\n' + 'A long final paragraph with ordinary words to force wrapping. ' * 12 + 'FinalToken]', "marks", directory)
        assert result.returncode == 0, result.stderr
        marked_words = [w for page in words(pdf) for w in page]
        final = next(b for t, b in marked_words if t == "FinalToken")
        mark = next(b for t, b in marked_words if t == "marks]")
        assert abs(final["yMin"] - mark["yMin"]) < .1, (final, mark)
        assert abs(mark["xMax"] - 19.5 * cm) < .1, mark
        result, pdf = run('#question[' + ('Paragraph content which fills multiple lines without unbreakable expressions. ' * 450) + 'ParagraphEnd]', "paragraph-flow", directory)
        assert result.returncode == 0, result.stderr
        flow = words(pdf)
        assert len(flow) > 1
        assert "ParagraphEnd" in [t for t, _ in flow[-1]]
        header = next(b for t, b in flow[1] if t == "2")
        assert abs((header["xMin"] + header["xMax"]) / 2 - 10.5 * cm) < .1
        content = [b for t, b in flow[1] if t != "2"]
        assert min(b["yMin"] for b in content) >= 1.5 * cm + 24 - .1
        result, pdf = run('= HeadingOne\n#question(parts: (part([FirstPart]), part([SecondPart])), columns: 2)[]', "promptless", directory)
        assert result.returncode == 0, result.stderr
        items = words(pdf)[0]
        label = next(b for t, b in items if t == "1.")
        first = next(b for t, b in items if t == "FirstPart")
        heading = next(b for t, b in items if t == "HeadingOne")
        assert abs(label["yMin"] - first["yMin"]) < .1, (label, first)
        assert abs(heading["yMax"] - heading["yMin"] - 12) < .1, heading
        assert abs((heading["xMin"] + heading["xMax"]) / 2 - 10.5 * cm) < .1, heading
        result, pdf = run('#question(parts: (part([RowAlpha]), part([RowBeta])), working: 3)[]', "row-space", directory)
        assert result.returncode == 0, result.stderr
        items = words(pdf)[0]
        a = next(b for t, b in items if t == "RowAlpha")
        b = next(b for t, b in items if t == "RowBeta")
        assert abs(b["yMin"] - a["yMin"] - 60) < .1, (a, b)
        result, pdf = run('#question(parts: (part([], parts: (task([FirstTask], marks: 2), task([LastTask], marks: 1))), part([ParentPrompt], marks: 3, parts: (task([UnmarkedTask]),))))[]', "nested-marks", directory)
        assert result.returncode == 0, result.stderr
        items = words(pdf)[0]
        last = next(b for t, b in items if t == "LastTask")
        mark = next(b for t, b in items if t == "mark]")
        assert abs(mark["yMin"] - last["yMin"]) < .1, (mark, last)
        for token in ("FirstTask", "ParentPrompt"):
            prompt = next(b for t, b in items if t == token)
            assert any(t == "marks]" and abs(b["yMin"] - prompt["yMin"]) < .1 and abs(b["xMax"] - 19.5 * cm) < .1 for t, b in items), (token, items)
        result, pdf = run('#v(22cm)\n#question(parts: (part([KeptFirst]), part([KeptSecond])), columns: 2, working: 12)[]', "row-keep", directory)
        assert result.returncode == 0, result.stderr
        kept_pages = words(pdf)
        locations = {t: i for i, page in enumerate(kept_pages) for t, _ in page if t in ("KeptFirst", "KeptSecond")}
        assert locations == {"KeptFirst": 1, "KeptSecond": 1}, locations
        # The prompt alone fits here, but its four working lines do not.
        # Test both a following question and an explicit page/section boundary.
        for ending in ('#question[NextPrompt]', '#pagebreak()\nNextPage', '#answers[#answer[AnswerText]]', ''):
            result, pdf = run('#v(24cm)\n#question(working: 4, marks: 3)[KeptPrompt]\n' + ending, "standalone-keep", directory)
            assert result.returncode == 0, result.stderr
            kept_pages = words(pdf)
            assert not any(t == "KeptPrompt" for t, _ in kept_pages[0])
            prompt = next(b for t, b in kept_pages[1] if t == "KeptPrompt")
            mark = next(b for t, b in kept_pages[1] if t == "marks]")
            assert prompt["yMax"] + 48 <= 28.2 * cm + .1, prompt
            assert abs(mark["yMin"] - prompt["yMin"]) < .1, (mark, prompt)
            if "NextPrompt" in ending:
                following = next(b for t, b in kept_pages[1] if t == "NextPrompt")
                assert abs(following["yMin"] - prompt["yMax"] - 60) < .1, (prompt, following)
        result, pdf = run('#v(22cm)\n#question(working: 4)[FitsHere]\n#question(working: 4)[MovesNext]', "independent-working", directory)
        assert result.returncode == 0, result.stderr
        independent = words(pdf)
        assert any(t == "FitsHere" for t, _ in independent[0])
        assert any(t == "MovesNext" for t, _ in independent[1])
        result, pdf = run('#question(working: 4, marks: 3)[LongStart ' + ('A long prompt may continue across pages with ordinary paragraph wrapping. ' * 450) + ' LongEnd]\n#question[AfterLong]', "long-working", directory)
        assert result.returncode == 0, result.stderr
        flow = words(pdf)
        assert any(t == "LongStart" for t, _ in flow[0])
        end_page, end = next((i, b) for i, page in enumerate(flow) for t, b in page if t == "LongEnd")
        assert end_page > 0
        assert end["yMax"] + 48 <= 28.2 * cm + .1, end
        mark = next(b for t, b in flow[end_page] if t == "marks]")
        assert abs(mark["yMin"] - end["yMin"]) < .1, (mark, end)
        result, _ = run('#question(working: 100)[Too much working space.]', "oversized-standalone", directory)
        assert result.returncode != 0 and "exceed a page" in result.stderr, result.stderr
        result, _ = run('#question(parts: (part([Test], marks: 1), part([Test])), columns: 2)[]', "invalid-marks", directory)
        assert result.returncode != 0 and "Marks are not supported" in result.stderr, result.stderr
        result, _ = run('#question(parts: (part([], parts: (task([Test], marks: 1),)), part([Test])), columns: 2)[]', "invalid-roman-marks", directory)
        assert result.returncode != 0 and "Marks are not supported" in result.stderr, result.stderr
        result, _ = run('#question(parts: (part([], marks: 3, parts: (task([Test]),)),))[]', "missing-part-prompt", directory)
        assert result.returncode != 0 and "Part-level marks require a written prompt" in result.stderr, result.stderr
    print("Passed worksheet geometry, pagination, working space, numbering and marks; "
          "nested overflow, optional key validation, whole-question grids and tagged PDF structure.")


if __name__ == "__main__":
    main()
