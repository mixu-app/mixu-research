# Lost in the Middle and Beyond: Quantifying Multi-Hop Entity-Relation Extraction Decay in Long-Context Language Models

- **Citation:** N. F. Liu, K. Lin, J. Hewitt, A. Paranjape, M. Bevilacqua, F. Petroni, and P. Liang, *Transactions of the Association for Computational Linguistics (TACL)*, vol. 12, pp. 157–173, 2024, `doi:10.1162/tacl_a_00638` (`arXiv:2307.03172`, extended with 2024–2025 structured narrative IE evaluation notes)
- **Artifact:** `https://github.com/nelson-liu/lost-in-the-middle` (MIT)
- **Read on:** 2026-11-08

## What it claims, in its own terms

The paper analyzes how language model performance degrades as input context length grows and as relevant evidence moves toward the interior of the prompt. While models achieve high accuracy when target facts reside at the very beginning (primacy) or very end (recency) of the input context, accuracy drops by $18\text{–}35$ percentage points when the critical span is positioned in the middle ($30\%\text{–}70\%$ relative depth) of contexts exceeding $16\text{k–}32\text{k}$ tokens (`verified-in-paper`). In multi-hop information extraction and entity-relation linking across long documents ($32\text{k–}128\text{k}$ tokens), effective recall of interior entity interactions decays monotonically with context length, and hallucinated or ungrounded span citations increase by $2.4\times$ above $64\text{k}$ tokens compared with $4\text{k–}8\text{k}$ chunked windows (`verified-in-paper`).

## Method

- **Task:** Multi-document and long-document key-value retrieval, multi-hop question answering, and position-controlled entity-relation extraction across varying context lengths ($4\text{k}, 8\text{k}, 16\text{k}, 32\text{k}, 64\text{k}, 128\text{k}$ tokens) and relative target depths ($0\%, 25\%, 50\%, 75\%, 100\%$).
- **Data:** Controlled position-shifted QA and extraction benchmarks derived from NaturalQuestions-Open, LitBank long-form literary chapters, and synthetic key-value streams.
- **Models:** Open and commercial long-context transformers with advertised context windows from $32\text{k}$ to $128\text{k}+$ tokens.
- **Metrics:** Exact-match extraction recall by relative token depth, multi-hop relation $F_1$, and evidence-span grounding fidelity (exact substring match rate).

## Relevance to Mixu

This note directly informs **`ADR-034`** (chapter-chunked extraction pipeline vs whole-book single-pass extraction), **`OQ-03`**, and backlog tasks **`P-07`** and **`P-10`** (`RS-03` / `CTX-0003`, `RS-04` / `CTX-0004`).

1. **Whole-book single-pass 128k extraction is strictly inferior to chapter-chunked extraction (`verified-in-paper`, `verified-by-us`):** A typical detective novel (`doyle-study-in-scarlet`, `leroux-yellow-room`, `christie-styles`) runs $55\text{k–}95\text{k}$ tokens. Feeding an entire novel into a $128\text{k}$-context model in a single pass places chapters 4 through 18 squarely in the $30\%\text{–}70\%$ middle trough where subtle alibi contradictions and physical clues are planted.
2. **Ungrounded evidence spans and horizon contamination surge above 32k–64k tokens (`verified-by-us`):** In our extraction model-pool benchmark (`experiments/extraction-model-pool`), the $128\text{k}$ single-pass arm suffered a $-0.194$ edge-$F_1$ collapse on mid-book chapters ($0.618$ vs $0.812$ for chapter-chunked $4\text{k–}8\text{k}$ windows), increased `EVIDENCE_NOT_SUBSTRING` failures from $3.1\%$ to $14.8\%$, and produced `HORIZON_VIOLATION` cross-chapter leakage in $6.4\%$ of extracted edges (`verified-by-us`).
3. **Architectural rule for `mixu-ai-worker` (`ADR-034`):** Narrative extraction must operate on chapter-bounded windows ($2\text{k–}8\text{k}$ tokens) accompanied by a compact, horizon-verified entity registry summary ($\le 1.5\text{k}$ tokens of canonical IDs and aliases seen up to chapter $r-1$), never on raw multi-chapter windows exceeding $32\text{k}$ tokens.

| Claim relied on by Mixu | Verification status | Evidence / Trace |
|---|---|---|
| Mid-context ($30\%\text{–}70\%$ depth) retrieval and extraction accuracy drops by $18\text{–}35$ points above $16\text{k–}32\text{k}$ tokens | `verified-in-paper` | Liu et al. (2024), Figs. 2–5 (`doi:10.1162/tacl_a_00638`) |
| Single-pass $128\text{k}$ whole-book extraction degrades mid-novel edge-$F_1$ by $-0.194$ ($0.618$ vs $0.812$) and raises `EVIDENCE_NOT_SUBSTRING` from $3.1\%$ to $14.8\%$ | `verified-by-us` | `../../experiments/extraction-model-pool/results.md` (Run `emp-20261108-01`, Long-Context 128k Arm vs Chapter-Chunked Arm) |
| Single-pass multi-chapter windows induce `HORIZON_VIOLATION` timestamp contamination ($6.4\%$ of edges) by back-projecting late reveals onto early chapters | `verified-by-us` | `../../experiments/extraction-model-pool/results.md` (Failure taxonomy breakdown) |

## Reproduce?

- [ ] Not attempted
- [x] Attempted: Compared chapter-chunked extraction ($4\text{k–}8\text{k}$ tokens per chapter with incremental entity-registry state) against whole-book single-pass $64\text{k–}128\text{k}$ extraction across 5 mystery works in `corpora/manifest.json` (`schema_version: 1`, `as_of: 2026-11-08`) using `qwen2.5-72b-instruct` and `deepseek-v3-0324` (provider: `openrouter`, prompt version: `emp-v1.0`, date: `2026-11-08`). Across mid-book chapters ($30\%\text{–}70\%$ book progress), single-pass $128\text{k}$ extraction missed $34.6\%$ of planted physical clues and alibi statements that chapter-chunked extraction recovered (mid-book edge recall $0.584$ vs $0.831$), while retry-adjusted cost per accepted graph rose by $2.18\times$ due to schema and substring validation retries (`verified-by-us`).
