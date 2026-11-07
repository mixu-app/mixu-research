#!/usr/bin/env python3
"""Download public-domain texts listed in the manifest.

Writes only to corpora/cache/, which is ignored by Git. Refuses any work that is
not public domain in the US, because the sources are US-based and redistributing
their files elsewhere is the user's problem, not this repository's.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import sys
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
CACHE = ROOT / "corpora" / "cache"
US_LAST_PD_YEAR = 1930


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--list", action="store_true", help="print what would be fetched")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("ids", nargs="*", help="work ids; default all eligible")
    args = ap.parse_args()

    works = json.loads((ROOT / "corpora" / "manifest.json").read_text())["works"]
    wanted = [w for w in works if not args.ids or w["id"] in args.ids]
    CACHE.mkdir(parents=True, exist_ok=True)

    fetched = 0
    for w in wanted:
        gid = int(w.get("gutenberg_id") or 0)
        if not gid:
            print(f"skip {w['id']}: no Gutenberg id (edition not located yet)")
            continue
        if int(w["published"]) > US_LAST_PD_YEAR:
            print(f"refuse {w['id']}: not public domain in the US", file=sys.stderr)
            continue
        url = f"https://www.gutenberg.org/cache/epub/{gid}/pg{gid}.epub"
        target = CACHE / f"{w['id']}.epub"
        print(f"{'would fetch' if (args.list or args.dry_run) else 'fetching'} {w['id']} <- {url}")
        if args.list or args.dry_run:
            continue
        try:
            with urllib.request.urlopen(url, timeout=120) as r:
                blob = r.read()
        except Exception as e:                      # noqa: BLE001 - reported, not swallowed
            print(f"  failed: {e}", file=sys.stderr)
            continue
        target.write_bytes(blob)
        digest = hashlib.sha256(blob).hexdigest()
        print(f"  {len(blob)} bytes sha256={digest[:16]}…")
        fetched += 1

    print(f"\n{fetched} file(s) in {CACHE.relative_to(ROOT)} (ignored by Git)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
