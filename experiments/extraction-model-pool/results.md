# Extraction Model-Pool Benchmark Results

## Reproducibility metadata

| Field | Value |
|---|---|
| **Run ID** | `emp-20261108-01` |
| **Execution date** | `2026-11-08` |
| **Protocol version** | `experiments/extraction-model-pool/protocol.md` (`v1.0`) |
| **Prompt version** | `emp-v1.0` (`mixu-contracts` graph-pack JSON schema + verbatim substring rubric) |
| **Corpus version** | `corpora/manifest.json` (`schema_version: 1`, `as_of: 2026-11-08`) + `mixu-fixtures@v0.1.0` ($W = 150$ chapter windows, $1{,}354$ gold edges) |
| **Candidate models & providers** | Arm E0: `regex-coref-floor-v1` (`local-cpu`); Arm E1: `qwen2.5-14b-instruct` (`local-vllm`, `bf16`); Arm E2: `qwen2.5-72b-instruct` (`openrouter`, `fp8`); Arm E3: `deepseek-v3-0324` (`openrouter`, `fp8`); Arm E4: `qwen2.5-72b-instruct-128k` (`openrouter`, `fp8`, single-pass whole-book) |
| **Reproduction command** | `./experiments/extraction-model-pool/run.sh` |

## Primary results: quality and retry-adjusted cost per accepted graph ($W = 150$)

Rather than quoting raw price per $1\text{M}$ tokens, the table below reports **total retry-adjusted cost per accepted chapter graph** and **per 24-chapter novel graph**, including all wasted tokens from failed validation attempts (up to $K_{\max} = 3$ retries when `SCHEMA_INVALID`, `EVIDENCE_NOT_SUBSTRING`, or `HORIZON_VIOLATION` fires).

| Arm | Model ID (`Provider`) | Window strategy | First-pass accepted (%) | Final accepted $\le 3$ tries (%) | Mean attempts / window | Entity $B^3$ $F_1$ | Overall Edge Macro-$F_1$ | Mid-Book ($30\text{–}70\%$) Edge $F_1$ | Raw price (in / out per 1M) | Retry-adj. cost / accepted ch. | Retry-adj. cost / accepted novel (24 ch) | Verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **Arm E0** | `regex-coref-floor-v1` (`local-cpu`) | Chapter ($4\text{–}8\text{k}$) | `100.0%` (150/150) | `100.0%` (150/150) | `1.00` | `0.642` | `0.518` | `0.504` | `$0.00` / `$0.00` | `$0.0000` | `$0.00` | Floor baseline |
| **Arm E1** | `qwen2.5-14b-instruct` (`local-vllm`) | Chapter ($4\text{–}8\text{k}$) | `74.0%` (111/150) | `94.0%` (141/150) | `1.39` | `0.798` | `0.734` | `0.721` | `$0.08` / `$0.24` (GPU eq.) | `$0.0068` | `$0.16` | **Reject** (Edge $F_1 = 0.734 < 0.800$; $6.0\%$ unrecovered window drops) |
| **Arm E2** | `qwen2.5-72b-instruct` (`openrouter`) | Chapter ($4\text{–}8\text{k}$) | **`92.0%`** (138/150) | **`100.0%`** (150/150) | **`1.09`** | **`0.884`** | **`0.824`** | **`0.812`** | `$0.35` / `$0.40` | **`$0.0183`** | **`$0.44`** | **Adopt (`en` / `ja` Default)** |
| **Arm E3** | `deepseek-v3-0324` (`openrouter`) | Chapter ($4\text{–}8\text{k}$) | **`93.3%`** (140/150) | **`100.0%`** (150/150) | **`1.07`** | **`0.896`** | **`0.841`** | **`0.833`** | `$0.27` / `$1.10` | **`$0.0192`** | **`$0.46`** | **Adopt (`zh-Hans` & Complex Deductive Primary)** |
| **Arm E4** | `qwen2.5-72b-instruct-128k` (`openrouter`) | Whole-book single pass ($64\text{–}128\text{k}$) | `46.7%` (70/150 eq.) | `86.0%` (129/150 eq.) | `1.88` | `0.791` | `0.689` | `0.618` | `$0.35` / `$0.40` | `$0.0400` | **`$0.96`** (`2.18x` vs E2) | **Reject** (Mid-book $F_1$ collapses by `-0.194`; retry cost `2.18x`) |

## Failure taxonomy breakdown ($W = 150$ chapter windows)

Hard validator failures (`SCHEMA_INVALID`, `EVIDENCE_NOT_SUBSTRING`, `HORIZON_VIOLATION`) are measured on the **first-pass generation** across all $W = 150$ windows before retry filtering; audit errors (`OVER_EXTRACTION`, `WRONG_EPISTEMIC_LABEL`) are measured as a percentage of total extracted candidate edges in the accepted output graphs.

| Arm | `SCHEMA_INVALID` (1st pass windows) | `EVIDENCE_NOT_SUBSTRING` (1st pass windows) | `HORIZON_VIOLATION` (1st pass edges) | `OVER_EXTRACTION` (% of emitted nodes) | `WRONG_EPISTEMIC_LABEL` (% of matched edges) | Post-validator `HORIZON_VIOLATION` |
|---|---|---|---|---|---|---|
| **Arm E0** (`regex-coref-floor-v1`) | `0 / 150` (`0.0%`) | `0 / 150` (`0.0%`) | `0.0%` | `24.6%` (noun-phrase noise) | `28.4%` (defaults to `OBSERVED`) | `0.0%` |
| **Arm E1** (`qwen2.5-14b-instruct`, ch.) | `14 / 150` (`9.3%`) | `22 / 150` (`14.7%`) | `1.8%` | `14.2%` | `13.9%` | `0.0%` |
| **Arm E2** (`qwen2.5-72b-instruct`, ch.) | `5 / 150` (`3.3%`) | **`5 / 150` (`3.3%`, `3.1%` of spans)** | `0.9%` | `6.8%` | `8.4%` | **`0.0%`** |
| **Arm E3** (`deepseek-v3-0324`, ch.) | **`4 / 150` (`2.7%`)** | **`4 / 150` (`2.7%`, `2.5%` of spans)** | **`0.6%`** | **`5.4%`** | **`6.9%`** | **`0.0%`** |
| **Arm E4** (`qwen2.5-72b-instruct-128k`, single-pass) | `29 / 150` (`19.3%`) | **`38 / 150` (`25.3%`, `14.8%` of spans)** | **`6.4%`** | `11.5%` | `15.2%` | **`0.0%`** (21 windows dropped after 3 failed retries) |

## Language-stratified Edge Macro-$F_1$ (`en`, `zh-Hans`, `ja`)

| Language slice | Windows ($W$) | Arm E1 (`qwen2.5-14b`) | Arm E2 (`qwen2.5-72b`, ch.) | Arm E3 (`deepseek-v3-0324`, ch.) | Arm E4 (`qwen2.5-72b-128k`, single-pass) | Key linguistic differentiator |
|---|---|---|---|---|---|---|
| English (`en`: 5 classics + `fixtures-en-clockwork`) | 130 | `0.738` | `0.827` | `0.839` | `0.692` | E2 and E3 perform within `0.012` $F_1$; E2 has $28\%$ lower output token price for verbose English quotes. |
| Simplified Chinese (`zh-Hans`: `fixtures-zh-pavilion`) | 10 | `0.741` | `0.816` | **`0.854`** (`+0.038` vs E2) | `0.674` | E3 accurately segments classical four-character idioms and zero-pronoun multi-turn interrogations where E2 drops subject links. |
| Japanese (`ja`: `fixtures-ja-snow-inn`) | 10 | `0.675` | `0.793` | **`0.854`** | `0.665` | Honorific-implied speaker transitions (`敬語` subject omission) cause E1 to misattribute alibi claims. |

## Negative findings (what failed and why)

1. **Long-context 128k single-pass extraction fails on both accuracy (`-0.194` mid-book $F_1$) and cost (`2.18x` higher):**
   Replicating [liu-2024-long-context-extraction-decay.md](../../papers/literature/liu-2024-long-context-extraction-decay.md), feeding an entire novel ($55\text{k–}95\text{k}$ tokens) into `qwen2.5-72b-instruct-128k` (Arm E4) caused mid-book ($30\%\text{–}70\%$ depth) edge recall to collapse from $0.831$ (Arm E2 chapter-chunked) to $0.584$ (a $34.6\%$ loss of planted mid-novel clues and alibis), pulling mid-book Edge Macro-$F_1$ down from $0.812$ to $0.618$ ($\Delta F_1 = -0.194$). Worse, at $>64\text{k}$ context length the model frequently paraphrased evidence quotes instead of copying exact substrings (`EVIDENCE_NOT_SUBSTRING` rose from $3.1\%$ of spans to $14.8\%$, affecting $25.3\%$ of chapter windows) and back-projected late-book culprit identities onto early chapters (`HORIZON_VIOLATION` $= 6.4\%$ of extracted edges). Because failed windows required costly full-context retries, Arm E4's effective cost per accepted novel graph reached $\$0.96$—**$2.18\times$ more expensive** than chapter-chunked Arm E2 ($\$0.44$).
2. **Cheap `14B` extraction suffers severe retry inflation and silent quote normalization:**
   In Arm E1 (`qwen2.5-14b-instruct`), $26.0\%$ of first-pass chapter windows failed deterministic validation ($9.3\%$ `SCHEMA_INVALID` from dangling entity references; $14.7\%$ `EVIDENCE_NOT_SUBSTRING` from silently normalizing British punctuation, archaic spellings like `clew` $\to$ `clue`, or inserting `...` inside quotes). Even after 3 retries, $6.0\%$ ($9/150$) of chapter windows failed to produce a valid graph delta.
3. **Salience over-extraction (`OVER_EXTRACTION` $= 5.4\%\text{–}14.2\%$):**
   Without a two-pass salience filter or degree-thresholding rule, every LLM arm extracted minor props (e.g., "the brandy decanter", "the morning post") as standalone `CLUE` nodes upon their first mention, even when the narrative never referenced them again. In `mixu-ai-worker`, this requires a post-extraction staging rule: physical objects remain candidate mentions until referenced by $\ge 2$ distinct paragraphs or linked by an investigative edge (`POSSESSES_CLUE`, `CONTRADICTS`).

## What we cannot conclude

1. **We cannot conclude that `qwen2.5-14b-instruct` is unusable with grammar-constrained decoding (`FSM / guided_json`) and LoRA fine-tuning:** Our benchmark tested zero-shot/few-shot prompting under standard JSON mode (`emp-v1.0`). Enforcing a strict finite-state grammar during token sampling would eliminate `SCHEMA_INVALID` ($9.3\%$) mechanically, though it would not by itself fix `EVIDENCE_NOT_SUBSTRING` ($14.7\%$) or mid-chapter coreference misses without span-pointer training.
2. **We cannot extrapolate `zh-Hans` and `ja` novel-scale entity drift beyond 10-chapter novellas:** While `corpora/manifest.json` provides 28-chapter English mysteries, our `zh-Hans` and `ja` slices in `mixu-fixtures@v0.1.0` span 10 chapters each ($28\text{k–}29\text{k}$ tokens). Whether `deepseek-v3-0324` maintains $B^3$ Entity $F_1 \ge 0.880$ across a 60-chapter Chinese web-mystery serial with $120+$ named characters remains open until a longer rights-cleared Chinese corpus is onboarded.
3. **We cannot equate span-grounded extraction $F_1$ with end-reader mystery comprehension:** Higher edge $F_1$ proves that the extracted graph faithfully mirrors our gold narrative annotations; proving that readers solve or track mysteries more effectively with those graphs requires a human-subjects reading study (scoped separately from this automated benchmark).

## Verdict

- **Adopt chapter-chunked extraction ($4\text{k–}8\text{k}$ tokens + $\le 1.5\text{k}$ horizon entity registry) as a hard architectural invariant in `ADR-034`**; reject whole-book single-pass $128\text{k}$ extraction (Arm E4).
- **Adopt a dual-model pool for `mixu-ai-worker` (`ADR-034`):** route `zh-Hans`, `ja`, and multi-hop deductive synthesis chapters to `deepseek-v3-0324` (Arm E3, Edge Macro-$F_1 = 0.841$, $\$0.46\text{/novel}$) and standard `en` chapters to `qwen2.5-72b-instruct` (Arm E2, Edge Macro-$F_1 = 0.824$, $\$0.44\text{/novel}$).
