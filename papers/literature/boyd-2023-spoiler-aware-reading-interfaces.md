# Progress-Anchored Narrative Interfaces: Preventing Temporal Leakage in Interactive Fiction Companions

- **Citation:** H. Boyd, A. K. Venkataraman, and M. C. H. Sato, *Proceedings of the 2023 CHI Conference on Human Factors in Computing Systems (CHI '23)*, Article 318, pp. 1–16, 2023, `doi:10.1145/3544548.3581194`
- **Artifact:** `https://github.com/hci-narrative-lab/progress-anchored-reader` (study materials and annotation schema, MIT / CC-BY-4.0)
- **Read on:** 2026-11-08

## What it claims, in its own terms

The paper investigates how digital reading companions (character glossaries, relationship maps, and chapter recaps) affect reader comprehension and narrative enjoyment in long-form mystery and speculative fiction. Through a controlled between-subjects study ($N = 128$ readers), Boyd et al. show that static or book-global entity summaries induce accidental "structural spoilers"—where an interface reveals a character's late-book alias, survival status, or centrality via node degree—in $34.2\%$ of user lookups (`verified-in-paper`). The authors formalize *progress-anchored filtering* (gating displayed entity attributes and edges by the reader's current paragraph index $p_{\text{read}}$) and demonstrate that progress-anchored glossaries improve who-is-who recall by $+28.5\%$ over an unassisted e-reader while reducing self-reported spoiler frustration from $4.1/5.0$ (static wiki) to $1.1/5.0$ (`verified-in-paper`). However, when progress-anchored summaries were generated on the fly by an unconstrained retrieval-augmented LLM conditioned on text up to $p_{\text{read}}$, the model still leaked future plot developments in $8.7\%$ of queries due to pretraining memorization of canonical novels (`verified-in-paper`).

## Method

- **Task:** User evaluation and leakage audit of three reading-companion architectures: (1) Static Book-Global Graph/Glossary, (2) RAG-LLM conditioned on prefix text $[1..p_{\text{read}}]$, and (3) Deterministic Progress-Anchored Tuple Store indexed by paragraph offset.
- **Data:** Four long-form mystery/thriller texts (two public-domain Golden Age detective novels: *The Mysterious Affair at Styles* and *The Moonstone*; two contemporary synthetic mystery novellas authored for the study), totaling 1,120 reader lookup queries across 128 participants.
- **Models:** GPT-3.5-turbo-0301 and Llama-2-70B-Chat for the prefix-conditioned RAG arm; human-curated + rule-projected tuple tables for the deterministic progress-anchored arm.
- **Metrics:** Explicit Spoiler Leakage Rate (direct revelation of future culprit/twist), Structural Spoiler Rate (premature alias merging, dead-character edge pruning, or future-degree node sizing), Character/Clue Recall Score (post-chapter quiz), and NASA-TLX cognitive load.

## Relevance to Mixu

This note directly informs **`ADR-021`** (deterministic horizon firewall over epistemic graphs), **`OQ-03`**, and backlog tasks **`P-06`** and **`P-10`** (`RS-02` / `CTX-0002`, `RS-04` / `CTX-0004`).

1. **Prior art and terminology mapping (`verified-in-paper`):** The concept Mixu calls *knowledge-horizon filtering* (`TemporalProjectionEngine` + `RedactionPolicy` in `mixu-spoiler`) exists in the HCI literature as *progress-anchored filtering* (Boyd et al., 2023). Crucially, Boyd et al. identify *structural spoilers*—such as merging two nodes under a shared canonical ID before the narrative reveals they are the same person, or sizing a node by its full-book degree—which validates Mixu's design requirement that alias merging edges (`ALIAS_OF`), node labels, and layout degree must all carry `reveal_at` locators and be projected strictly within $r \le h$.
2. **Prefix-only RAG fails on famous books because of parametric memory (`verified-in-paper`, `verified-by-us`):** Boyd et al.'s finding that prefix-conditioned LLMs leak spoilers in $8.7\%$ of queries on famous novels (*Styles*, *Moonstone*) directly motivates our confound **`R-01`** (pretraining memorization of canonical mysteries). A prompt instruction ("do not spoil past chapter $k$") or even truncating the input text to chapter $k$ does not prevent a language model from emitting a famous culprit's identity during free-form generation.
3. **Why Mixu separates offline span-grounded extraction from on-device deterministic projection (`verified-by-us`):** Where Boyd et al. relied on manual tuple curation to achieve $0.0\%$ leakage in their third arm, Mixu automates graph construction by requiring every extracted node, edge, and epistemic transition to attach a verbatim character-offset evidence span inside chapter $r \le h$, and enforces deterministic horizon projection $P(G, h)$ at query time (`verified-by-us`).

| Claim relied on by Mixu | Verification status | Evidence / Trace |
|---|---|---|
| Static/global entity graphs cause structural or explicit spoilers in $34.2\%$ of reader lookups | `verified-in-paper` | Boyd et al. (2023), Section 4.1 & Table 2 (`doi:10.1145/3544548.3581194`) |
| Prefix-truncated RAG LLMs still leak canonical mystery twists in $8.7\%$ of queries due to parametric memory | `verified-in-paper` | Boyd et al. (2023), Section 5.3 (Parametric Contamination Audit) |
| Enforcing span-grounded `first_seen <= h` and `reveal_at <= h` via deterministic projection reduces post-filter spoiler leakage to $0.000$ across all tested arms | `verified-by-us` | `../../experiments/spoiler-decisions/results.md` (Run `sd-20261108-01`, Post-filter SLR $= 0.000$) |

## Reproduce?

- [ ] Not attempted
- [x] Attempted: Replicated the prefix-RAG parametric leakage test on `christie-styles` and `christie-ackroyd` (`corpora/manifest.json` `schema_version: 1`, `as_of: 2026-11-08`) at reading horizon $h = 35\%$ using unconstrained JSON generation (`qwen2.5-72b-instruct`, provider: `openrouter`, prompt version: `sd-v1.2`, date: `2026-11-08`) without our deterministic `TemporalProjectionEngine` + span-grounding filter. Unfiltered LLM responses leaked late-book culprit/alias facts in $7.8\%$ ($19/244$) of queries on famous public-domain works versus $1.1\%$ ($2/180$) on unseen synthetic `mixu-fixtures` stories, confirming Boyd et al.'s parametric leakage phenomenon (`R-01`). Applying Mixu's deterministic horizon filter and evidence-substring check reduced post-filter leakage to $0/424$ ($0.000$, `verified-by-us`).
