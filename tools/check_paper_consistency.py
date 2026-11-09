#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Verify LaTeX manuscript structural integrity and cross-artifact metric consistency."""

from __future__ import annotations

import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
PAPER_DIR = ROOT / "papers" / "ours" / "progress-aware-narrative-kg"
PAPER_MD = PAPER_DIR / "paper.md"
LATEX_DIR = PAPER_DIR / "latex"
MAIN_TEX = LATEX_DIR / "main.tex"
BIB_FILE = LATEX_DIR / "references.bib"
SPOILER_RESULTS = ROOT / "experiments" / "spoiler-decisions" / "results.md"
EXTRACTION_RESULTS = ROOT / "experiments" / "extraction-model-pool" / "results.md"

SPOILER_METRICS = ("0.000", "0.858", "0.889", "0.742", "0.031", "0.024")
EXTRACTION_METRICS = ("0.812", "0.833", "0.618")
ALL_KEY_METRICS = SPOILER_METRICS + EXTRACTION_METRICS

REQUIRED_BIB_KEYS = (
    "boyd2023spoiler",
    "jev2025threshold",
    "chen2025cdecidebench",
    "liu2024lost",
    "w3c2013provo",
    "iso5392_2024",
)


def strip_tex_comments(text: str) -> str:
    """Remove unescaped LaTeX line comments."""
    out_lines: list[str] = []
    for line in text.splitlines():
        cleaned = re.sub(r"(?<!\\)%.*$", "", line)
        out_lines.append(cleaned)
    return "\n".join(out_lines)


def check_balanced_braces_and_envs(path: pathlib.Path, problems: list[str]) -> str:
    """Check that unescaped braces and \\begin/\\end environments are balanced."""
    raw = path.read_text(encoding="utf-8")
    text = strip_tex_comments(raw)

    depth = 0
    for idx, ch in enumerate(text):
        prev = text[idx - 1] if idx > 0 else ""
        if prev == "\\":
            continue
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth < 0:
                problems.append(
                    f"{path.relative_to(ROOT)}: unmatched closing brace '}}'"
                )
                break
    if depth != 0:
        problems.append(
            f"{path.relative_to(ROOT)}: unbalanced braces (net depth {depth})"
        )

    env_stack: list[str] = []
    for match in re.finditer(r"\\(begin|end)\{([^}]+)\}", text):
        kind, env_name = match.group(1), match.group(2)
        if kind == "begin":
            env_stack.append(env_name)
        else:
            if not env_stack or env_stack[-1] != env_name:
                expected = env_stack[-1] if env_stack else "<none>"
                problems.append(
                    f"{path.relative_to(ROOT)}: \\end{{{env_name}}} does not match \\begin{{{expected}}}"
                )
                break
            env_stack.pop()
    if env_stack:
        problems.append(
            f"{path.relative_to(ROOT)}: unclosed environments: {', '.join(env_stack)}"
        )

    return text


def main() -> int:
    problems: list[str] = []

    for required_path in (
        PAPER_MD,
        MAIN_TEX,
        BIB_FILE,
        SPOILER_RESULTS,
        EXTRACTION_RESULTS,
    ):
        if not required_path.is_file():
            problems.append(f"missing required file: {required_path.relative_to(ROOT)}")

    if problems:
        for p in problems:
            print(f"error: {p}", file=sys.stderr)
        return 1

    main_tex_clean = check_balanced_braces_and_envs(MAIN_TEX, problems)
    bib_clean = check_balanced_braces_and_envs(BIB_FILE, problems)

    # Resolve all \input{...} files referenced by main.tex
    input_targets = re.findall(r"\\input\{([^}]+)\}", main_tex_clean)
    if not input_targets:
        problems.append("main.tex: no \\input{...} table inclusions found")

    combined_latex_parts = [main_tex_clean]
    for rel_target in input_targets:
        target_path = LATEX_DIR / rel_target
        if target_path.suffix != ".tex":
            target_path = target_path.with_suffix(".tex")
        if not target_path.is_file():
            problems.append(
                f"main.tex references missing input file: {target_path.relative_to(ROOT)}"
            )
            continue
        combined_latex_parts.append(
            check_balanced_braces_and_envs(target_path, problems)
        )

    combined_latex = "\n".join(combined_latex_parts)
    paper_md_text = PAPER_MD.read_text(encoding="utf-8")
    spoiler_text = SPOILER_RESULTS.read_text(encoding="utf-8")
    extraction_text = EXTRACTION_RESULTS.read_text(encoding="utf-8")

    # Verify required bibliography keys exist and are cited
    for key in REQUIRED_BIB_KEYS:
        if key not in bib_clean:
            problems.append(f"references.bib: missing required entry '{key}'")
        if key not in combined_latex:
            problems.append(
                f"main.tex: required bibliography entry '{key}' is never cited"
            )

    # Verify key empirical metrics across paper.md, LaTeX source+tables, and experiment reports
    for metric in ALL_KEY_METRICS:
        if metric not in paper_md_text:
            problems.append(f"paper.md: missing key metric '{metric}'")
        if metric not in combined_latex:
            problems.append(f"latex manuscript/tables: missing key metric '{metric}'")

    for metric in SPOILER_METRICS:
        if metric not in spoiler_text:
            problems.append(
                f"experiments/spoiler-decisions/results.md: missing metric '{metric}'"
            )

    for metric in EXTRACTION_METRICS:
        if metric not in extraction_text:
            problems.append(
                f"experiments/extraction-model-pool/results.md: missing metric '{metric}'"
            )

    # Ensure no binary .pdf artifacts are tracked or left inside latex/
    for pdf_file in LATEX_DIR.rglob("*.pdf"):
        problems.append(
            f"unexpected PDF artifact in source tree: {pdf_file.relative_to(ROOT)}"
        )

    # Optional clean compile check in an isolated temporary directory if pdflatex is installed
    pdflatex_bin = shutil.which("pdflatex")
    bibtex_bin = shutil.which("bibtex")
    compiled_status = "skipped (pdflatex not installed)"
    if pdflatex_bin and not problems:
        with tempfile.TemporaryDirectory(prefix="mixu-latex-check-") as tmpdir:
            tmp_path = pathlib.Path(tmpdir)
            shutil.copytree(LATEX_DIR, tmp_path / "latex")
            work_dir = tmp_path / "latex"
            cmd_pdf = [
                pdflatex_bin,
                "-interaction=nonstopmode",
                "-halt-on-error",
                "main.tex",
            ]
            res1 = subprocess.run(
                cmd_pdf, cwd=work_dir, capture_output=True, text=True, check=False
            )
            if res1.returncode != 0:
                problems.append(f"pdflatex pass 1 failed:\n{res1.stdout[-800:]}")
            elif bibtex_bin:
                res_bib = subprocess.run(
                    [bibtex_bin, "main"],
                    cwd=work_dir,
                    capture_output=True,
                    text=True,
                    check=False,
                )
                if res_bib.returncode != 0:
                    problems.append(f"bibtex failed:\n{res_bib.stdout[-800:]}")
                else:
                    subprocess.run(
                        cmd_pdf,
                        cwd=work_dir,
                        capture_output=True,
                        text=True,
                        check=True,
                    )
                    subprocess.run(
                        cmd_pdf,
                        cwd=work_dir,
                        capture_output=True,
                        text=True,
                        check=True,
                    )
                    compiled_status = (
                        "verified (pdflatex + bibtex clean build in tmpdir)"
                    )
            else:
                compiled_status = "verified (pdflatex pass 1 in tmpdir)"

    if problems:
        print("paper consistency check failed:", file=sys.stderr)
        for p in problems:
            print(f"  - {p}", file=sys.stderr)
        return 1

    print(
        f"ok: paper consistency verified ({len(input_targets)} LaTeX tables, "
        f"{len(ALL_KEY_METRICS)} core metrics matched across paper.md/LaTeX/experiments, "
        f"LaTeX build: {compiled_status})"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
