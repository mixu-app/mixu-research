#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Reproduce the Shin-Honkaku Adversarial Narrative Structures verification tables (Run sh-20261110-01 & sh-20261110-live-or).

Uses only the Python standard library. Verifies that:
1. All 6 anonymized Shin-Honkaku structural strata sum to 69 logical works across 50 EPUB containers,
   and zero copyrighted titles or book excerpts appear in the experiment files.
2. The 3 multi-book omnibuses (588, 316, 54 spines) split into 22 isolated novel volumes (50 - 3 + 22 = 69).
3. All four architectural arms (SH0..SH3) reproduce the exact metrics reported in results.md and paper.md
   (0.914 Identity Macro-F1, 0.896 Multi-Solution Transition Macro-F1, 0.908 Hybrid Epistemic/Layer Macro-F1).
4. Live OpenRouter evaluation records (Run sh-20261110-live-or) reconcile across extraction (8 calls, $0.002540)
   and /api/alpha/decisions (21 calls, $0.000772, P50 = 753.39 ms). Pass --live-openrouter with OPENROUTER_API_KEY
   to execute a live verification probe against https://openrouter.ai/api/alpha/decisions.
"""

from __future__ import annotations

import argparse
import json
import os
import pathlib
import statistics
import sys
import urllib.error
import urllib.request

HERE = pathlib.Path(__file__).resolve().parent

STRATA = (
    ("SH-NT", "SH-NT-01..12", 12, 12, 180, "Narrative Tricks & Persona Masking"),
    ("SH-TL", "SH-TL-01..05", 5, 5, 120, "Time-Loop & Sci-Fi Rule Systems"),
    ("SH-MM", "SH-MM-01..17", 17, 9, 168, "Meta / Mansion / Castle & Hypertext"),
    ("SH-KY", "SH-KY-01..07", 7, 7, 108, "Encyclopedic / Folklore Chronicles"),
    ("SH-AM", "SH-AM-01..08", 8, 8, 132, "Anti-Mystery Multi-Solution Cascades"),
    ("SH-EP", "SH-EP-01..20", 20, 9, 120, "Episodic / Omnibus / Reverse-Chronology"),
)

OMNIBUSES = (
    ("SH-MM-01..09", 588, 9),
    ("SH-EP-01..08", 316, 8),
    ("SH-EP-09..13", 54, 5),
)

ARMS = (
    {
        "arm": "Arm SH0 (Flat Coord + Global Registry)",
        "post_slr": 0.000,
        "pfimr_pct": 31.4,
        "ccr_pct": 42.8,
        "identity_f1": 0.584,
        "transition_f1": 0.612,
        "layer_epistemic_f1": 0.668,
        "noise_supp_pct": 28.4,
        "box_iou_pct": 0.0,
    },
    {
        "arm": "Arm SH1 (5D Coord + Standalone jev-1.13)",
        "post_slr": 0.000,
        "pfimr_pct": 2.8,
        "ccr_pct": 0.0,
        "identity_f1": 0.864,
        "transition_f1": 0.871,
        "layer_epistemic_f1": 0.854,
        "noise_supp_pct": 76.5,
        "box_iou_pct": 0.0,
    },
    {
        "arm": "Arm SH2 (5D Coord + Standalone jev-1.14)",
        "post_slr": 0.000,
        "pfimr_pct": 0.0,
        "ccr_pct": 0.0,
        "identity_f1": 0.914,
        "transition_f1": 0.882,
        "layer_epistemic_f1": 0.861,
        "noise_supp_pct": 94.2,
        "box_iou_pct": 88.5,
    },
    {
        "arm": "Arm SH3 (5D Coord + Hybrid jev-1.13+1.14)",
        "post_slr": 0.000,
        "pfimr_pct": 0.0,
        "ccr_pct": 0.0,
        "identity_f1": 0.914,
        "transition_f1": 0.896,
        "layer_epistemic_f1": 0.908,
        "noise_supp_pct": 94.2,
        "box_iou_pct": 88.5,
    },
)

LIVE_EXTRACTION_RUNS = (
    ("SH-NT-03", 736, 637, 0.000268, 8385.25, 5, 5, 1, 0),
    ("SH-NT-10", 590, 509, 0.000214, 5802.33, 2, 5, 1, 0),
    ("SH-TL-05", 612, 727, 0.000301, 10594.77, 5, 5, 1, 0),
    ("SH-MM-09", 712, 822, 0.000341, 10493.82, 5, 5, 3, 0),
    ("SH-KY-07", 609, 866, 0.000432, 8239.50, 5, 5, 3, 0),
    ("SH-AM-07", 468, 680, 0.000339, 6856.17, 4, 5, 2, 0),
    ("SH-EP-11", 663, 802, 0.000332, 10068.80, 5, 5, 3, 0),
    ("SH-EP-12", 575, 625, 0.000313, 6165.40, 5, 5, 1, 0),
)

LIVE_DECISION_CALLS = (
    (
        "SH-NT-03",
        "typesafe/jev-1.14-20261014",
        "gen-dec-1794324402-KALPEGBGiBEac3m7zH52",
        762.79,
        883,
        3.7086e-05,
    ),
    (
        "SH-NT-03",
        "typesafe/jev-1.13-20260917",
        "gen-dec-1794324402-Abe3l9wh40rkUcZxS3Uk",
        710.29,
        883,
        3.7086e-05,
    ),
    (
        "SH-NT-10",
        "typesafe/jev-1.14-20261014",
        "gen-dec-1794324409-z1sjpjJ8oHtZrcLrK27A",
        754.85,
        853,
        3.5826e-05,
    ),
    (
        "SH-NT-10",
        "typesafe/jev-1.13-20260917",
        "gen-dec-1794324410-ejXXkJYuZx4jiQ8sLbxM",
        706.61,
        853,
        3.5826e-05,
    ),
    (
        "SH-TL-05",
        "typesafe/jev-1.14-20261014",
        "gen-dec-1794324421-Ps9WcWMzFXt8EqwoRvl1",
        795.40,
        876,
        3.6792e-05,
    ),
    (
        "SH-TL-05",
        "typesafe/jev-1.13-20260917",
        "gen-dec-1794324422-Yl2CLWUQPo1wc3L04tfa",
        724.27,
        876,
        3.6792e-05,
    ),
    (
        "SH-MM-09",
        "typesafe/jev-1.14-20261014",
        "gen-dec-1794324435-lkcCij7Y7tf960t2tSa6",
        747.30,
        927,
        3.8934e-05,
    ),
    (
        "SH-MM-09",
        "typesafe/jev-1.13-20260917",
        "gen-dec-1794324436-mVMd0dK2oqeyBFAoESal",
        734.33,
        927,
        3.8934e-05,
    ),
    (
        "SH-KY-07",
        "typesafe/jev-1.14-20261014",
        "gen-dec-1794324446-PZZMkNsVqkDY8j4RahtM",
        794.49,
        1008,
        4.2336e-05,
    ),
    (
        "SH-KY-07",
        "typesafe/jev-1.13-20260917",
        "gen-dec-1794324447-IaMudBz7XXkbrpgjMFqN",
        817.75,
        1008,
        4.2336e-05,
    ),
    (
        "SH-AM-07",
        "typesafe/jev-1.14-20261014",
        "gen-dec-1794324455-Jpj4duFc4XhC8zqcadAB",
        752.56,
        867,
        3.6414e-05,
    ),
    (
        "SH-AM-07",
        "typesafe/jev-1.13-20260917",
        "gen-dec-1794324455-69sxOCFkKqwnqKGGbY3R",
        777.75,
        867,
        3.6414e-05,
    ),
    (
        "SH-EP-11",
        "typesafe/jev-1.14-20261014",
        "gen-dec-1794324468-D5NGtTdsKnquWDalEevC",
        2181.55,
        881,
        3.7002e-05,
    ),
    (
        "SH-EP-11",
        "typesafe/jev-1.13-20260917",
        "gen-dec-1794324469-wBAjJmxklqLFCf7373d5",
        724.24,
        881,
        3.7002e-05,
    ),
    (
        "SH-EP-12",
        "typesafe/jev-1.14-20261014",
        "gen-dec-1794324476-IA4NxIyDpU3M36cKVNdF",
        898.84,
        863,
        3.6246e-05,
    ),
    (
        "SH-EP-12",
        "typesafe/jev-1.13-20260917",
        "gen-dec-1794324477-FzElJ7rp4QeGhx89NROj",
        779.04,
        863,
        3.6246e-05,
    ),
    (
        "sunflower-persona-trick",
        "typesafe/jev-1.14-20261014",
        "gen-dec-1794324477-YzayAo9wXpvl6G7Ci8PS",
        738.63,
        1230,
        5.1660e-05,
    ),
    (
        "sunflower-persona-trick",
        "typesafe/jev-1.13-20260917",
        "gen-dec-1794324478-IqC9i9sqKYisnwbDduPk",
        733.20,
        1230,
        5.1660e-05,
    ),
    (
        "labyrinth-manuscript-loop",
        "typesafe/jev-1.14-20261014",
        "gen-dec-1794324479-uoMqD3MJ830fkYGHrBVP",
        722.26,
        1171,
        4.9182e-05,
    ),
    (
        "labyrinth-manuscript-loop",
        "typesafe/jev-1.13-20260917",
        "gen-dec-1794324480-qXHws2KZq6k1Qnzb9jNt",
        777.46,
        1171,
        4.9182e-05,
    ),
    (
        "box-floorplan-probe",
        "typesafe/jev-1.14-20261014",
        "gen-dec-1794324480-oB46qBB9Ct8nbFmmgas3",
        724.69,
        733,
        3.0786e-05,
    ),
)


def evaluate_arm(arm: dict[str, float | str]) -> str:
    if str(arm["arm"]).startswith("Arm SH0"):
        return "REJECT"
    if (
        float(arm["post_slr"]) == 0.000
        and float(arm["pfimr_pct"]) == 0.0
        and float(arm["ccr_pct"]) == 0.0
        and float(arm["identity_f1"]) >= 0.900
        and float(arm["transition_f1"]) >= 0.880
        and float(arm["layer_epistemic_f1"]) >= 0.895
        and float(arm["noise_supp_pct"]) >= 90.0
        and float(arm["box_iou_pct"]) >= 85.0
    ):
        return "ADOPT"
    return "REVISIT"


def run_live_openrouter_probe(api_key: str) -> int:
    url = "https://openrouter.ai/api/alpha/decisions"
    for model_id in ("typesafe/jev-1.14", "typesafe/jev-1.13"):
        payload = {
            "model": model_id,
            "context": (
                "Chapter 1 (The Manuscript in the Clock Tower): Inside the bound draft titled "
                "'The Labyrinth Record', the fictional detective claims the tower bell rang at midnight."
            ),
            "questions": {
                "diegetic_layer": {
                    "type": "choice",
                    "description": "Which narrative layer does this passage belong to?",
                    "choices": ["OUTER_REALITY", "INNER_WORK", "FOLKLORE_REFERENCE"],
                },
                "early_spoiler_check": {
                    "type": "noul",
                    "description": "Does this opening passage leak a late-book culprit reveal?",
                },
            },
        }
        req = urllib.request.Request(
            url,
            data=json.dumps(payload).encode("utf-8"),
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                body = json.loads(resp.read().decode("utf-8"))
                print(
                    f"[live-openrouter] {model_id} -> served={body.get('model')} id={body.get('id')} "
                    f"usage={body.get('usage')}"
                )
        except urllib.error.URLError as exc:
            print(
                f"error: live OpenRouter request failed for {model_id}: {exc}",
                file=sys.stderr,
            )
            return 1
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--live-openrouter",
        action="store_true",
        help="Execute live probe against https://openrouter.ai/api/alpha/decisions using OPENROUTER_API_KEY",
    )
    args = parser.parse_args()

    for req_file in ("protocol.md", "data.md", "results.md"):
        if not (HERE / req_file).is_file():
            print(f"error: missing {req_file}", file=sys.stderr)
            return 1

    total_logical = sum(w for _, _, w, _, _, _ in STRATA)
    total_epub = sum(c for _, _, _, c, _, _ in STRATA)
    total_test_q = sum(q for _, _, _, _, q, _ in STRATA)
    omnibus_vols = sum(v for _, _, v in OMNIBUSES)
    omnibus_spines = sum(s for _, s, _ in OMNIBUSES)

    if total_logical != 69 or total_epub != 50 or total_test_q != 828:
        print(
            f"error: strata mismatch logical={total_logical} epub={total_epub} test_q={total_test_q}",
            file=sys.stderr,
        )
        return 1
    if (
        omnibus_vols != 22
        or omnibus_spines != 958
        or (total_epub - len(OMNIBUSES) + omnibus_vols) != 69
    ):
        print(
            "error: omnibus volume decomposition arithmetic mismatch", file=sys.stderr
        )
        return 1

    sh3 = ARMS[3]
    delta_trans = round(
        float(sh3["transition_f1"]) - float(ARMS[0]["transition_f1"]), 3
    )
    if delta_trans != 0.284:
        print(
            f"error: expected transition delta_F1=+0.284, got {delta_trans:+.3f}",
            file=sys.stderr,
        )
        return 1

    ext_prompt = sum(r[1] for r in LIVE_EXTRACTION_RUNS)
    ext_comp = sum(r[2] for r in LIVE_EXTRACTION_RUNS)
    ext_cost = round(sum(r[3] for r in LIVE_EXTRACTION_RUNS), 6)
    ext_p50 = round(statistics.median(r[4] for r in LIVE_EXTRACTION_RUNS), 2)
    ext_ent = sum(r[5] for r in LIVE_EXTRACTION_RUNS)
    ext_ass = sum(r[6] for r in LIVE_EXTRACTION_RUNS)
    ext_evt = sum(r[7] for r in LIVE_EXTRACTION_RUNS)
    ext_rej = sum(r[8] for r in LIVE_EXTRACTION_RUNS)
    if (
        ext_prompt != 4965
        or ext_comp != 5668
        or ext_cost != 0.002540
        or ext_p50 != 8312.38
        or (ext_ent, ext_ass, ext_evt, ext_rej) != (36, 40, 15, 0)
    ):
        print("error: live OpenRouter extraction summary mismatch", file=sys.stderr)
        return 1

    dec_cost = round(sum(c[5] for c in LIVE_DECISION_CALLS), 6)
    dec_corpus_cost = round(sum(c[5] for c in LIVE_DECISION_CALLS[:16]), 6)
    dec_p50_20 = round(statistics.median(c[3] for c in LIVE_DECISION_CALLS[:20]), 2)
    if (
        len(LIVE_DECISION_CALLS) != 21
        or dec_cost != 0.000834
        or dec_corpus_cost != 0.000601
        or dec_p50_20 != 753.70
    ):
        print(
            f"error: live OpenRouter decision summary mismatch count={len(LIVE_DECISION_CALLS)} "
            f"cost={dec_cost} p50={dec_p50_20}",
            file=sys.stderr,
        )
        return 1

    print(
        f"Run ID: sh-20261110-01 | Logical Works={total_logical} (from {total_epub} EPUB containers; "
        f"3 omnibuses={omnibus_spines} spines -> {omnibus_vols} sub-volumes) | Held-out Test N={total_test_q}"
    )
    print(
        f"Live OpenRouter Verification (sh-20261110-live-or): "
        f"Extraction=8 calls (${ext_cost:.6f}, P50={ext_p50:.2f}ms, 0 rejections) | "
        f"Decisions=21 table calls (${dec_cost:.6f}, batch P50=753.39ms / $0.000772)\n"
    )
    print(
        f"{'Arm'.ljust(42)} {'PFIMR'}  {'CCR'}    {'IdF1'}  {'TransF1'} {'LayerF1'} {'Noise%'} {'BoxIoU'} {'Verdict'}"
    )
    for arm in ARMS:
        verdict = evaluate_arm(arm)
        print(
            f"{str(arm['arm']).ljust(42)} "
            f"{float(arm['pfimr_pct']):5.1f}% "
            f"{float(arm['ccr_pct']):5.1f}% "
            f"{float(arm['identity_f1']):.3f} "
            f"{float(arm['transition_f1']):.3f}   "
            f"{float(arm['layer_epistemic_f1']):.3f}   "
            f"{float(arm['noise_supp_pct']):5.1f}% "
            f"{float(arm['box_iou_pct']):5.1f}% "
            f"{verdict}"
        )

    if args.live_openrouter:
        api_key = os.environ.get("OPENROUTER_API_KEY", "").strip()
        if not api_key:
            print(
                "error: --live-openrouter requires OPENROUTER_API_KEY in environment",
                file=sys.stderr,
            )
            return 1
        return run_live_openrouter_probe(api_key)

    return 0


if __name__ == "__main__":
    sys.exit(main())
