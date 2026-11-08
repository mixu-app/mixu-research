#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Reproduce the spoiler-decision verification tables and decision-rule checks (Run sd-20261108-01).

Uses only the Python standard library. Verifies that:
1. All referenced public-domain corpus IDs exist in corpora/manifest.json and pass US PD checks.
2. The 10-bin reliability diagram recomputes to ECE_10 = 0.031 (<= 0.050 threshold).
3. Each arm's metrics match the pre-registered decision rule in protocol.md.
"""
from __future__ import annotations

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "corpora" / "manifest.json"

REQUIRED_CORPUS_IDS = (
    "poe-rue-morgue",
    "leroux-yellow-room",
    "doyle-study-in-scarlet",
    "christie-styles",
    "christie-ackroyd",
)

# 10-bin reliability diagram counts, mean confidence, and empirical accuracy for Arm C (N = 720)
ARM_C_BINS = (
    (1, 0, 0.000, 0.000),
    (2, 0, 0.000, 0.000),
    (3, 6, 0.265, 0.333),
    (4, 19, 0.358, 0.368),
    (5, 38, 0.454, 0.421),
    (6, 54, 0.552, 0.519),
    (7, 71, 0.651, 0.620),
    (8, 132, 0.753, 0.788),
    (9, 196, 0.854, 0.883),
    (10, 204, 0.946, 0.917),
)

# Held-out test metrics (N = 720)
ARMS = (
    {
        "arm": "Arm A (Rules Floor)",
        "post_slr": 0.000,
        "pre_slr": 0.000,
        "frr": 0.068,
        "f1": 0.742,
        "ece": 0.112,
        "p95_ms": 9,
        "cost_per_1k": 0.00,
    },
    {
        "arm": "Arm B (Rules + qwen2.5-72b-instruct JSON)",
        "post_slr": 0.000,
        "pre_slr": 0.039,
        "frr": 0.024,
        "f1": 0.868,
        "ece": 0.078,
        "p95_ms": 1890,
        "cost_per_1k": 1.42,
    },
    {
        "arm": "Arm C (Rules + jev-decision-1.13 @ tau*=0.72)",
        "post_slr": 0.000,
        "pre_slr": 0.003,
        "frr": 0.031,
        "f1": 0.858,
        "ece": 0.031,
        "p95_ms": 142,
        "cost_per_1k": 0.09,
    },
    {
        "arm": "Arm D (Rules + jev-decision-1.13 + Escalation)",
        "post_slr": 0.000,
        "pre_slr": 0.004,
        "frr": 0.021,
        "f1": 0.889,
        "ece": 0.024,
        "p95_ms": 485,
        "cost_per_1k": 0.34,
    },
)


def evaluate_decision_rule(arm: dict[str, float | str], floor_f1: float) -> str:
    delta_f1 = round(float(arm["f1"]) - floor_f1, 3)
    if str(arm["arm"]).startswith("Arm A"):
        return "BASELINE"
    if delta_f1 < 0.015 or float(arm["pre_slr"]) > 0.020:
        return "REJECT"
    if (
        float(arm["post_slr"]) == 0.000
        and float(arm["pre_slr"]) <= 0.005
        and delta_f1 >= 0.040
        and float(arm["ece"]) <= 0.050
        and float(arm["p95_ms"]) <= 600
        and float(arm["cost_per_1k"]) <= 0.80
    ):
        return "ADOPT"
    return "REVISIT"


def main() -> int:
    manifest = json.loads(MANIFEST.read_text())
    works_by_id = {w["id"]: w for w in manifest["works"]}
    for cid in REQUIRED_CORPUS_IDS:
        if cid not in works_by_id:
            print(f"error: missing corpus id {cid} in manifest.json", file=sys.stderr)
            return 1
        if int(works_by_id[cid]["published"]) > 1930:
            print(f"error: corpus id {cid} is not US public domain", file=sys.stderr)
            return 1

    total_n = sum(count for _, count, _, _ in ARM_C_BINS)
    if total_n != 720:
        print(f"error: expected N=720 held-out test items, got {total_n}", file=sys.stderr)
        return 1

    ece = sum((count / total_n) * abs(acc - conf) for _, count, conf, acc in ARM_C_BINS)
    if round(ece, 3) != 0.031:
        print(f"error: recomputed ECE_10={ece:.4f} does not match reported 0.031", file=sys.stderr)
        return 1

    floor_f1 = float(ARMS[0]["f1"])
    print(f"Run ID: sd-20261108-01 | Corpus schema_version={manifest['schema_version']} as_of={manifest['as_of']}")
    print(f"Recomputed Arm C 10-bin ECE_10 (N={total_n}): {ece:.4f} (reported: 0.031)\n")
    print(f"{'Arm'.ljust(48)} {'PostSLR'} {'PreSLR'} {'MacroF1'} {'dF1'}    {'ECE10'} {'P95ms'} {'Cost/1k'} {'Verdict'}")
    for arm in ARMS:
        df1 = float(arm["f1"]) - floor_f1
        verdict = evaluate_decision_rule(arm, floor_f1)
        print(
            f"{str(arm['arm']).ljust(48)} "
            f"{float(arm['post_slr']):.3f}   "
            f"{float(arm['pre_slr']):.3f}  "
            f"{float(arm['f1']):.3f}   "
            f"{df1:+.3f}  "
            f"{float(arm['ece']):.3f} "
            f"{int(arm['p95_ms']):<5} "
            f"${float(arm['cost_per_1k']):.2f}   "
            f"{verdict}"
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
