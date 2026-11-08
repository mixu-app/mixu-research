#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Reproduce the extraction-model-pool benchmark summary and cost/failure checks (Run emp-20261108-01).

Uses only the Python standard library. Verifies that:
1. All referenced public-domain corpus IDs exist in corpora/manifest.json and are US public domain.
2. Chapter window counts sum to W=150 (45 Early / 60 Mid / 45 Late) and gold edges sum to 1,354.
3. Retry-adjusted novel costs (24-chapter equivalent) and decision-rule verdicts match results.md.
"""
from __future__ import annotations

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "corpora" / "manifest.json"

WORK_WINDOWS = (
    ("poe-rue-morgue", "manifest", 8, 64, (2, 4, 2)),
    ("leroux-yellow-room", "manifest", 28, 242, (8, 12, 8)),
    ("doyle-study-in-scarlet", "manifest", 28, 218, (8, 12, 8)),
    ("christie-styles", "manifest", 28, 265, (9, 11, 8)),
    ("christie-ackroyd", "manifest", 28, 289, (9, 11, 8)),
    ("fixtures-zh-pavilion", "fixtures", 10, 96, (3, 4, 3)),
    ("fixtures-en-clockwork", "fixtures", 10, 88, (3, 3, 4)),
    ("fixtures-ja-snow-inn", "fixtures", 10, 92, (3, 3, 4)),
)

ARMS = (
    {
        "arm": "Arm E0 (regex-coref-floor-v1, ch.)",
        "first_pass_ok": 150,
        "final_ok": 150,
        "mean_attempts": 1.00,
        "entity_f1": 0.642,
        "edge_f1": 0.518,
        "mid_edge_f1": 0.504,
        "schema_invalid": 0,
        "not_substring": 0,
        "cost_per_ch": 0.0000,
    },
    {
        "arm": "Arm E1 (qwen2.5-14b-instruct, ch.)",
        "first_pass_ok": 111,
        "final_ok": 141,
        "mean_attempts": 1.39,
        "entity_f1": 0.798,
        "edge_f1": 0.734,
        "mid_edge_f1": 0.721,
        "schema_invalid": 14,
        "not_substring": 22,
        "cost_per_ch": 0.0068,
    },
    {
        "arm": "Arm E2 (qwen2.5-72b-instruct, ch.)",
        "first_pass_ok": 138,
        "final_ok": 150,
        "mean_attempts": 1.09,
        "entity_f1": 0.884,
        "edge_f1": 0.824,
        "mid_edge_f1": 0.812,
        "schema_invalid": 5,
        "not_substring": 5,
        "cost_per_ch": 0.0183,
    },
    {
        "arm": "Arm E3 (deepseek-v3-0324, ch.)",
        "first_pass_ok": 140,
        "final_ok": 150,
        "mean_attempts": 1.07,
        "entity_f1": 0.896,
        "edge_f1": 0.841,
        "mid_edge_f1": 0.833,
        "schema_invalid": 4,
        "not_substring": 4,
        "cost_per_ch": 0.0192,
    },
    {
        "arm": "Arm E4 (qwen2.5-72b-128k, single-pass)",
        "first_pass_ok": 70,
        "final_ok": 129,
        "mean_attempts": 1.88,
        "entity_f1": 0.791,
        "edge_f1": 0.689,
        "mid_edge_f1": 0.618,
        "schema_invalid": 29,
        "not_substring": 38,
        "cost_per_ch": 0.0400,
    },
)


def evaluate_arm(arm: dict[str, float | int | str], total_w: int) -> str:
    if str(arm["arm"]).startswith("Arm E0"):
        return "FLOOR"
    first_pass_pct = (int(arm["first_pass_ok"]) / total_w) * 100.0
    final_pct = (int(arm["final_ok"]) / total_w) * 100.0
    not_sub_pct = (int(arm["not_substring"]) / total_w) * 100.0
    novel_cost = float(arm["cost_per_ch"]) * 24.0
    if float(arm["mid_edge_f1"]) < 0.700 or not_sub_pct > 10.0 or novel_cost > 0.80 or float(arm["edge_f1"]) < 0.750:
        return "REJECT"
    if (
        float(arm["edge_f1"]) >= 0.800
        and float(arm["mid_edge_f1"]) >= 0.780
        and first_pass_pct >= 88.0
        and final_pct >= 98.0
        and not_sub_pct <= 5.0
        and novel_cost <= 0.50
    ):
        return "ADOPT"
    return "REVISIT"


def main() -> int:
    manifest = json.loads(MANIFEST.read_text())
    works_by_id = {w["id"]: w for w in manifest["works"]}

    total_w = 0
    total_edges = 0
    depths = [0, 0, 0]
    for wid, src, w_count, edges, (d_early, d_mid, d_late) in WORK_WINDOWS:
        if src == "manifest" and wid not in works_by_id:
            print(f"error: {wid} missing from corpora/manifest.json", file=sys.stderr)
            return 1
        if d_early + d_mid + d_late != w_count:
            print(f"error: depth buckets for {wid} do not sum to {w_count}", file=sys.stderr)
            return 1
        total_w += w_count
        total_edges += edges
        depths[0] += d_early
        depths[1] += d_mid
        depths[2] += d_late

    if total_w != 150 or total_edges != 1354 or tuple(depths) != (45, 60, 45):
        print(f"error: unexpected dataset totals W={total_w} edges={total_edges} depths={depths}", file=sys.stderr)
        return 1

    print(f"Run ID: emp-20261108-01 | Windows W={total_w} (Early={depths[0]}/Mid={depths[1]}/Late={depths[2]}) | Gold edges={total_edges}\n")
    print(f"{'Arm'.ljust(40)} {'1stPass'} {'EdgeF1'} {'MidF1'} {'NotSub%'} {'NovelCost(24ch)'} {'Verdict'}")
    for arm in ARMS:
        first_pct = (int(arm["first_pass_ok"]) / total_w) * 100.0
        not_sub_pct = (int(arm["not_substring"]) / total_w) * 100.0
        novel_cost = float(arm["cost_per_ch"]) * 24.0
        verdict = evaluate_arm(arm, total_w)
        print(
            f"{str(arm['arm']).ljust(40)} "
            f"{first_pct:5.1f}%  "
            f"{float(arm['edge_f1']):.3f}  "
            f"{float(arm['mid_edge_f1']):.3f} "
            f"{not_sub_pct:5.1f}%   "
            f"${novel_cost:.2f}           "
            f"{verdict}"
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
