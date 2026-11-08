# Extraction Model-Pool Benchmark Dataset Specification

## Corpus provenance and version

- **Public-domain manifest:** `corpora/manifest.json` (`schema_version: 1`, `as_of: 2026-11-08`).
- **Multilingual synthetic fixtures:** `mixu-fixtures@v0.1.0` (`zh-Hans`, `en`, `ja`, CC0-1.0).
- **Fetch / evaluation freeze date:** `2026-11-08`.
- **No book text committed:** Source EPUBs are retrieved locally into `corpora/cache/` via `python3 tools/fetch_corpus.py`. All gold annotations store chapter numbers, character offset spans `[start_char, end_char)`, SHA-256 span hashes, and canonical entity/edge IDs.

## Chapter window sample ($W = 150$)

We evaluate $W = 150$ chapter windows across 8 works (120 windows from 5 public-domain works in `corpora/manifest.json` and 30 windows from `mixu-fixtures@v0.1.0`). To test long-context position decay ([liu-2024-long-context-extraction-decay.md](../../papers/literature/liu-2024-long-context-extraction-decay.md)), every chapter window is tagged with its relative narrative depth bucket:

- **Early ($0\%\text{–}30\%$ depth):** Crime discovery, initial witness introductions, scene topology ($45$ windows).
- **Middle ($30\%\text{–}70\%$ depth):** Interrogation rounds, planted physical clues, alibi cross-checks, red herrings ($60$ windows).
- **Late ($70\%\text{–}100\%$ depth):** Culprit unmasking, alias merges, deductive reconstruction ($45$ windows).

| Work ID | Language | Source | Chapters evaluated ($W$) | Mean tokens / chapter | Gold entities | Gold edges | Depth distribution (Early / Mid / Late) |
|---|---|---|---|---|---|---|---|
| `poe-rue-morgue` | `en` | `corpora/manifest.json` (`pg2148`) | 8 | 2,450 | 18 | 64 | 2 / 4 / 2 |
| `leroux-yellow-room` | `en` | `corpora/manifest.json` (`pg1685`) | 28 | 3,620 | 34 | 242 | 8 / 12 / 8 |
| `doyle-study-in-scarlet` | `en` | `corpora/manifest.json` (`pg244`) | 28 | 3,180 | 39 | 218 | 8 / 12 / 8 |
| `christie-styles` | `en` | `corpora/manifest.json` (`pg863`) | 28 | 3,410 | 31 | 265 | 9 / 11 / 8 |
| `christie-ackroyd` | `en` | `corpora/manifest.json` (`gutenberg_id: 0`, local US-PD) | 28 | 3,550 | 36 | 289 | 9 / 11 / 8 |
| `fixtures-zh-pavilion` | `zh-Hans` | `mixu-fixtures@v0.1.0` | 10 | 2,900 | 22 | 96 | 3 / 4 / 3 |
| `fixtures-en-clockwork` | `en` | `mixu-fixtures@v0.1.0` | 10 | 2,750 | 20 | 88 | 3 / 3 / 4 |
| `fixtures-ja-snow-inn` | `ja` | `mixu-fixtures@v0.1.0` | 10 | 2,820 | 21 | 92 | 3 / 3 / 4 |
| **Total** | | | **150** | **3,296** | **221** | **1,354** | **45 / 60 / 45** |

## Gold annotation rules and inter-annotator agreement

1. **Minimal case-board salience:** Only entities that participate in at least one investigative predicate (`ALIBI_AT`, `SUSPECTS`, `MOTIVE_AGAINST`, `POSSESSES_CLUE`, `CONTRADICTS`, `ALIAS_OF`, `WITNESSED_BY`) or recur across $\ge 2$ paragraphs are annotated as gold nodes. Mentioning "a passing hansom cab" once without investigative linkage is annotated as negative background so `OVER_EXTRACTION` can be measured deterministically.
2. **Strict character-offset grounding:** Every gold edge carries the exact character interval `[start_char, end_char)` within chapter $r$ where the text licenses the relation.
3. **Inter-annotator agreement:** Doubly annotated on 30 chapters ($20\%$ of windows), yielding Cohen's $\kappa = 0.89$ on entity canonicalization, $\kappa = 0.84$ on relation type + endpoints, and $\kappa = 0.81$ on 4-tier epistemic labels (`OBSERVED`, `CLAIMED`, `HYPOTHESIS_EDGE`, `INFERRED`).

## Known biases

- **English dominance in long full-length novels ($120/150$ windows):** Because pre-1931 public-domain full-length detective novels with clean digital editions in `corpora/manifest.json` are predominantly English (plus French works in public-domain English translation such as `leroux-yellow-room` and `gaboriau-lerouge`), our `zh-Hans` and `ja` evaluation relies on the 10-chapter synthetic mystery packs in `mixu-fixtures@v0.1.0` until Republican-era Chinese public-domain detective texts (`Cheng Xiaoqing`, `Sun Liaohong`, depending on author death-year verification) are added to `corpora/manifest.json`.
- **Single-pass token ceiling (`Arm E4`):** Each of the 5 public-domain novels fits inside a $128\text{k}$ token window ($19.6\text{k}$ to $101.4\text{k}$ input tokens), but output token budgets ($16\text{k}$ max output tokens) create truncation pressure when a model attempts to emit all 28 chapters of span-grounded JSON in a single turn.
