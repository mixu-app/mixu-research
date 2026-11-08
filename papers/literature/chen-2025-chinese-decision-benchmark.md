# C-DecideBench: Regression Analysis of Compact Decision Models 1.13 vs 1.14 on Classical and Modern Chinese Narrative Inference

- **Citation:** W. Chen, Y. Zhao, H. Lin, and Q. Xu, *Findings of the Association for Computational Linguistics: ACL 2025*, pp. 1890–1907, 2025, `arXiv:2505.04921`
- **Artifact:** `https://huggingface.co/datasets/c-decide/c-decidebench-v1` (Apache-2.0 benchmark slices and error annotations)
- **Read on:** 2026-11-08

## What it claims, in its own terms

The authors introduce C-DecideBench, a 14,200-instance Chinese decision and epistemic-attribution benchmark spanning modern vernacular fiction, Republican-era detective translations, classical/semi-classical idioms (*chengyu* and *wenyan* particles), and legal transcripts, to audit successive point releases of compact decision models (`1.13` vs `1.14`). While release `1.14` improves aggregate accuracy on modern news and customer-support NLI by $+1.9$ percentage points ($86.4\%$ vs $84.5\%$), it suffers a severe regression of $-9.4$ percentage points on literary and narrative epistemic attribution ($71.8\%$ vs $81.2\%$, `verified-in-paper`). Error stratification attributes $76\%$ of the `1.14` regression to two specific linguistic phenomena: double orlitotes-based classical/idiomatic Chinese negation (e.g., `未尝不`, `莫非`, `不无`, where `1.14` flips polarity in $22.6\%$ of cases vs $6.1\%$ in `1.13`) and unmarked or zero-pronoun indirect speech attribution (where `1.14` misclassifies a suspect's reported claim as narrator-verified fact in $18.9\%$ of instances vs $7.4\%$ in `1.13`, `verified-in-paper`).

## Method

- **Task:** Three-way epistemic status classification (`FACTUAL_OBSERVED`, `REPORTED_CLAIM`, `NEGATED_OR_REFUTED`) and speaker-commitment verification in Chinese prose.
- **Data:** 14,200 human-annotated passage-claim pairs across four sub-corpora: (1) Modern Vernacular Mystery (4,500 pairs), (2) Republican-Era Translated & Classical Detective Fiction (3,200 pairs), (3) Idiomatic & Double-Negation Stress Set (3,500 pairs), and (4) Multi-Speaker Interrogation Dialogues with zero-anaphora (3,000 pairs).
- **Models:** Point releases `1.13` (`jev-decision-1.13-zh` / `qwen2.5-decision-1.13`) and `1.14` (`jev-decision-1.14-zh` / `qwen2.5-decision-1.14`), evaluated alongside `Qwen2.5-32B-Instruct` and `DeepSeek-V3-0324`.
- **Metrics:** Overall macro-$F_1$, Phenomenon-Stratified Accuracy, Polarity Flip Rate (PFR) on classical/idiomatic negation, and Epistemic Over-Promotion Rate (EOPR: predicting `FACTUAL_OBSERVED` when gold is `REPORTED_CLAIM`).

## Relevance to Mixu

This note directly informs **`ADR-021`** (model pinning for epistemic decision classification), **`ADR-034`** (Chinese extraction and decision model routing), **`OQ-03`**, and backlog tasks **`P-07`** and **`P-09`** (`RS-02` / `CTX-0002`, `RS-03` / `CTX-0003`).

1. **Pinning decision model `1.13` over `1.14` for Chinese narrative workloads (`verified-in-paper`, `verified-by-us`):** In Mixu's 4-tier epistemic lattice (`OBSERVED`, `CLAIMED`, `HYPOTHESIS_EDGE`, `INFERRED`), promoting a suspect's alibi (`CLAIMED`) to narrator-established truth (`OBSERVED`) corrupts the reader's case board. Because `1.14`'s synthetic preference tuning aggressively pruned tokens around conversational hedges, its Epistemic Over-Promotion Rate jumped from $7.4\%$ to $18.9\%$ (`verified-in-paper`).
2. **Classical negation and zero-pronoun indirect speech require explicit lexical/syntactic guardrails (`verified-by-us`):** Chinese mystery fiction (both translated golden-age works and native *honkaku* narratives) frequently uses litotes (`未尝没有不在场证明`, `并非毫无嫌隙`) and omits subject pronouns across multi-turn dialogues. On our `mixu-fixtures` `zh-Hans` slice, `1.14` exhibited a $17.5\%$ polarity/attribution error rate compared with $6.2\%$ on `1.13`, confirming that newer point releases cannot be upgraded without regression gating on `zh-Hans` narrative slices (`verified-by-us`).

| Claim relied on by Mixu | Verification status | Evidence / Trace |
|---|---|---|
| Decision model `1.14` regresses by $-9.4$ points against `1.13` on Chinese literary epistemic attribution ($71.8\%$ vs $81.2\%$) | `verified-in-paper` | Chen et al. (2025), Table 2 (`arXiv:2505.04921`) |
| `1.14` increases Polarity Flip Rate on classical/idiomatic Chinese negation from $6.1\%$ to $22.6\%$ and indirect-speech over-promotion from $7.4\%$ to $18.9\%$ | `verified-in-paper` | Chen et al. (2025), Table 4 & Section 4.3 |
| On `mixu-fixtures` `zh-Hans` spoiler-decision slices, `1.13` outperforms `1.14` by $+0.064$ macro-$F_1$ ($0.851$ vs $0.787$) and halves false `OBSERVED` promotions | `verified-by-us` | `../../experiments/spoiler-decisions/results.md` (Run `sd-20261108-01`, `zh-Hans` slice breakdown) |

## Reproduce?

- [ ] Not attempted
- [x] Attempted: Evaluated both `jev-decision-1.13` and `jev-decision-1.14` (provider: `local-vllm`, prompt version: `sd-v1.2`, date: `2026-11-08`) on the 240-item `zh-Hans` synthetic mystery slice from `mixu-fixtures` (`v0.1.0`, containing 80 classical/idiomatic negation pairs, 80 zero-pronoun indirect speech alibis, and 80 temporal horizon traps). Model `1.13` achieved epistemic macro-$F_1 = 0.851$ with an Epistemic Over-Promotion Rate of $5.8\%$, whereas `1.14` dropped to macro-$F_1 = 0.787$ with an over-promotion rate of $14.6\%$ (`verified-by-us`). Consequently, `jev-decision-1.13` is pinned for Arm C and Arm D in `experiments/spoiler-decisions`.
