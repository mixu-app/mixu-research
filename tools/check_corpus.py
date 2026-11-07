#!/usr/bin/env python3
"""Validate the corpus manifest and recompute public-domain status.

The manifest's job is metadata, not text. This gate fails when a claim in the
manifest disagrees with the arithmetic of copyright terms:

  US   works first published in 1930 or earlier are public domain as of 2026
  CN   life + 50, public domain from the year after the 50th anniversary
  EU   life + 70, public domain from the year after the 70th anniversary

Recomputation is the point: a hand-written flag rots, arithmetic does not.
"""
from __future__ import annotations

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "corpora" / "manifest.json"
CURRENT_YEAR = 2026

US_LAST_PD_YEAR = 1930          # 95 years, incremented every 1 January
CN_TERM = 50
EU_TERM = 70

REQUIRED = ("id", "author", "death", "title", "published", "language", "source")


def pd_in_us(published: int) -> bool:
    return published <= US_LAST_PD_YEAR


def pd_from_death(death: int, term: int) -> int:
    """First year the work is public domain in a life+term jurisdiction."""
    return death + term + 1


def main() -> int:
    data = json.loads(MANIFEST.read_text())
    works = data.get("works", [])
    problems: list[str] = []
    seen: set[str] = set()
    rows = []

    for w in works:
        missing = [k for k in REQUIRED if k not in w]
        if missing:
            problems.append(f"{w.get('id','?')}: missing {', '.join(missing)}")
            continue
        if w["id"] in seen:
            problems.append(f"{w['id']}: duplicate id")
        seen.add(w["id"])

        us = pd_in_us(int(w["published"]))
        cn_year = pd_from_death(int(w["death"]), CN_TERM)
        eu_year = pd_from_death(int(w["death"]), EU_TERM)
        cn = CURRENT_YEAR >= cn_year
        eu = CURRENT_YEAR >= eu_year

        gid = int(w.get("gutenberg_id") or 0)
        if gid and not us:
            problems.append(f"{w['id']}: has a Gutenberg id but is not public domain in the US")
        if not w.get("role"):
            problems.append(f"{w['id']}: no role recorded (why is this work in the corpus?)")

        # A hand-written flag, if present, must agree with the arithmetic.
        for field, truth in (("us_pd", us), ("cn_pd", cn), ("eu_pd", eu)):
            if field in w and bool(w[field]) != truth:
                problems.append(f"{w['id']}: {field}={w[field]} contradicts the computed value {truth}")

        rows.append((w["id"], w["published"], "yes" if us else "no",
                     "yes" if cn else f"no (from {cn_year})",
                     "yes" if eu else f"no (from {eu_year})"))

    if problems:
        print("corpus manifest problems:")
        for p in problems:
            print("  " + p)
        return 1

    width = max(len(r[0]) for r in rows) if rows else 10
    print(f"{'work'.ljust(width)}  published  US    CN                 EU")
    for r in rows:
        print(f"{r[0].ljust(width)}  {r[1]:<9}  {r[2]:<4}  {r[3]:<18} {r[4]}")
    print(f"\nok: {len(rows)} works, {sum(1 for r in rows if r[2]=='yes')} public domain in the US as of {CURRENT_YEAR}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
