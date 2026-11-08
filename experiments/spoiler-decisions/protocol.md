# Spoiler-Decision Protocol (Arms A/B/C/D)

**Question:** Does adding a calibrated compact decision model (alone or with selective LLM uncertainty escalation) behind Mixu's deterministic horizon filter improve epistemic classification macro-$F_1$ by at least $+0.040$ over deterministic rules alone while maintaining post-filter Spoiler Leakage Rate ($\text{SLR}$) at $0.000$, pre-filter $\text{SLR} \le 0.005$, $\text{ECE}_{10} \le 0.050$, $P_{95} \le 600\text{ ms}$, and cost $\le \$0.80$ per $1{,}000$ decisions?

## Arms

Every arm is gated at output time by the exact same deterministic firewall (`TemporalProjectionEngine` + `RedactionPolicy` in `mixu-spoiler`), which enforces `first_seen <= h`, `reveal_at <= h`, and verbatim character-offset substring grounding inside chapters $[1..h]$. No model arm is permitted to bypass the deterministic filter.

| Arm | Name | Pipeline specification | Model ID & Provider |
|---|---|---|---|
| **Arm A** | Deterministic Rules Floor | `TemporalProjectionEngine` + `RedactionPolicy` + lexical epistemic cue dictionary (hedges, reporting verbs, negation particles). No neural inference. | `rules-v1.0` (`local-cpu`) |
| **Arm B** | Rules + Chat LLM JSON | Deterministic filter + zero-shot structured JSON classification over visible chapter evidence using a general-purpose instruction LLM. | `qwen2.5-72b-instruct` (`openrouter`) |
| **Arm C** | Rules + Dedicated Decision Model | Deterministic filter + compact cross-encoder/classifier decision head calibrated via temperature scaling and evaluated at probability cutoff $\tau^*$. | `jev-decision-1.13` (`local-vllm`) |
| **Arm D** | Rules + Decision Model + Uncertainty Escalation | Deterministic filter + `jev-decision-1.13` as primary classifier; invokes `qwen2.5-72b-instruct` **only** when top-class calibrated probability falls inside the uncertainty band $p \in [0.45, \tau^*)$. | `jev-decision-1.13` (`local-vllm`) + `qwen2.5-72b-instruct` (`openrouter`) |

## Data

- **Corpus slice:** Five public-domain mystery works from `corpora/manifest.json` (`schema_version: 1`, `as_of: 2026-11-08`: `poe-rue-morgue`, `leroux-yellow-room`, `doyle-study-in-scarlet`, `christie-styles`, `christie-ackroyd`) paired with three rights-cleared synthetic mystery slices from `mixu-fixtures` (`v0.1.0`, languages `zh-Hans`, `en`, `ja`).
- **Sample size and deterministic split:** $N = 1{,}200$ labelled horizon-conditioned decision queries ($480$ dev calibration / $720$ held-out test, deterministic $40\% / 60\%$ split partitioned at work/story level and stratified across four narrative phenomena: `alias_resolution`, `alibi_contradiction`, `unreliable_narrator`, and `late_reveal`). Full inventory and bias audit live in [data.md](data.md).

## Metrics

Metrics are ordered strictly by product criticality: spoiler safety first, reader utility second, epistemic fidelity third, probability calibration fourth, and operational budget fifth.

### 1. Spoiler Leakage Rate (SLR)

$$\text{SLR} = \frac{\text{leaked future-reveal items}}{\text{total queries}}$$

We measure two quantities for every arm:

- **Post-filter $\text{SLR}$ (Hard Ceiling $= 0.000$):** The fraction of queries in which an entity, alias merge (`ALIAS_OF`), edge, or epistemic transition whose ground-truth disclosure chapter satisfies $r_{\text{true}} > h$ survives the deterministic `TemporalProjectionEngine` + `RedactionPolicy` gate. Any post-filter $\text{SLR} > 0.000$ is a release-blocking severity-0 failure.
- **Pre-filter $\text{SLR}$:** The fraction of queries in which the upstream model arm proposes, promotes, or infers a fact whose true disclosure locus is $r_{\text{true}} > h$ *before* the deterministic firewall intercepts it. Measuring pre-filter $\text{SLR}$ quantifies parametric memorization leakage (`R-01`) and premature inference risk.

### 2. False Redaction Rate (FRR)

$$\text{FRR} = \frac{\text{redacted items with } r_{\text{true}} \le h}{\text{total visible ground-truth items with } r_{\text{true}} \le h}$$

A trivia-proof firewall that hides everything achieves $\text{SLR} = 0.000$ by destroying the case board. $\text{FRR}$ penalizes over-suppression of clues, alibis, and character relationships that the reader has already encountered at horizon $h$.

### 3. Epistemic Precision, Recall, and Macro-F1 at Threshold $\tau^*$

For all items visible at horizon $h$ ($r_{\text{true}} \le h$), the classifier assigns one of the four epistemic status tiers (`OBSERVED`, `CLAIMED`, `HYPOTHESIS_EDGE`, `INFERRED`) and four transition states (`CORROBORATED`, `CONTRADICTED`, `RETRACTED`, `UNRESOLVED`). Let $C$ be the label set; for each class $c \in C$ at operating threshold $\tau^*$:

$$\text{Precision}_c(\tau^*) = \frac{\text{TP}_c(\tau^*)}{\text{TP}_c(\tau^*) + \text{FP}_c(\tau^*)}, \quad \text{Recall}_c(\tau^*) = \frac{\text{TP}_c(\tau^*)}{\text{TP}_c(\tau^*) + \text{FN}_c(\tau^*)}$$

$$\text{Macro-}F_1(\tau^*) = \frac{1}{\lvert C \rvert} \sum_{c \in C} \frac{2 \cdot \text{Precision}_c(\tau^*) \cdot \text{Recall}_c(\tau^*)}{\text{Precision}_c(\tau^*) + \text{Recall}_c(\tau^*)}$$

### 4. Expected Calibration Error ($\text{ECE}_{10}$) and 10-Bin Reliability Diagram

To verify whether model confidence scores can reliably trigger abstention (`UNRESOLVED`) or selective escalation (Arm D), we partition predictions on the evaluation split ($N$ items) into $M = 10$ equal-width probability bins $B_1, \dots, B_{10}$ spanning $[0.0, 0.1), [0.1, 0.2), \dots, [0.9, 1.0]$:

$$\text{ECE} = \sum_{m=1}^{M} \frac{\lvert B_m \rvert}{N} \left\lvert \text{acc}(B_m) - \text{conf}(B_m) \right\rvert$$

where $\text{acc}(B_m)$ is the empirical fraction of correct predictions in bin $B_m$ and $\text{conf}(B_m)$ is the mean predicted probability in bin $B_m$. Every results report must publish the full 10-bin reliability table ($\lvert B_m \rvert$, $\text{conf}(B_m)$, $\text{acc}(B_m)$, and $\lvert \text{acc}(B_m) - \text{conf}(B_m) \rvert$).

### 5. Latency ($P_{50}, P_{95}$) and Cost per 1,000 Decisions

- **Latency:** End-to-end wall-clock decision latency in milliseconds ($P_{50}$ and $P_{95}$) per query batch, including serialization and any escalation round-trip in Arm D.
- **Cost (USD / 1,000 decisions):** Total inference expenditure per $1{,}000$ evaluated decisions, accounting for input/output tokens, local GPU amortization ($0.45\text{ USD/hour}$ for an L4-equivalent worker), schema-retry penalties, and Arm D escalation frequency.

## Decision rule

Defined prior to executing the held-out evaluation run:

1. **Adopt** a neural decision arm (Arm C or Arm D) if and only if all six conditions hold on the held-out test split:
   - Post-filter $\text{SLR} = 0.000$
   - Pre-filter $\text{SLR} \le 0.005$
   - Epistemic gain $\Delta F_1 = \text{Macro-}F_1(\text{Arm}) - \text{Macro-}F_1(\text{Arm A}) \ge +0.040$
   - Calibration error $\text{ECE}_{10} \le 0.050$
   - Tail latency $P_{95} \le 600\text{ ms}$
   - Operational cost $\le \$0.80\text{ per } 1{,}000\text{ decisions}$
2. **Reject** the decision model architecture if either:
   - $\Delta F_1 < +0.015$ over Arm A (rules floor), **or**
   - Pre-filter $\text{SLR} > 0.020$ (indicating severe parametric or horizon hallucination that stresses the deterministic gate).
3. **Revisit** if $0.015 \le \Delta F_1 < 0.040$, or if accuracy/calibration gates pass but $\text{ECE}_{10} > 0.050$, $P_{95} > 600\text{ ms}$, or cost $> \$0.80 / 1{,}000\text{ decisions}$ (triggering threshold recalibration or uncertainty-band narrowing before product integration).

### Pre-run threshold governance

Per [jev-2025-threshold-transfer.md](../../papers/literature/jev-2025-threshold-transfer.md), cross-task probability thresholds do not transfer zero-shot. Our protocol therefore fixes the calibration procedure before viewing test data:

- Initial baseline cutoff from source FEVER transfer: $\tau_0 = 0.58$.
- Calibration step (permitted once, strictly on the 40% dev split): grid-search $\tau \in [0.50, 0.85]$ in steps of $0.02$ to maximize dev Macro-$F_1$ subject to dev pre-filter $\text{SLR} \le 0.005$ and $\text{FRR} \le 0.040$.
- Any adjustment from $\tau_0$ to $\tau^*$ must be logged with its exact dev metrics in `results.md` before running the 60% held-out test split.

## Falsification criteria

What empirical evidence would falsify the usefulness of a dedicated decision model (`jev-decision-1.13`) in Mixu?

1. **Sufficiency of deterministic lexical rules:** If Arm A (deterministic horizon rules + lexical hedge/reporting-verb grammar) achieves within $0.015$ Macro-$F_1$ of Arm C on held-out test queries—specifically on `alibi_contradiction` and `unreliable_narrator` slices—then maintaining a neural decision model adds operational complexity without meaningful epistemic gain.
2. **Failure to generalize beyond famous memorized plots (`R-01`):** If Arm C's $\Delta F_1 \ge +0.040$ holds on canonical Gutenberg mysteries (`christie-ackroyd`, `doyle-study-in-scarlet`) but collapses to $\Delta F_1 < +0.015$ on unseen synthetic stories in `mixu-fixtures`, the apparent gain is an artifact of pretraining contamination rather than genuine discourse reasoning.
3. **Dominance of direct chat-LLM classification:** If Arm B (`qwen2.5-72b-instruct` JSON) satisfies $P_{95} \le 600\text{ ms}$, cost $\le \$0.80 / 1{,}000\text{ decisions}$, and $\text{ECE}_{10} \le 0.050$ without needing a dedicated compact classifier, then deploying a separate decision model tier (`jev-decision-1.13`) is redundant.

## Known confounds

- **`R-01` (Famous-book training memorization):** Foundation models have seen *The Murder of Roger Ackroyd* and *The Murders in the Rue Morgue* during pretraining. Even when given only Chapters 1–4, an unconstrained model may assign high confidence to the true culprit. We control for `R-01` by evaluating identical metrics separately on the 5 public-domain classics and the 3 unseen synthetic `mixu-fixtures` stories.
- **`R-02` (Chapter boundary density):** 19th-century novellas (`poe-rue-morgue`, continuous narrative segmented into 4 logical parts) have coarse horizon steps compared with 27-chapter Golden Age novels (`christie-ackroyd`).
- **`R-03` (Multilingual negation and zero-anaphora):** As documented in [chen-2025-chinese-decision-benchmark.md](../../papers/literature/chen-2025-chinese-decision-benchmark.md), classical Chinese litotes (`未尝不`, `不无`) and omitted pronouns in dialogue cause point-release regressions (`1.14` vs `1.13`).
