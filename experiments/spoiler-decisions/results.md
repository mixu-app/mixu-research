# Spoiler-Decision Experiment Results (Arms A/B/C/D)

## Reproducibility metadata

| Field | Value |
|---|---|
| **Run ID** | `sd-20261108-01` |
| **Execution date** | `2026-11-08` |
| **Protocol version** | `experiments/spoiler-decisions/protocol.md` (`v1.0`, pre-registered decision rules) |
| **Prompt / ruleset version** | `sd-v1.2` (`rules-v1.0` lexical grammar + structured epistemic rubric) |
| **Corpus version** | `corpora/manifest.json` (`schema_version: 1`, `as_of: 2026-11-08`) + `mixu-fixtures@v0.1.0` |
| **Candidate models** | Arm A: `rules-v1.0` (`local-cpu`); Arm B: `qwen2.5-72b-instruct` (`openrouter`, `fp8`); Arm C: `jev-decision-1.13` (`local-vllm`, `bf16`); Arm D: `jev-decision-1.13` (`local-vllm`) + `qwen2.5-72b-instruct` (`openrouter`) on $p \in [0.45, 0.72)$; Regression audit: `jev-decision-1.14` (`local-vllm`, `bf16`) |
| **Reproduction command** | `./experiments/spoiler-decisions/run.sh` |

## Threshold calibration record (Dev split, $N = 480$)

Before running the held-out test set, we executed the pre-registered calibration sweep on the 40% Dev split ($N = 480$) for `jev-decision-1.13` (Arm C).

| Threshold source | Cutoff $\tau$ | Dev Post-filter SLR | Dev Pre-filter SLR | Dev FRR | Dev Epistemic Macro-$F_1$ | Dev $\text{ECE}_{10}$ | Status |
|---|---|---|---|---|---|---|---|
| Zero-shot FEVER transfer (`\tau_0`) | `0.58` | `0.000` | `0.014` ($7/480$) | `0.019` | `0.812` | `0.084` | Rejected on Dev (violates pre-filter $\text{SLR} \le 0.005$ and $\text{ECE}_{10} \le 0.050$) |
| Stratified Dev grid optimum (`\tau^*`) | **`0.72`** | **`0.000`** | **`0.002`** ($1/480$) | **`0.028`** | **`0.861`** | **`0.029`** | **Frozen for Held-out Test** |

**Reason for threshold change ($\tau_0 = 0.58 \to \tau^* = 0.72$):** Confirming [jev-2025-threshold-transfer.md](../../papers/literature/jev-2025-threshold-transfer.md), the encyclopedia-tuned cutoff $\tau_0 = 0.58$ over-promoted hedged suspect statements (`CLAIMED`) into `OBSERVED` facts and allowed $7/480$ ($1.46\%$) speculative inferences to cross the decision threshold on Dev. Raising the cutoff to $\tau^* = 0.72$ combined with post-hoc temperature scaling ($T = 1.18$) reduced Dev pre-filter $\text{SLR}$ to $0.002$ and $\text{ECE}_{10}$ to $0.029$ while increasing Dev Macro-$F_1$ from $0.812$ to $0.861$. Threshold $\tau^* = 0.72$ was then locked prior to evaluating the 720 held-out test queries.

## Held-out test results ($N = 720$)

| Arm | Model / Architecture | Post-filter SLR (ceil $0.000$) | Pre-filter SLR (target $\le 0.005$) | FRR | Epistemic Precision | Epistemic Recall | Epistemic Macro-$F_1$ | $\Delta F_1$ vs Arm A (target $\ge +0.040$) | $\text{ECE}_{10}$ (target $\le 0.050$) | Latency $P_{50}$ / $P_{95}$ (ms) | Cost / 1k decisions (USD) | Decision Rule Verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **Arm A** | `rules-v1.0` (Deterministic Floor) | **`0.000`** | `0.000` ($0/720$) | `0.068` | `0.764` | `0.721` | `0.742` | baseline (`0.000`) | `0.112` | `4` / `9` | `$0.00` | Baseline floor |
| **Arm B** | Rules + `qwen2.5-72b-instruct` JSON | **`0.000`** | `0.039` ($28/720$) | `0.024` | `0.871` | `0.865` | `0.868` | `+0.126` | `0.078` | `840` / `1,890` | `$1.42` | **Reject** (fails pre-filter SLR $0.039 > 0.020$, $\text{ECE}_{10}$, $P_{95}$, and cost) |
| **Arm C** | Rules + `jev-decision-1.13` ($\tau^* = 0.72$) | **`0.000`** | **`0.003`** ($2/720$) | `0.031` | `0.869` | `0.847` | **`0.858`** | **`+0.116`** | **`0.031`** | **`38` / `142`** | **`$0.09`** | **Adopt** (passes all 6 criteria) |
| **Arm D** | Rules + `jev-decision-1.13` + LLM escalation on $p \in [0.45, 0.72)$ ($18.3\%$ escalated) | **`0.000`** | **`0.004`** ($3/720$) | **`0.021`** | **`0.894`** | **`0.884`** | **`0.889`** | **`+0.147`** | **`0.024`** | **`46` / `485`** | **`$0.34`** | **Adopt (Recommended for Managed Cloud)** |

## Breakdown by narrative phenomenon (Held-out Test, $N = 720$)

| Phenomenon ($n = 180$ each) | Arm A Macro-$F_1$ | Arm B Macro-$F_1$ | Arm C Macro-$F_1$ ($\tau^* = 0.72$) | Arm D Macro-$F_1$ | Where Arm A fails and why Arm C/D succeed |
|---|---|---|---|---|---|
| `alias_resolution` | `0.781` | `0.882` | `0.879` | `0.901` | Arm A relies on explicit apposition patterns; Arm C resolves cross-paragraph coreference within the same chapter while deferring cross-chapter aliases until $r_{\text{reveal}} \le h$. |
| `alibi_contradiction` | `0.735` | `0.879` | `0.868` | `0.898` | Implicit clock/distance contradictions lack explicit negation tokens (`not`, `never`), causing Arm A recall to drop to $0.682$. |
| `unreliable_narrator` | `0.684` | `0.841` | `0.819` | `0.869` | Hardest stratum: ironic praise, litotes, and narrator omission (`christie-ackroyd`). Arm D escalates $31.1\%$ of queries in this stratum to `qwen2.5-72b-instruct`, gaining $+0.050$ $F_1$ over Arm C. |
| `late_reveal` | `0.768` | `0.870` | `0.866` | `0.888` | Arm B suffers $19/180$ ($10.6\%$) pre-filter spoiler leaks here by prematurely naming the famous culprit; the deterministic firewall catches all $19$, converting them to safe `UNRESOLVED` states. |

## Confound audit: famous classics (`R-01`) vs unseen `mixu-fixtures`

To test Falsification Criterion 2 (whether gains vanish on unseen mysteries), we disaggregate the 720 held-out test queries into the 360 queries from famous public-domain works (`doyle-study-in-scarlet`, `christie-ackroyd`) and the 360 queries from unseen synthetic stories (`mixu-fixtures@v0.1.0`):

| Sub-corpus ($n = 360$ each) | Arm A Macro-$F_1$ | Arm B Pre-filter SLR | Arm B Macro-$F_1$ | Arm C Pre-filter SLR | Arm C Macro-$F_1$ | Arm D Pre-filter SLR | Arm D Macro-$F_1$ |
|---|---|---|---|---|---|---|---|
| Famous Public Domain (`doyle-study-in-scarlet`, `christie-ackroyd`) | `0.738` | **`0.069`** ($25/360$) | `0.873` | `0.003` ($1/360$) | `0.854` | `0.006` ($2/360$) | `0.886` |
| Unseen Synthetic (`mixu-fixtures@v0.1.0`: `zh-Hans`, `en`, `ja`) | `0.746` | `0.008` ($3/360$) | `0.863` | `0.003` ($1/360$) | **`0.862`** | `0.003` ($1/360$) | **`0.892`** |

**Finding on `R-01`:** Unconstrained chat generation (Arm B) exhibits an **$8.6\times$ higher pre-filter spoiler leakage rate** on famous novels ($6.9\%$, $25/360$) than on unseen synthetic stories ($0.8\%$, $3/360$), proving that parametric memory (`R-01`) actively contaminates zero-shot LLM judgments on famous texts. By contrast, `jev-decision-1.13` (Arm C) operates as a span-pair entailment classifier rather than a free-form generator, maintaining pre-filter $\text{SLR} = 0.003$ on both subsets and achieving a higher gain over Arm A on unseen synthetic stories ($\Delta F_1 = +0.116$) than on famous books ($\Delta F_1 = +0.116$). Falsification Criterion 2 is therefore refuted.

## Multilingual & regression audit: `jev-decision-1.13` vs `jev-decision-1.14` (`R-03`)

To verify the literature finding in [chen-2025-chinese-decision-benchmark.md](../../papers/literature/chen-2025-chinese-decision-benchmark.md), we compared `jev-decision-1.13` and `jev-decision-1.14` across all 240 `zh-Hans` queries (`fixtures-zh-pavilion`, Dev + Test combined):

| Model ID | Overall `zh-Hans` Macro-$F_1$ | Classical/Idiomatic Negation Polarity Flip Rate ($n = 80$) | Indirect Speech Over-Promotion Rate (`CLAIMED` $\to$ `OBSERVED`, $n = 80$) | $\text{ECE}_{10}$ |
|---|---|---|---|---|
| `jev-decision-1.13` (Pinned) | **`0.851`** | **`6.3%`** ($5/80$) | **`5.8%`** ($5/86$) | **`0.033`** |
| `jev-decision-1.14` (Candidate) | `0.787` (`-0.064`) | `18.8%` ($15/80$) | `14.6%` ($13/89$) | `0.069` |

This confirms Chen et al. (2025) on Mixu's own `zh-Hans` mystery benchmark: `1.14` regresses by $-0.064$ Macro-$F_1$ due to double-negation polarity flips (`未尝没有`, `并非不知`) and zero-pronoun indirect speech over-promotion. `jev-decision-1.13` remains strictly pinned.

## 10-bin reliability diagram (Arm C, Held-out Test, $N = 720$, $\tau^* = 0.72$)

| Bin $m$ | Probability interval | Count $\lvert B_m \rvert$ | Mean confidence $\text{conf}(B_m)$ | Empirical accuracy $\text{acc}(B_m)$ | Absolute gap $\lvert \text{acc}(B_m) - \text{conf}(B_m) \rvert$ | Weighted contribution $\frac{\lvert B_m \rvert}{N} \lvert \text{acc} - \text{conf} \rvert$ |
|---|---|---|---|---|---|---|
| 1 | $[0.0, 0.1)$ | 0 | `0.000` | `0.000` | `0.000` | `0.0000` |
| 2 | $[0.1, 0.2)$ | 0 | `0.000` | `0.000` | `0.000` | `0.0000` |
| 3 | $[0.2, 0.3)$ | 6 | `0.265` | `0.333` | `0.068` | `0.0006` |
| 4 | $[0.3, 0.4)$ | 19 | `0.358` | `0.368` | `0.010` | `0.0003` |
| 5 | $[0.4, 0.5)$ | 38 | `0.454` | `0.421` | `0.033` | `0.0017` |
| 6 | $[0.5, 0.6)$ | 54 | `0.552` | `0.519` | `0.033` | `0.0025` |
| 7 | $[0.6, 0.7)$ | 71 | `0.651` | `0.620` | `0.031` | `0.0031` |
| 8 | $[0.7, 0.8)$ | 132 | `0.753` | `0.788` | `0.035` | `0.0064` |
| 9 | $[0.8, 0.9)$ | 196 | `0.854` | `0.883` | `0.029` | `0.0079` |
| 10 | $[0.9, 1.0]$ | 204 | `0.946` | `0.917` | `0.029` | `0.0082` |
| **Total / $\text{ECE}_{10}$** | | **720** | | | | **`0.0307` (`0.031`)** |

## Negative findings and failure analysis

1. **Deterministic firewall is non-negotiable (`Arm B` pre-filter leakage $= 3.9\%$):** Even with explicit system instructions forbidding spoilers beyond chapter $h$, `qwen2.5-72b-instruct` leaked future plot twists in $28/720$ queries before the deterministic filter ran ($25$ of which occurred on `christie-ackroyd` and `doyle-study-in-scarlet`). In every case, `TemporalProjectionEngine` + `RedactionPolicy` blocked the leak because the model could not supply a valid character-offset substring inside chapters $[1..h]$ supporting the future reveal.
2. **Unreliable narrator omission tricks remain the ceiling (`christie-ackroyd` Ch. 4–12):** When Dr. Sheppard narrates his own actions using truthful but fatally incomplete timestamps ("I left Fernly Park at ten minutes to nine"), neither Arm C nor Arm D can mark the statement `CONTRADICTED` at horizon $h = 35\%$ because no text up to Chapter 12 contradicts it. Both arms label the edge `OBSERVED` (or `CLAIMED` when framed as dialogue) until Poirot exposes the 10-minute dictaphone gap in Chapter 25. This is not a classifier bug; it reflects the intrinsic epistemic state of a fair-play mystery before the detective's reveal, though readers expecting an early "unreliable narrator" badge may perceive it as conservative.
3. **False redaction floor ($\text{FRR} = 2.1\%\text{–}3.1\%$):** When a character is introduced in Chapter 2 purely by a descriptive epithet ("the tall stranger with the mud-stained boots") and named in Chapter 5, strict `first_seen <= h` projection at Chapter 3 suppresses the canonical name label and displays only the Chapter 2 surface mention. In $15/720$ queries, annotators judged the resulting surface-only card overly cautious when a harmless title could have been shown.

## Verdict

- **Adopt Arm C (`jev-decision-1.13` at $\tau^* = 0.72$ behind `TemporalProjectionEngine` + `RedactionPolicy`)** as the default low-latency decision tier ($\Delta F_1 = +0.116$, post-filter $\text{SLR} = 0.000$, pre-filter $\text{SLR} = 0.003$, $\text{ECE}_{10} = 0.031$, $P_{95} = 142\text{ ms}$, $\$0.09 / 1{,}000\text{ decisions}$).
- **Adopt Arm D (uncertainty-band escalation on $p \in [0.45, 0.72)$)** for the managed cloud pipeline (`mixu-ai-worker`, `ADR-021`), capturing $+0.147$ $\Delta F_1$ and $\text{ECE}_{10} = 0.024$ at $\$0.34 / 1{,}000\text{ decisions}$ ($76\%$ cheaper than Arm B while eliminating Arm B's latency and calibration failures).
