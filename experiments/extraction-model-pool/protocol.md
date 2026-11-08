# Extraction Model-Pool Benchmark Protocol

**Question:** Which candidate extraction model and context-window strategy achieves an overall relation/edge Macro-$F_1 \ge 0.800$, mid-book ($30\%\text{–}70\%$ depth) edge Macro-$F_1 \ge 0.780$, and retry-adjusted total cost $\le \$0.50$ per accepted 24-chapter novel graph without emitting ungrounded evidence spans or cross-chapter horizon violations?

## Arms

Every neural extraction arm emits candidate graph deltas conforming to the `mixu-contracts` Graph Pack schema (`nodes`, `edges`, `epistemic_transitions`, and character-offset `evidence_span` locators). If a candidate payload fails JSON Schema validation or verbatim substring verification against the source chapter text, the worker harness issues up to $K_{\max} = 3$ corrective retry prompts before rejecting the window.

| Arm | Role in pool | Model ID | Provider | Context window strategy |
|---|---|---|---|---|
| **Arm E0** | Deterministic Floor | `regex-coref-floor-v1` | `local-cpu` | Chapter-chunked ($4\text{k–}8\text{k}$ tokens); rule-based dialogue attribution + apposition NER. |
| **Arm E1** | Cheap Default Candidate | `qwen2.5-14b-instruct` | `local-vllm` (`bf16`) | Chapter-chunked ($4\text{k–}8\text{k}$ tokens) + compact horizon entity registry ($\le 1.5\text{k}$ tokens). |
| **Arm E2** | Structured-Output Reference | `qwen2.5-72b-instruct` | `openrouter` (`fp8`) | Chapter-chunked ($4\text{k–}8\text{k}$ tokens) + compact horizon entity registry ($\le 1.5\text{k}$ tokens). |
| **Arm E3** | Chinese & Reasoning Specialist | `deepseek-v3-0324` | `openrouter` (`fp8`) | Chapter-chunked ($4\text{k–}8\text{k}$ tokens) + compact horizon entity registry ($\le 1.5\text{k}$ tokens). |
| **Arm E4** | Long-Context Single-Pass Arm | `qwen2.5-72b-instruct-128k` | `openrouter` (`fp8`) | Whole-book single pass ($64\text{k–}128\text{k}$ tokens) requesting chapter-indexed graph deltas in one generation. |

## Data

- **Corpus slice:** $W = 150$ chapter windows drawn from 5 public-domain mystery works in `corpora/manifest.json` (`schema_version: 1`, `as_of: 2026-11-08`: `poe-rue-morgue`, `leroux-yellow-room`, `doyle-study-in-scarlet`, `christie-styles`, `christie-ackroyd`; 120 chapter windows) and 3 synthetic mystery packs in `mixu-fixtures@v0.1.0` (`zh-Hans`, `en`, `ja`; 30 chapter windows). Full inventory and depth buckets are specified in [data.md](data.md).

## Metrics

### 1. Retry-Adjusted Cost per Accepted Graph (Primary Operational Metric)

Raw per-token API pricing is misleading when a cheap model frequently fails schema or substring validation and consumes 2–3 full-context retry turns. Let $C_{\text{raw}}(w, t)$ be the token cost of attempt $t \in \{1..T_w\}$ on chapter window $w$, and let $A_{\text{accepted}}$ be the number of chapter windows that pass all deterministic validation gates within $K_{\max} = 3$ attempts:

$$\text{Cost per Accepted Chapter} = \frac{\sum_{w=1}^{W} \sum_{t=1}^{T_w} C_{\text{raw}}(w, t)}{A_{\text{accepted}}}$$

$$\text{Cost per Accepted Novel Graph (24-ch eq.)} = 24 \times \text{Cost per Accepted Chapter}$$

### 2. Entity Canonicalization $F_1$ and Edge/Relation Macro-$F_1$

- **Entity $F_1$:** B-cubed ($B^3$) cluster precision, recall, and $F_1$ over character, location, and physical-clue nodes visible up to chapter $r$, penalizing both premature alias merges ($r_{\text{reveal}} > r$) and duplicate unlinked surface mentions.
- **Edge Macro-$F_1$ (Overall and Mid-Book $30\%\text{–}70\%$ Depth):** Precision, recall, and Macro-$F_1$ across typed narrative edges (`ALIBI_AT`, `SUSPECTS`, `MOTIVE_AGAINST`, `POSSESSES_CLUE`, `CONTRADICTS`, `ALIAS_OF`) matched by `(source_id, target_id, edge_type, chapter_index)`. Per [liu-2024-long-context-extraction-decay.md](../../papers/literature/liu-2024-long-context-extraction-decay.md), we report mid-book depth ($30\%\text{–}70\%$ of chapter progression) separately to detect long-context interior decay.

### 3. First-Pass Acceptance Rate and Failure Taxonomy

Every rejected generation attempt (and every post-acceptance audit defect against gold annotations) is classified into five mutually exclusive failure categories:

| Failure code | Gate type | Definition |
|---|---|---|
| `SCHEMA_INVALID` | Hard validator gate (triggers retry) | Output is malformed JSON, violates `mixu-contracts` JSON Schema types/enums, or references an undeclared node ID in an edge. |
| `EVIDENCE_NOT_SUBSTRING` | Hard validator gate (triggers retry) | The quoted `evidence_span.quote` or character offset `[start_char, end_char)` is not an exact verbatim substring of chapter $r$ (paraphrased, elided with `...`, or hallucinated). |
| `HORIZON_VIOLATION` | Hard validator gate (triggers retry/drop) | An extracted node or edge in chapter $r$ cites evidence from chapter $r' > r$ or merges an alias whose ground-truth disclosure occurs at $r_{\text{reveal}} > r$. |
| `OVER_EXTRACTION` | Gold audit error (precision penalty) | Model extracts transient background nouns (unnamed cabmen, dining room chairs, passing weather) as persistent case-board nodes (`degree = 1` noise). |
| `WRONG_EPISTEMIC_LABEL` | Gold audit error (epistemic penalty) | Structurally valid edge with grounded substring, but misclassified epistemic tier (e.g., labelling a suspect's self-serving alibi as `OBSERVED` instead of `CLAIMED`). |

## Decision rule

Defined before executing the benchmark (`emp-20261108-01`):

1. **Adopt** a model + context strategy into the `mixu-ai-worker` routing pool (`ADR-034`) if:
   - Overall Edge Macro-$F_1 \ge 0.800$ and Mid-Book ($30\%\text{–}70\%$) Edge Macro-$F_1 \ge 0.780$
   - First-pass deterministic gate acceptance rate $\ge 88.0\%$ (final acceptance after $\le 3$ retries $\ge 98.0\%$)
   - `EVIDENCE_NOT_SUBSTRING` rate on first pass $\le 5.0\%$
   - Post-validator `HORIZON_VIOLATION` rate $= 0.0\%$
   - Retry-adjusted cost per accepted 24-chapter novel graph $\le \$0.50$
2. **Reject** any model or context strategy with Mid-Book Edge Macro-$F_1 < 0.700$, `EVIDENCE_NOT_SUBSTRING` $> 10.0\%$, or retry-adjusted cost $> \$0.80$ per accepted novel graph.
3. **Revisit** if a model achieves high quality on one language (`zh-Hans` or `en`) but misses the cost or schema stability threshold on another, motivating language-routed specialization.

## Known confounds

- **Prompt formatting sensitivity:** Smaller instruction models (`14B`) degrade sharply when JSON Schema constraints are injected only in the system prompt rather than reinforced via constrained decoding (`guided_json`). To isolate intrinsic model grounding ability from decoding middleware, all arms use identical system/user prompt templates (`emp-v1.0`) with standard JSON mode before testing grammar-constrained decoding in a follow-up experiment.
- **Chapter length variance:** Chapters range from $1{,}850$ tokens (`christie-styles` short dialogue chapters) to $7{,}600$ tokens (`poe-rue-morgue` continuous analytical segments).
