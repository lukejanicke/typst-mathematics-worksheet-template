#!/usr/bin/env python3
"""Exercise worksheet geometry, numbering, and failure diagnostics."""
from pathlib import Path
import subprocess
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
PREFIX = '#import "../worksheet.typ": *\n#show: worksheet.with(title: [Layout verification], page-numbers: true)\n'


def run(source, name, directory):
    fixture_dir = Path(tempfile.mkdtemp(prefix="fixture-", dir=ROOT / "tests"))
    path = fixture_dir / (name + ".typ")
    # Temporary fixtures live inside project so relative template imports work.
    path.write_text(PREFIX.replace("../worksheet.typ", "../../worksheet.typ") + source)
    try:
        out = Path(directory) / (name + ".pdf")
        result = subprocess.run(["python3", str(ROOT / "scripts/compile.py"), str(path), str(out)], capture_output=True, text=True)
        return result, out
    finally:
        path.unlink(missing_ok=True)
        fixture_dir.rmdir()


def words(pdf):
    result = subprocess.run(["pdftotext", "-bbox", str(pdf), "-"], check=True, capture_output=True, text=True)
    root = ET.fromstring(result.stdout)
    ns = {"x": "http://www.w3.org/1999/xhtml"}
    return [[(w.text, {k: float(v) for k, v in w.attrib.items()}) for w in p.findall("x:word", ns)] for p in root.findall(".//x:page", ns)]


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
        result, _ = run('#question(parts: (part([$x+1=2$]),), working: 100)[]', "oversized", directory)
        assert result.returncode != 0 and "exceed a page" in result.stderr, result.stderr
        result, _ = run('#question(parts: (part([$123456789x + 123456789x + 123456789x = 123456789$]), part([$x=2$]), part([$x=3$])), columns: 3)[]', "overflow", directory)
        assert result.returncode == 0 and "caution:" in result.stderr, result.stderr
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
    print("Passed: margins, 12 pt baselines/headings, working space, pagination, final-line marks, promptless labels, counter jumps/resets, wrapping and error/caution diagnostics.")


if __name__ == "__main__":
    main()
