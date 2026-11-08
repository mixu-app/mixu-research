# Internal Review and Pre-Submission Verification Log

- **Paper:** [paper.md](paper.md) (*Progress-Aware Narrative Knowledge Engineering: Epistemic Horizon Filtering for Mystery Fiction*)
- **Current status:** `draft`
- **Review round:** `R0` (Internal pre-submission audit, `2026-11-08`)

## 1. Repository Governance and Integrity Checklist

| Rule (`papers/ours/README.md` & `AGENTS.md`) | Status | Verification Evidence |
|---|---|---|
| Status is honestly labelled (`idea` or `draft`, never falsely `published`) | Pass | `Status: draft` in header of [paper.md](paper.md) and index in [../README.md](../README.md). |
| Every number in the abstract is traceable to an `experiments/<slug>/results.md` | Pass | All numbers in Abstract Claims 1–3 map 1-to-1 to [../../experiments/spoiler-decisions/results.md](../../experiments/spoiler-decisions/results.md) (`sd-20261108-01`) and [../../experiments/extraction-model-pool/results.md](../../experiments/extraction-model-pool/results.md) (`emp-20261108-01`). |
| Data availability statement points strictly at `corpora/manifest.json` + `tools/fetch_corpus.py`, never redistributed text | Pass | Verified in §5 of [paper.md](paper.md) and enforced by CI `no-book-text` gate. |
| Related work cites the repository's literature notes and states explicit disagreements | Pass | §3 of [paper.md](paper.md) cites all four notes in `papers/literature/` and states exact methodological and empirical disagreements for each. |
| Paper states its own limitations before an external reviewer does | Pass | §4 of [paper.md](paper.md) documents `R-01` pretraining memorization, unreliable-narrator omission ceilings (`christie-ackroyd`), edition offset sensitivity, and non-English novella length bounds. |

## 2. Internal Review Comments and Author Responses (`R0`)

### Comment R0-1 (Confound `R-01`: Pretraining Contamination on Christie and Doyle)

- **Critique:** A skeptical ACL reviewer will immediately object that *The Murder of Roger Ackroyd* and *A Study in Scarlet* are among the most famous detective novels in English literature. How do we know `jev-decision-1.13` and `deepseek-v3-0324` are not simply recalling Wikipedia plot summaries?
- **Resolution in draft:** Added explicit disaggregation in Claim 3 and §2.1 between famous public-domain works ($n = 360$ test queries) and unseen CC0 synthetic mysteries (`mixu-fixtures@v0.1.0`, $n = 360$ test queries). We show that unconstrained LLM JSON (Arm B) indeed suffers an $8.6\times$ spike in pre-filter spoiler leakage on famous novels ($6.9\%$ vs $0.8\%$), proving the reviewer's concern is real for naive LLM pipelines—whereas our span-grounded classifier (`jev-decision-1.13` Arm C) maintains pre-filter $\text{SLR} = 0.003$ and achieves slightly higher Macro-$F_1$ on unseen stories ($0.862$) than on famous novels ($0.854$).

### Comment R0-2 (Justification of Escalation Band $[0.45, 0.72)$ in Arm D)

- **Critique:** Why is the lower bound of Arm D's escalation band set at $p = 0.45$ while the upper bound is $\tau^* = 0.72$?
- **Resolution in draft:** Documented via the 10-bin reliability diagram in [../../experiments/spoiler-decisions/results.md](../../experiments/spoiler-decisions/results.md). Predictions with $p < 0.45$ (Bins 3–4, $25/720$ items) correspond to clear negative/ungrounded candidates that should remain `UNRESOLVED` without wasting an LLM call, while predictions in $[0.45, 0.72)$ (Bins 5–7, $18.3\%$ of queries) contain subtle multi-turn irony and clock-alibi contradictions where escalating to `qwen2.5-72b-instruct` yields $+0.031$ Macro-$F_1$ gain ($0.889$ vs $0.858$) while keeping $P_{95} = 485\text{ ms} \le 600\text{ ms}$ and cost at $\$0.34 / 1{,}000\text{ decisions}$.

### Comment R0-3 (Grammar-Constrained Decoding Confound in Extraction Benchmark)

- **Critique:** In `experiments/extraction-model-pool`, `qwen2.5-14b-instruct` (Arm E1) had a $9.3\%$ `SCHEMA_INVALID` rate under standard JSON mode. Would grammar-constrained decoding (`guided_json`) rescue Arm E1?
- **Resolution in draft:** Explicitly recorded in `experiments/extraction-model-pool/results.md` under `## What we cannot conclude`: finite-state grammar decoding would eliminate `SCHEMA_INVALID` ($9.3\%$) mechanically, but would not fix Arm E1's $14.7\%$ `EVIDENCE_NOT_SUBSTRING` rate (quote paraphrasing/normalization) or its lower Edge Macro-$F_1$ ($0.734 < 0.800$).
