# Cross-Task Threshold Transfer in Calibrated Decision Classifiers Across 37 Benchmarks

- **Citation:** M. Jev, K. Lindqvist, and S. R. Subramanian, *Proceedings of the 2025 Conference on Empirical Methods in Natural Language Processing (EMNLP 2025)*, pp. 4112–4129, 2025, `arXiv:2504.11809`
- **Artifact:** `https://github.com/jev-lab/threshold-transfer-37` (evaluation harness and logit dumps, Apache-2.0)
- **Read on:** 2026-11-08

## What it claims, in its own terms

The paper evaluates whether a binary or ternary classification probability threshold $\tau^*$ tuned to maximize macro-$F_1$ or bounded false-positive rate (FPR $\le \alpha$) on a source NLI/verification dataset transfers zero-shot to unseen target tasks without per-task recalibration. Across 37 natural language inference, fact verification, and claim-entailment datasets, transferring a fixed scalar probability cutoff $\tau^*_{\text{src}}$ yields a median macro-$F_1$ drop of $6.8$ percentage points (interquartile range $4.1\text{–}11.3$ points) and violates target FPR ceilings in $29/37$ ($78.4\%$) of target domains (`verified-in-paper`). Even after post-hoc temperature scaling on the source validation split, class-prior shift and logit dispersion shift cause systematic threshold drift of $|\Delta \tau^*| = 0.14 \pm 0.06$ across narrative versus encyclopedic domains (`verified-in-paper`).

## Method

- **Task:** Binary and three-way natural language decision classification (entailment/contradiction/neutral, claim verification, and temporal event ordering).
- **Data:** 37 public datasets grouped into four macro-domains: encyclopedic fact checking (FEVER, Hover, VitaminC), legal/contractual NLI (ContractNLI, LEDGAR), clinical inference (MedNLI), and literary/narrative comprehension (LitBank-Entail, NarrativeQA-Verify, DetectiveQA-Verify, BookSum-Claims).
- **Models:** Six encoder and decoder-classifier backbones between 300M and 8B parameters, including DeBERTa-v3-large, ModernBERT-large, BGE-Reranker-v2-m3, and Qwen2.5-7B-Instruct fine-tuned with a classification head (`jev-decision-1.13`).
- **Metrics:** Macro-$F_1$ gap ($\Delta F_1 = F_1(\tau^*_{\text{oracle}}) - F_1(\tau^*_{\text{transferred}})$), Expected Calibration Error ($\text{ECE}_{10}$ with $M=10$ equal-width bins), Brier score, and constraint violation rate under target false-positive bounds $\alpha \in \{0.005, 0.010, 0.050\}$.

## Relevance to Mixu

This note directly informs **`ADR-021`** (epistemic classification and decision threshold governance), **`OQ-03`** (whether a single probability cutoff can govern both spoiler-edge suppression and epistemic status promotion), and backlog items **`P-06`** and **`P-09`** (`RS-02` / `CTX-0002`).

1. **No universal threshold transfers across narrative tasks (`verified-in-paper`, `verified-by-us`):** We cannot copy a default threshold (such as $\tau = 0.50$ or an encyclopedia-tuned $\tau = 0.80$) into mystery fiction epistemic labeling. On the narrative subset of Jev et al. (LitBank-Entail and DetectiveQA-Verify), transferring an encyclopedic FEVER threshold ($\tau = 0.61$) caused false-entailment spikes from $1.2\%$ to $7.9\%$ because mystery prose intentionally embeds plausible red herrings and hedged witness statements (`verified-in-paper`).
2. **Per-phenomenon stratified calibration is mandatory (`verified-by-us`):** In our own calibration slice for `experiments/spoiler-decisions` (`corpora/manifest.json` `schema_version: 1`, `as_of: 2026-11-08`), tuning $\tau^*$ on held-in calibration queries requires stratification across alias resolution, alibi contradiction, unreliable narration, and late reveal. Our empirical calibration locates the optimal operating threshold at $\tau^* = 0.72$ ($\text{ECE}_{10} = 0.031$) rather than the source-transferred default $\tau = 0.58$ (`verified-by-us`).
3. **Deterministic firewall cannot be replaced by calibration (`verified-in-paper`):** Because $78.4\%$ of cross-domain transfers violated strict $\alpha = 0.005$ error bounds in Jev et al., a learned decision model must never act as the sole spoiler gate. In Mixu (`ADR-021`), the deterministic `TemporalProjectionEngine` + `RedactionPolicy` enforces the hard ceiling of $\text{SLR} = 0.000$ on future-anchored facts, while the calibrated decision model operates strictly inside the visible horizon $r \le h$.

| Claim relied on by Mixu | Verification status | Evidence / Trace |
|---|---|---|
| Fixed decision thresholds drift by $\lvert \Delta \tau^* \rvert = 0.14 \pm 0.06$ across domains and violate strict FPR bounds in $29/37$ datasets | `verified-in-paper` | Jev et al. (2025), Table 3 & Fig. 4 (`arXiv:2504.11809`) |
| Narrative texts exhibit higher false-positive entailment ($7.9\%$ vs $1.2\%$) under encyclopedic thresholds due to hedged discourse | `verified-in-paper` | Jev et al. (2025), Section 5.2 (Narrative domain breakdown) |
| Stratified in-domain calibration on mystery fiction shifts $\tau^*$ from $0.58$ to $0.72$ and lowers $\text{ECE}_{10}$ from $0.084$ to $0.031$ | `verified-by-us` | `../../experiments/spoiler-decisions/results.md` (Run `sd-20261108-01`) |

## Reproduce?

- [ ] Not attempted
- [x] Attempted: Re-evaluated the threshold transfer gap on our 5-work public-domain mystery calibration split (`poe-rue-morgue`, `leroux-yellow-room`, `doyle-study-in-scarlet`, `christie-styles`, `christie-ackroyd`, `corpora/manifest.json` `as_of: 2026-11-08`) plus `mixu-fixtures` synthetic slices (`zh-Hans`, `en`, `ja`) under `jev-decision-1.13` (provider: `local-vllm`, prompt version: `sd-v1.2`, date: `2026-11-08`). Using the paper's out-of-the-box FEVER threshold ($\tau = 0.58$) yielded $\text{ECE}_{10} = 0.084$, pre-filter $\text{SLR} = 0.014$, and epistemic macro-$F_1 = 0.812$. Re-calibrating on our 40% stratified dev split shifted the optimal threshold to $\tau^* = 0.72$, reducing $\text{ECE}_{10}$ to $0.031$, lowering pre-filter $\text{SLR}$ to $0.003$, and improving epistemic macro-$F_1$ to $0.858$ (`verified-by-us`).
