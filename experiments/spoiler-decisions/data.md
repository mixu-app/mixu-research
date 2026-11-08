# Spoiler-Decision Dataset & Split Specification

## Corpus provenance and version metadata

- **Primary public-domain manifest:** `corpora/manifest.json` (`schema_version: 1`, `as_of: 2026-11-08`, validated by `python3 tools/check_corpus.py`).
- **Synthetic control corpus:** `mixu-fixtures` (`v0.1.0`, CC0-1.0 original mystery stories authored specifically to eliminate pretraining memorization `R-01` and test multilingual edge cases in `zh-Hans`, `en`, and `ja`).
- **Fetch / freeze date:** `2026-11-08`.
- **Storage policy:** Zero book text is committed to this repository. Public-domain EPUBs are fetched on demand into `corpora/cache/` (Git-ignored) via `python3 tools/fetch_corpus.py`. Evaluation annotations reference work IDs, chapter indices $r \in \mathbb{N}$, and character-offset intervals `[start_char, end_char)`.

## Work inventory and query distribution

The evaluation dataset comprises $N = 1{,}200$ human-verified decision queries sampled across 8 works (5 canonical public-domain works from `corpora/manifest.json` and 3 synthetic multilingual benchmark stories from `mixu-fixtures`). Each query specifies a reading horizon $h \in \{20\%, 35\%, 50\%, 75\%, 90\%\}$ of total chapters, a candidate graph assertion (entity alias, alibi claim, motive/means edge, or contradiction transition), and its ground-truth epistemic status at horizon $h$ versus full-book horizon $H_{\max}$.

| Corpus ID | Source | Language | Published / Death | US / CN / EU PD (2026) | Split assignment | Total queries ($N$) | Primary narrative phenomenon tested |
|---|---|---|---|---|---|---|---|
| `poe-rue-morgue` | `corpora/manifest.json` (`pg2148`) | `en` | 1841 / 1849 | yes / yes / yes | Dev (calibration) | 120 | Witness contradiction (`CLAIMED` vs acoustic physical evidence `OBSERVED`) |
| `leroux-yellow-room` | `corpora/manifest.json` (`pg1685`) | `en` | 1907 / 1927 | yes / yes / yes | Dev (calibration) | 180 | Locked-room alibi refutation and late-book identity (`ALIAS_OF` reveal at Ch. 26) |
| `christie-styles` | `corpora/manifest.json` (`pg863`) | `en` | 1920 / 1976 | yes / no (2027) / no (2047) | Dev (calibration) | 180 | Planted red-herring corroboration vs delayed toxicology contradiction |
| `doyle-study-in-scarlet` | `corpora/manifest.json` (`pg244`) | `en` | 1887 / 1930 | yes / yes / yes | Held-out Test | 180 | Multi-hop deductive chain (`INFERRED` vs `OBSERVED`) across Part I and Part II flashback |
| `christie-ackroyd` | `corpora/manifest.json` (`gutenberg_id: 0`, local US-PD edition) | `en` | 1926 / 1976 | yes / no (2027) / no (2047) | Held-out Test | 180 | Unreliable first-person narrator omission and timeline manipulation (`R-01` stress test) |
| `fixtures-zh-pavilion` | `mixu-fixtures@v0.1.0` | `zh-Hans` | 2026 (CC0-1.0) | CC0 / CC0 / CC0 | Dev (90) / Test (150) | 240 | Classical/idiomatic Chinese negation (`未尝不`, `莫非`) and zero-pronoun indirect speech alibis |
| `fixtures-en-clockwork` | `mixu-fixtures@v0.1.0` | `en` | 2026 (CC0-1.0) | CC0 / CC0 / CC0 | Dev (45) / Test (105) | 150 | Twin-alias substitution (`ALIAS_OF`) and retracted confession (`RETRACTED`) |
| `fixtures-ja-snow-inn` | `mixu-fixtures@v0.1.0` | `ja` | 2026 (CC0-1.0) | CC0 / CC0 / CC0 | Dev (45) / Test (105) | 150 | Honorific-implied speaker attribution and architectural locked-room timeline shift |
| **Total** | | | | | **480 Dev / 720 Test** | **1,200** | |

*Note on `christie-ackroyd` and `christie-styles` rights:* Both works were published on or before 1930 (1926 and 1920) and are public domain in the United States as verified by `tools/check_corpus.py`. Because Agatha Christie died in 1976, they remain under copyright in China until 2027-01-01 and in the EU until 2047-01-01. No text or extracted graph pack from these works is distributed in this repository or in any public Mixu repository.

## Deterministic split rule and phenomenon stratification

To prevent entity leakage between threshold calibration and final evaluation:

1. **Work-disjoint classic split:** Whole books in `corpora/manifest.json` are assigned strictly to either Dev (`poe-rue-morgue`, `leroux-yellow-room`, `christie-styles`) or Held-out Test (`doyle-study-in-scarlet`, `christie-ackroyd`).
2. **Story-disjoint synthetic sub-episodes:** Each `mixu-fixtures` language pack contains 5 independent mini-mysteries (episodes `ep01`–`ep05`); episodes `ep01`–`ep02` are assigned to Dev and `ep03`–`ep05` to Held-out Test using deterministic hash seed `mixu-sd-split-20261108`.
3. **Phenomenon balance:** Across both Dev ($N = 480$) and Held-out Test ($N = 720$), queries are balanced across four narrative phenomena:

| Phenomenon stratum | Description | Dev queries ($40\%$) | Held-out Test queries ($60\%$) | Total ($100\%$) |
|---|---|---|---|---|
| `alias_resolution` | Two surface names refer to the same canonical person, revealed only at chapter $r_{\text{reveal}} > h$ | 120 | 180 | 300 |
| `alibi_contradiction` | Suspect's `CLAIMED` spatiotemporal alibi is later refuted (`CONTRADICTED`) by physical evidence or a second witness | 120 | 180 | 300 |
| `unreliable_narrator` | Narrator or focal character hedges, omits, or uses litotes/irony to disguise commitment | 120 | 180 | 300 |
| `late_reveal` | Culprit identity, murder weapon, or hidden motive edge disclosed in the final $15\%$ of chapters | 120 | 180 | 300 |
| **Total** | | **480** | **720** | **1,200** |

## Known biases and confounds

1. **`R-01` (Pretraining memorization of canonical mysteries):** Commercial and open-weights LLMs have memorized the culprit of *The Murder of Roger Ackroyd* (`christie-ackroyd`) and *The Mystery of the Yellow Room* (`leroux-yellow-room`). In an unfiltered prompt, a model may predict `CONTRADICTED` on an early alibi not because the text up to chapter $h$ contradicts it, but because the model remembers the ending. Our evaluation isolates this confound by reporting pre-filter $\text{SLR}$ and Macro-$F_1$ separately for `corpora/manifest.json` classics ($N_{\text{test}} = 360$) versus unseen `mixu-fixtures` episodes ($N_{\text{test}} = 360$).
2. **`R-02` (Gutenberg edition segmentation variance):** Project Gutenberg HTML/EPUB headers occasionally merge a prologue or epilogue into adjacent chapters. Our ingestion normalizer strips paratext (`Transcriber's Note`, table of contents) before indexing chapter numbers $r \in \{1..K\}$.
3. **`R-03` (Translator style in public-domain English editions):** `leroux-yellow-room` (`pg1685`) is an early 20th-century English translation from French, exhibiting archaic reporting verbs (`averred`, `deposed`) that differ from modern `en` and `zh-Hans` syntax.
