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

## Live 30-Book Public-Domain Gutenberg Mystery Corpus Validation (`deepseek/deepseek-v4.1-flash-1017`, `2026-11-08`)

To verify end-to-end EPUB parsing, offset-preserving normalization, `Locator` round-tripping, and horizon-bounded extraction across the full public-domain research corpus (`corpora/manifest.json`: $32$ US public-domain mystery works across $30$ distinct Project Gutenberg EPUB editions, fetched via `./tools/fetch_corpus.py`), we executed `105` live extraction calls on OpenRouter using `deepseek/deepseek-v4.1-flash-1017` (`reasoning: {"enabled": false}`, `response_format: {"type": "json_object"}`, `max_tokens: 1600`, `temperature: 0.0`):

- **Corpus Scale**: $30$ distinct Project Gutenberg EPUB editions ($32$ works), $665$ spine documents, $241{,}171$ narrative segments, $14{,}175{,}323$ normalized characters (including full-length Victorian and Golden Age detective novels up to $1.36\text{M}$ characters).
- **Locator Round-Trip Accuracy**: `150 / 150` (`100.00%`) across 5 stratified checkpoints ($0\%, 25\%, 50\%, 75\%, 100\%$) per EPUB edition.
- **First-Pass Extraction Call Completion**: `105 / 105` (`100.00%`, `0` retries required) across `3` narrative horizons ($15\%, 50\%, 85\%$) per book plus `5` consecutive mid-novel segments on each of the `3` longest novels (*The Woman in White*, *The Moonstone*, *Monsieur Lecoq*).
- **Accepted Grounded Records**: `405` accepted evidence-anchored records (`165` entities, `171` assertions, `1` transition, `68` events), `60` candidates filtered by deterministic substring grounding (`UNGROUNDED_EVIDENCE_SPAN`), and **`0` post-validator `HORIZON_VIOLATION`s**.
- **Latency & Cost**: Mean latency `2,166.33 ms` (`29.04 s` wall time at 8-worker concurrency), `41,926` prompt tokens, `27,624` completion tokens, **`$0.013923` total billed cost** (`$0.000133` per segment).

| Work ID | Title (Published) | Lang | PG ID | Chars | Spines | Segments | Calls (`OK`) | Entities | Assertions | Events | Rejections | Mean Latency (ms) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `collins-woman-in-white` | *The Woman in White* (1859) | `en` | `583` | `1,364,852` | `26` | `21,113` | `8 / 8` | `15` | `16` | `7` | `9` | `2611.3` |
| `collins-moonstone` | *The Moonstone* (1868) | `en` | `155` | `1,087,483` | `51` | `16,854` | `8 / 8` | `10` | `13` | `6` | `7` | `2190.6` |
| `gaboriau-lerouge` | *Monsieur Lecoq* (1869) | `en` | `3803` | `836,213` | `21` | `14,282` | `8 / 8` | `13` | `12` | `4` | `2` | `1826.4` |
| `green-leavenworth` | *The Leavenworth Case* (1878) | `en` | `4047` | `626,752` | `47` | `10,690` | `3 / 3` | `9` | `10` | `2` | `2` | `2540.4` |
| `doyle-return` | *The Return of Sherlock Holmes* (1905) | `en` | `108` | `625,013` | `16` | `10,032` | `3 / 3` | `4` | `6` | `3` | `2` | `2055.7` |
| `doyle-adventures` | *The Adventures of Sherlock Holmes* (1892) | `en` | `1661` | `578,200` | `15` | `9,295` | `3 / 3` | `6` | `5` | `3` | `5` | `2505.1` |
| `poe-rue-morgue` (+2) | *The Murders in the Rue Morgue* et al. (1841) | `en` | `2148` | `565,331` | `25` | `8,582` | `3 / 3` | `5` | `4` | `2` | `0` | `2982.4` |
| `doyle-memoirs` | *The Memoirs of Sherlock Holmes* (1894) | `en` | `834` | `531,499` | `14` | `8,043` | `3 / 3` | `6` | `3` | `2` | `1` | `2103.7` |
| `hume-hansom-cab` | *The Mystery of a Hansom Cab* (1886) | `en` | `4223` | `505,940` | `13` | `8,581` | `3 / 3` | `6` | `5` | `4` | `0` | `2072.7` |
| `chesterton-innocence` | *The Innocence of Father Brown* (1911) | `en` | `204` | `457,311` | `14` | `7,051` | `3 / 3` | `4` | `3` | `0` | `0` | `1927.1` |
| `christie-secret-adversary` | *The Secret Adversary* (1922) | `en` | `1155` | `440,887` | `33` | `8,055` | `3 / 3` | `3` | `4` | `2` | `0` | `1656.6` |
| `leblanc-crystal-stopper` | *The Crystal Stopper* (1912) | `en` | `1563` | `437,107` | `23` | `7,760` | `3 / 3` | `5` | `5` | `2` | `1` | `1933.8` |
| `leroux-yellow-room` | *The Mystery of the Yellow Room* (1907) | `en` | `1685` | `435,813` | `35` | `7,485` | `3 / 3` | `4` | `3` | `2` | `0` | `2360.7` |
| `christie-man-in-brown-suit` | *The Man in the Brown Suit* (1924) | `en` | `61168` | `428,215` | `39` | `9,063` | `3 / 3` | `2` | `3` | `1` | `2` | `2041.8` |
| `chesterton-wisdom` | *The Wisdom of Father Brown* (1914) | `en` | `223` | `417,069` | `9` | `6,376` | `3 / 3` | `6` | `6` | `2` | `0` | `1789.9` |
| `christie-ackroyd` | *The Murder of Roger Ackroyd* (1926) | `en` | `69087` | `409,275` | `31` | `7,578` | `3 / 3` | `4` | `6` | `2` | `1` | `2091.7` |
| `rinehart-circular-staircase` | *The Circular Staircase* (1908) | `en` | `434` | `399,286` | `36` | `6,403` | `3 / 3` | `7` | `5` | `3` | `2` | `2299.6` |
| `christie-links` | *The Murder on the Links* (1923) | `en` | `58866` | `377,724` | `32` | `6,752` | `3 / 3` | `6` | `6` | `3` | `0` | `2484.9` |
| `milne-red-house` | *The Red House Mystery* (1922) | `en` | `1872` | `349,507` | `24` | `6,279` | `3 / 3` | `3` | `4` | `2` | `2` | `2065.4` |
| `sayers-whose-body` | *Whose Body?* (1923) | `en` | `58820` | `349,162` | `20` | `7,513` | `3 / 3` | `2` | `2` | `1` | `1` | `1475.8` |
| `doyle-his-last-bow` | *His Last Bow* (1917) | `en` | `2350` | `341,169` | `10` | `5,208` | `3 / 3` | `6` | `5` | `4` | `2` | `2700.9` |
| `christie-styles` | *The Mysterious Affair at Styles* (1920) | `en` | `863` | `336,797` | `15` | `6,191` | `3 / 3` | `4` | `6` | `3` | `3` | `2805.3` |
| `doyle-hound` | *The Hound of the Baskervilles* (1902) | `en` | `2852` | `335,838` | `19` | `5,493` | `3 / 3` | `5` | `5` | `1` | `1` | `1795.2` |
| `doyle-valley-of-fear` | *The Valley of Fear* (1915) | `en` | `3289` | `330,867` | `19` | `5,141` | `3 / 3` | `4` | `5` | `1` | `3` | `2024.9` |
| `christie-big-four` | *The Big Four* (1927) | `en` | `70114` | `324,556` | `21` | `5,701` | `3 / 3` | `4` | `5` | `2` | `5` | `1986.7` |
| `christie-poirot-investigates` | *Poirot Investigates* (1924) | `en` | `61262` | `312,795` | `9` | `7,646` | `3 / 3` | `6` | `3` | `0` | `2` | `1746.9` |
| `doyle-study-in-scarlet` | *A Study in Scarlet* (1887) | `en` | `244` | `257,396` | `18` | `3,823` | `3 / 3` | `3` | `5` | `2` | `1` | `1862.0` |
| `doyle-sign-of-four` | *The Sign of the Four* (1890) | `en` | `2097` | `250,063` | `15` | `3,873` | `3 / 3` | `4` | `6` | `2` | `1` | `2229.0` |
| `leblanc-lupin` | *Arsène Lupin* (1907) | `en` | `4013` | `236,189` | `5` | `3,942` | `3 / 3` | `6` | `6` | `0` | `4` | `2832.9` |
| `anon-digongan-zh` | *Di Gong An / 狄公案* (1800) | `zh-Hans` | `27686` | `227,014` | `10` | `6,366` | `3 / 3` | `3` | `4` | `0` | `1` | `1789.8` |
| **Total (`30` Editions / `32` Works)** | — | — | — | **`14,175,323`** | **`665`** | **`241,171`** | **`105 / 105` (`100%`)** | **`165`** | **`171`** | **`68`** | **`60`** | **`2166.3`** |

## Step-by-Step Temporal Graph Construction, Worked Examples, and 1M-Context Cost Optimization (`2026-11-11`)

### 1. How the Progress-Aware Temporal Knowledge Graph Grows Chapter by Chapter

Unlike a static, timeless knowledge graph that overwrites node attributes or merges aliases globally, Mixu stores a book's narrative graph as an **append-only, chapter-indexed temporal event log** $G = (V, A, E, T)$. The graph is never destructively mutated when later chapters reveal new facts; instead, every node, alias link, relational assertion, and epistemic transition carries its disclosure chapter index $r \in \{0..K-1\}$, and `TemporalProjectionEngine.project(pack, horizon)` deterministically filters $G$ to the reader's current reading horizon $h$:

1. **New Entity Discovery (`firstSeenChapterIndex`):** When a character, persona, location, or physical clue first appears in chapter $r$, a node $v \in V$ is appended with `firstSeenChapterIndex = r`. If the reader is at chapter $h < r$, $v \notin V_h$ (the node is completely invisible).
2. **Delayed Alias & Persona Resolution (`IdentityLink` at `revealChapterIndex`):** If a mysterious figure (e.g., `"灰衣跛足人"`) appears in Chapter 1 (`r = 0`) and is unmasked as `"沈怀舟"` in Chapter 3 (`r = 2`), both surface personas remain separate nodes in $V$ for $h \in \{0, 1\}$, and are linked only when $h \ge r_{\text{reveal}} = 2$.
3. **Append-Only Epistemic State Transitions (`OBSERVED`, `CLAIMED`, `CORROBORATED`, `CONTRADICTED`, `INFERRED`):** A suspect's alibi claimed in Chapter 1 (`chapterIndex = 0`, `status = CLAIMED`) remains `CLAIMED` while the reader is in Chapter 1. When a physical clue in Chapter 2 (`chapterIndex = 1`) disproves that alibi, a new assertion/transition record anchored at `chapterIndex = 1` with `status = CONTRADICTED` is appended. Scrolling the horizon slider back from Chapter 2 to Chapter 1 immediately restores the `CLAIMED` view without any spoiler leakage.

#### Worked Example 1: Progressive 3-Chapter Mystery (*The Clocktower Fall / 钟楼坠落事件*)

| Reading Horizon $h$ | Narrative Disclosure in Chapter $h$ | Newly Appended Delta $\Delta G_h$ | Reader-Visible Projected Graph $P(G, h)$ |
|---|---|---|---|
| **Chapter 1 (`h = 0`)** | 22:00 钟楼发现馆长尸体(`OBSERVED`)；管家顾言声称 21:30–22:00 在书房整理账目(`CLAIMED`)；窗台发现半枚带泥脚印(`OBSERVED`)。 | $+V_0$: `馆长`, `顾言`, `钟楼`, `书房`, `带泥脚印` (`firstSeen=0`)<br>$+E_0$: `(顾言, 声称在场, 书房, CLAIMED, ch=0)`, `(钟楼, 发现物证, 带泥脚印, OBSERVED, ch=0)` | **5 nodes, 2 edges.** 顾言's alibi badge displays `[CLM]`; the culprit and the stopped pocket watch in Chapter 2 are completely absent (`SLR = 0.000`). |
| **Chapter 2 (`h = 1`)** | 侦探林澈在钟楼齿轮间搜出停在 21:42 的怀表(`OBSERVED`)，怀表内侧刻有顾言缩写，直接推翻顾言 21:30–22:00 一直在书房的证词(`CONTRADICTED`)。 | $+V_1$: `林澈`, `停在21:42的怀表` (`firstSeen=1`)<br>$+E_1$: `(林澈, 搜出物证, 停在21:42的怀表, OBSERVED, ch=1)`, `(停在21:42的怀表, 推翻不在场证明, 书房, CONTRADICTED, ch=1)` | **7 nodes, 4 edges.** 顾言's alibi is now visibly challenged by `[⚔ CONTRADICTED]` edge from `停在21:42的怀表`, while Chapter 3's accomplice identity remains hidden. |
| **Chapter 3 (`h = 2`)** | 林澈结合带泥脚印与怀表齿轮油渍，推理出顾言在 21:42 推下馆长(`INFERRED`)，并揭露“灰衣园丁”实为馆长失踪多年的弟弟沈怀舟(`CORROBORATED` / `SAME_PERSON_AS`)。 | $+V_2$: `沈怀舟` (`firstSeen=2`)<br>$+A_2$: `IdentityLink(灰衣园丁 == 沈怀舟, revealCh=2)`<br>$+E_2$: `(顾言, 推下致死, 馆长, INFERRED, ch=2)` | **Full 8-node, 5-edge graph** with resolved persona link and final `[INF]` deductive chain. |

### 2. Cost-Optimal Temporal Graph Architecture Under 1M-Context `83.3:1` Asymmetric Pricing

With `deepseek/deepseek-v4.1-flash-1017` supporting a **`1,048,576`-token (`1M`) context window** (`384k+` effective novel input capacity) and `943,718` max completion tokens, almost any short story, novella, or full-length mystery novel (`100k–250k` tokens) can fit inside the model's input window. However, OpenRouter's live token pricing exhibits an extreme **`83.3:1` output-to-input cost asymmetry**:

- **Prompt (Input) Price:** **`$0.006 / 1M` tokens** (`$0.005 / 1M` with prompt cache read) — feeding an entire `100,000`-token (`~160,000`-char) novel as input costs only **`$0.0006` (`0.06` cents)**.
- **Completion (Output) Price:** **`$0.50 / 1M` tokens** — every `1,000` generated output tokens cost **`$0.0005`**, which is **`83.3x` more expensive per token** than input.

Consequently, **minimizing redundant JSON output tokens while preserving strict chapter-level temporal coordinates `chapterIndex`** is the primary mathematical lever for cost optimization:

$$\text{Total Cost} = C_{\text{in}} \cdot N_{\text{in}} + C_{\text{out}} \cdot N_{\text{out}}, \quad \text{where } \frac{C_{\text{out}}}{C_{\text{in}}} = \frac{\$0.50}{\$0.006} = 83.33$$

| Architectural Strategy (`100k`-Token / `24`-Chapter Novel) | Input Tokens ($N_{\text{in}}$) | Output Tokens ($N_{\text{out}}$) | Input Cost | Output Cost | **Total Cost / Novel** | Temporal & Quality Verdict |
|---|---|---|---|---|---|---|
| **Strategy 1: Naive Cumulative Snapshot Re-Emission** (re-emitting full $G_{\le k}$ at each chapter $k=1..24$) | `240,000` (ch text + growing graph) | `~36,000` ($O(K^2)$ duplicate JSON nodes/edges) | `$0.0014` | **`$0.0180`** (`93%` of cost) | `$0.0194` (`~¥0.14`) | **Reject:** $O(K^2)$ output token explosion wastes `10x` completion budget re-printing old chapters' nodes. |
| **Strategy 2: Unstructured Whole-Book Single Dump** (no chapter delimiters, single timeless output) | `100,000` | `~2,000` | `$0.0006` | `$0.0010` | `$0.0016` (`~¥0.011`) | **Reject:** Loses chapter progression (`HORIZON_VIOLATION = 6.4%`) and suffers mid-book attention decay (`-0.194` $F_1$). |
| **Strategy 3A: Chapter-Delimited Temporal Delta Stream** (**Mixu Full-Context Batch Mode**, $\le 80$ chapters / $\le 180\text{k}$ chars) | `100,000` (`[Chapter c \| index=c]` delimited) | **`~2,200`** ($O(\|V\|+\|E\|+\|T\|)$ deduplicated delta stream) | `$0.0006` | **`$0.0011`** | **`$0.0017` (`~¥0.012`)** | **Adopt (Initial Book Import & Short Stories):** Each entity emitted once at `firstSeenChapterIndex`; each edge/transition tagged with disclosure `chapterIndex`. **`11.4x` cheaper** than Strategy 1. |
| **Strategy 3B: Incremental Chapter Delta + Compact Horizon Registry $\mathcal{R}_h$** (**Mixu Live Reading Extension**) | `~4,200 / ch` (`~3.5k` ch text + $\le 700$-tok ID registry $\mathcal{R}_{h-1}$) | **`~220 / ch`** (only new $\Delta G_h$ nodes & transitions) | `$0.000025 / ch` | **`$0.00011 / ch`** | **`$0.000135 / ch`** (`$0.0032` for 24 ch) | **Adopt (On-Demand Chapter Horizon Advance):** Highest mid-book recall (`0.833` Edge $F_1$) with zero duplicate output tokens. |

### 3. Live Production Verification After Lifting Legacy `take(16)` / `take(400)` Truncation (`2026-11-11`)

Prior to `CTX-0012` / `CTX-0036`, the client (`BookGraphPackLoader.kt`) and server (`OpenRouterGatewayClient.kt`) enforced a legacy prototype cap of `chapters.take(16)` and `excerpt.take(400)` (`400` characters per chapter). For a single-chapter short story (`chapters.size == 1`, `2,000–15,000` characters) or a long chapter where key physical clues appear after character `400`, `80%–95%` of the narrative was truncated before reaching the LLM.

We lifted these limits in both `mixu-client` and `mixu-server` (`PR #19` & `PR #46`, deployed live to `https://api.mixuread.com/v1/ai/graph/extract`):

- **Chapter Capacity:** Raised from `16` to **`80` chapters** per extraction request.
- **Per-Chapter & Total Character Budget:** Raised from `400` chars/chapter (`6,400` chars total) to **`48,000` chars/chapter** and **`160,000–180,000` chars total** (with stratified `Head (45%) + Middle (30%) + Tail (25%)` sampling only if an individual chapter exceeds `48,000` chars).
- **Completion Budget:** Raised `maxTokens` from `1,400` to **`2,800` tokens** (`45,000 ms` read timeout) with explicit instructions to emit a deduplicated temporal delta stream (`firstSeenChapterIndex` + per-assertion `chapterIndex` and epistemic status transitions).

#### Worked Example 2: Live Single-Chapter Short-Story Extraction (*The Red Brick Manor Locked-Room Poisoning / 红砖馆密室投毒事件*, `2,352` Chars)

We tested the live production endpoint `POST https://api.mixuread.com/v1/ai/graph/extract` with a `2,352`-character single-chapter mystery short story (`chapters.size = 1`, `chapterIndex = 0`) where the crime discovery occurs in characters `0..450`, the suspects' alibis occur in characters `451..1,200`, and the decisive forensic clues (`定时发声磁带机`, `怀表链金粉`, `氰化物安瓿瓶残片`) and final deduction occur in characters `1,201..2,352` (completely invisible under the old `take(400)` cap):

- **Live Execution Telemetry:** Completed in **`5.46 s`** (`offline_fallback: false`), extracting **`16` entities** (`PERSON`, `LOCATION`, `CLUE`) and **`17` grounded assertions** (`0` self-loops, `0` schema errors) at a billed cost of **`~$0.0009` (`¥0.0065`)**.
- **Full Epistemic Progression Captured Within a Single Short Story:**
  - `OBSERVED` (Crime Scene & Late-Text Forensic Clues): `陆沉舟 --[死于]--> 红砖馆三楼书房`, `书房门窗 --[反锁于]--> 红砖馆三楼书房`, `林澈 --[搜出物证]--> 氰化物安瓿瓶残片` (char `1,420`), `林澈 --[发现物证]--> 怀表链金粉` (char `1,580`), `林澈 --[搜出物证]--> 定时发声磁带机` (char `1,790`).
  - `CLAIMED` (Suspect Testimony): `周牧 --[声称在场]--> 地下酒窖` (`"周牧声称自己在21:15至21:50之间一直在地下酒窖清点年份红酒"`), `韩芸 --[听见]--> 21:45敲击木桶声`, `苏晚 --[声称返回]--> 二楼画室`.
  - `CORROBORATED` (Physical Verification): `定时发声磁带机 --[伪造]--> 21:45敲击木桶声` (`"磁带恰好在21:45自动播放敲击木桶的录音"`), `怀表链金粉 --[证实到访]--> 通风管道检修口`.
  - `CONTRADICTED` (Alibi Refutation): `定时发声磁带机 --[推翻不在场证明]--> 地下酒窖` (`"周牧声称21:45在酒窖敲桶的不在场证明被定时磁带机彻底推翻"`).
  - `INFERRED` (Final Deductive Chain at Char `2,150+`): `周牧 --[投毒杀害]--> 陆沉舟` (`"林澈推理出周牧利用通风管道投入氰化物安瓿瓶并用磁带机伪造不在场证明"`).

### 4. Multi-Scenario Extraction Strategy Selection & Entity-Starvation Guard (`2026-11-11`)

To select the optimal default extraction strategy across diverse book topologies (single-chapter short story `~21k` chars, giant single-spine novella `~84k` chars, 6-chapter locked-room mystery `~93k` chars, 11-chapter multi-witness mystery `~115k` chars, 32-chapter fragmented micro-spine mystery `~108k` chars, and 22-chapter full-length novel `~303k` chars), we benchmarked five extraction strategies on `deepseek/deepseek-v4.1-flash-1017`:

- **`S1-Legacy-400`**: Legacy `take(16)` chapters $\times$ `take(400)` chars (`6.4k` chars max).
- **`S2-Uncapped-SinglePass`**: Single-pass whole-book input (`175k` chars max, `max_tokens = 2800`) without entity count caps.
- **`S3-3Window-MultiCall`**: 3 sequential horizon windows with entity registry carryover (`3` API calls).
- **`S4A-Salience-SinglePass` (**Production Default**)**: Single-pass stratified digest (`96k–120k` total chars, `36k` max/chapter with `40% Head + 35% Mid + 25% Tail`) + **Entity-Starvation Guard** (`14–22` central mystery entities + `24–36` assertions distributed across `EARLY 0..30%`, `MIDDLE 30..70%`, and `LATE 70..100%` chapters, `max_tokens = 3200`).
- **`S4B-Adaptive-1or2Pass`**: Uses `S4A` (`1` call) for books $\le 100\text{k}$ chars and $\le 12$ chapters, and a **2-Pass Midpoint Horizon Split (`[0..K/2)` + `[K/2..K)`)** with Compact Entity Registry carryover ($\mathcal{R}_{h_{1/2}}$) for longer/fragmented novels (`2` calls).

| Book Topology Scenario | Strategy | API Calls | Core Entities (`\|V\|`) | Grounded Assertions (`\|E\|`) | Mid / Late Ch. Edges | Epistemic States (`of 5`) | Prompt / Comp. Tokens | **Billed Cost (USD)** | Wall Latency |
|---|---|---|---|---|---|---|---|---|---|
| **C1: Single-Ch. Short Story** (`1` ch, `21.1k` chars) | `S1` / `S2` / **`S4A`** | `1` / `1` / **`1`** | `5` / `29` / **`16`** | `4` / `20` / **`27`** | `4` / `20` / **`27`** | `2` / `3` / **`4`** | `12.7k` / `2.5k` (`S4A`) | `$0.0002` / `$0.0015` / **`$0.00133`** | `3.9s` / `8.8s` / **`11.4s`** |
| **C2: Giant 1-Spine Novella** (`1` ch, `84.2k` chars) | `S1` / `S2` / **`S4A`** | `1` / `1` / **`1`** | `8` / `24` / **`18`** | `8` / `22` / **`34`** | `8` / `22` / **`34`** | `1` / `4` / **`4`** | `21.6k` / `3.1k` (`S4A`) | `$0.0004` / `$0.0015` / **`$0.00168`** | `3.2s` / `11.4s` / **`23.0s`** |
| **C3: 6-Ch. Locked-Room** (`6` ch, `93.5k` chars) | `S1` / `S2` / **`S4A`** | `1` / `1` / **`1`** | `17` / `23` / **`18`** | `9` / `21` / **`31`** | `9+0` / `18+3` / **`20+11`** | `2` / `4` / **`5`** | `40.0k` / `2.9k` (`S4A`) | `$0.0007` / `$0.0017` / **`$0.00170`** | `7.8s` / `11.9s` / **`10.2s`** |
| **C4: 11-Ch. Multi-Witness** (`11` ch, `115.4k` chars) | `S2` / **`S4A`** / **`S4B`** | `1` / **`1`** / **`2`** | `31` / **`16`** / **`20`** | `24` / **`32`** / **`43`** | `9+4` / **`12+11`** / **`17+10`** | `5` / **`4`** / **`5`** | `51.3k`/`2.8k` (`S4A`) | `$0.0018` / **`$0.00170`** / **`$0.00236`** | `35.0s` / **`10.6s`** / `24.6s` |
| **C5: 32-Ch. Fragmented** (`32` ch, `107.8k` chars) | `S2` / **`S4A`** / **`S4B`** | `1` / **`1`** / **`2`** | `56` / **`21`** / **`27`** | `18` / **`22`** / **`34`** | `5+0` / **`9+4`** / **`18+8`** | `3` / **`5`** / **`5`** | `48.1k`/`2.7k` (`S4A`) | `$0.0018` / **`$0.00164`** / **`$0.00263`** | `12.8s` / **`8.6s`** / `40.4s` |
| **C6: 22-Ch. Long Novel** (`22` ch, `303.4k` chars) | `S2` / **`S4A`** / **`S4B`** | `1` / **`1`** / **`2`** | `76` / **`20`** / **`18`** | **`0` (starved)** / **`35`** / **`44`** | `0+0` / **`27+2`** / **`39+0`** | `0` / **`3`** / **`4`** | `47.8k`/`3.1k` (`S4A`) | `$0.0019` / **`$0.00184`** / **`$0.00269`** | `5.9s` / **`14.8s`** / `43.8s` |

**Key Engineering Takeaway (`Entity-Starvation Guard`):** In `C6` (`303k` chars), uncapped `S2` emitted `76` entities first and exhausted `max_tokens` with **`0` assertions**. Enforcing the **`14–22` Core Entity Salience Cap** in `S4A` reserves `>80%` of completion tokens for temporal assertions, yielding **`35` grounded assertions in a single `14.8 s` call at `$0.00184` (`~¥0.013`)**.
