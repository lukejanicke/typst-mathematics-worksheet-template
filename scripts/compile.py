#!/usr/bin/env python3
"""Compile a worksheet and report its template-generated layout cautions."""
import argparse
import json
from pathlib import Path
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path.cwd(), help="Typst project root (default: current directory)")
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path, nargs="?")
    args = parser.parse_args()
    source = args.source.resolve()
    root = str(args.root.resolve())
    output = (args.output or args.source.with_suffix(".pdf")).resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    result = subprocess.run(["typst", "compile", "--root", root, str(source), str(output)])
    if result.returncode:
        return result.returncode
    result = subprocess.run(
        ["typst", "eval", "query(<worksheet-caution>).map(it => it.value)",
         "--in", str(source), "--root", root], capture_output=True, text=True)
    if result.returncode:
        sys.stderr.write(result.stderr)
        return result.returncode
    try:
        cautions = json.loads(result.stdout)
    except json.JSONDecodeError:
        print("error: could not decode worksheet layout cautions", file=sys.stderr)
        return 1
    seen = set()
    for caution in cautions:
        key = json.dumps(caution, sort_keys=True)
        message = caution["message"]
        if "label" in caution:
            message = f"{caution['label']}: {message}"
        if "width-pt" in caution and "available-pt" in caution:
            message += f" ({caution['width-pt']:.1f} pt > {caution['available-pt']:.1f} pt)"
        if key not in seen:
            print(f"caution: {message}", file=sys.stderr)
            seen.add(key)
    print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
