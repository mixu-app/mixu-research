# Shin-Honkaku Adversarial Narrative Structures Protocol

**Question:** Does extending Mixu's flat dual-timeline graph $(t_{\text{story}}, r)$ to the five-dimensional **Multi-Frame Shin-Honkaku Coordinate** $(t_{\text{story}}, \ell_{\text{loop}}, d_{\text{layer}}, f_{\text{frame}}, r)$ and pairing `typesafe/jev-1.14` (`choice`, `score`, `box`) with `typesafe/jev-1.13` (`noul` classical negation guard) in a **Hybrid Decision Router (`jev-hybrid-1.13+1.14`)** eliminate Premature/False Identity Merge Rate ($\text{PFIMR} = 0.0\%$) and Cross-Loop/Cross-Hypothesis Contradiction Collisions ($\text{CCR} = 0.0\%$) while achieving Identity Macro-$F_1 \ge 0.900$, Multi-Solution Transition Macro-$F_1 \ge 0.880$, and Epistemic/Layer Macro-$F_1 \ge 0.895$ across 69 adversarial Shin-Honkaku mystery works and CC0 synthetic fixtures?

## Arms

Every arm is gated at reader projection time by `TemporalProjectionEngine` + `RedactionPolicy` (`first_seen <= h`, `reveal_at <= h`, and verbatim character-offset substring verification). What varies across arms is the structural coordinate representation, entity coreference regime, and compact decision model routing:

| Arm | Name | Coordinate & Coreference Architecture | Decision Model & Routing Specification |
|---|---|---|---|
| **Arm SH0** | Flat Coordinate + Global Substring Registry (Floor) | Flat $(t_{\text{story}}, r)$ indexing; global surface/surname entity merging; raw EPUB spine chunking without omnibus splitting or micro-spine coalescing. | `rules-v1.0` (`local-cpu`) |
| **Arm SH1** | Multi-Frame Coordinate + Standalone `jev-1.13` | 5D coordinate $(t_{\text{story}}, \ell_{\text{loop}}, d_{\text{layer}}, f_{\text{frame}}, r)$ + `PERSONA` / `IdentityLink` delayed coreference + omnibus/micro-spine normalizer. | `typesafe/jev-1.13` (`noul` span entailment across all tasks) |
| **Arm SH2** | Multi-Frame Coordinate + Standalone `jev-1.14` | Same 5D coordinate + `PERSONA` / `IdentityLink` + omnibus/micro-spine normalizer + `box` floorplan anchoring. | `typesafe/jev-1.14` (`noul`, `choice`, `score`, `box` across all tasks) |
| **Arm SH3** | Multi-Frame Coordinate + Hybrid Router (`jev-hybrid-1.13+1.14`) | Full 5D coordinate + `PERSONA` / `IdentityLink` + omnibus/micro-spine normalizer + task-routed decision primitives. | `typesafe/jev-1.14` for multi-choice attribute/layer selection (`choice`), encyclopedic salience (`score`), and architectural map grounding (`box`); pinned `typesafe/jev-1.13` for literary/classical negation entailment (`noul`) |

## Data

- **Anonymized structural stress benchmark:** 69 logical mystery works extracted from 50 structurally distinct EPUB containers spanning six adversarial Shin-Honkaku narrative phenomena (`SH-NT-01..12`, `SH-TL-01..05`, `SH-MM-01..17`, `SH-KY-01..07`, `SH-AM-01..08`, `SH-EP-01..20`). In strict compliance with `AGENTS.md` Rule 1, zero copyrighted book text, titles, or character names are committed; all stress-corpus metadata is indexed exclusively by anonymized structural IDs.
- **Public CC0 synthetic fixtures & public-domain anchors:** Paired with two rights-cleared CC0 synthetic fixtures in `mixu-fixtures` (`sunflower-persona-trick` for gender/age/narrator persona masking and `labyrinth-manuscript-loop` for nested `INNER_WORK` manuscripts + 3-cycle time loops + competing detective hypotheses) plus canonical public-domain works in `corpora/manifest.json` (`christie-ackroyd`, `leroux-yellow-room`, `anon-digongan-zh`).
- **Evaluation queries:** $N = 1{,}380$ stratified horizon queries across the 6 structural strata ($552$ Dev calibration / $828$ Held-out Test). Full structural inventory lives in [data.md](data.md).

## Metrics

Metrics are ordered by structural spoiler safety first, multi-frame epistemic fidelity second, and ingestion topology fidelity third:

### 1. Premature / False Identity Merge Rate (PFIMR) and Identity Macro-F1

$$\text{PFIMR} = \frac{\text{queries with premature persona merge } (r_{\text{reveal}} > h) \text{ or false family-surname merge}}{\text{total identity/coreference queries}}$$

- **Hard safety target:** $\text{PFIMR} = 0.0\%$ and post-filter $\text{SLR} = 0.000$.
- **Identity Macro-$F_1$:** Harmonic mean of precision and recall over `PERSONA`-isolated entity clusters and horizon-licensed `IdentityLink` (`ALIAS_OF`, `SAME_PERSON_AS`, `SHARES_NAME_WITH`, `NARRATED_BY_PERSONA`) edges at horizon $h$.

### 2. Cross-Loop / Cross-Hypothesis Contradiction Collision Rate (CCR) and Transition Macro-F1

$$\text{CCR} = \frac{\text{edges experiencing false state overwrite across distinct } \ell_{\text{loop}} \text{ or } f_{\text{frame}}}{\text{total multi-loop and multi-hypothesis assertions}}$$

- **Hard isolation target:** $\text{CCR} = 0.0\%$ when an entity dies in Loop $\ell = 1$ (`WORLD_STATE_ALIVE -> DEAD`) but survives in Loop $\ell = 3$, or when Hypothesis Frame $f_A$ (`HYPOTHESIS_FRAME(detective_A, #1)`) is overturned by $f_B$ (`REFUTES_HYPOTHESIS`).
- **Multi-Solution Transition Macro-$F_1$:** Macro-$F_1$ over hypothesis lifecycle transitions (`PROPOSED` $\to$ `CHALLENGED` $\to$ `REFUTED` / `SUPERSEDED` $\to$ `CORROBORATED`) across 4–7 competing deductions per novel.

### 3. Diegetic Layer & Epistemic Classification Macro-F1, Noise Suppression, and Floorplan IoU

- **Epistemic / Layer Macro-$F_1$:** Joint Macro-$F_1$ across the four epistemic tiers (`OBSERVED`, `CLAIMED`, `HYPOTHESIS_EDGE`, `INFERRED`) and four diegetic layers (`OUTER_REALITY`, `INNER_WORK`, `DREAM_HALLUCINATION`, `FOLKLORE_REFERENCE`).
- **Encyclopedic Noise Suppression Rate:** Percentage of non-diegetic folklore/pedantic digression noun phrases in $400\text{k–}550\text{k}$-character `SH-KY` novels correctly filtered from the active case board via `typesafe/jev-1.14` `score` salience gating.
- **Architectural Floorplan Grounding ($\text{IoU} \ge 0.5$):** Fraction of crime-scene map landmarks in `SH-MM` works localized with bounding-box $\text{IoU} \ge 0.5$ via `typesafe/jev-1.14` `box`.

### 4. Omnibus Boundary Precision & Micro-Spine Coalescing Recall

- **Volume Boundary Precision & Recall:** Accuracy of splitting multi-book omnibus EPUBs ($588$, $316$, and $54$ spines) into $22$ isolated novel graphs without cross-book entity contamination.
- **Micro-Spine Extraction Recall:** Edge recall on fragmented hypertext/diary EPUBs ($308$ spines, median $410$ chars/spine) before and after character-budget spine coalescing ($4\text{k–}8\text{k}$ chars).

## Decision rule

Defined prior to executing Run `sh-20261110-01`:

1. **Adopt** the 5D Multi-Frame Coordinate + `jev-hybrid-1.13+1.14` router (Arm SH3) if and only if all six conditions hold on the held-out evaluation:
   - Post-filter $\text{SLR} = 0.000$, $\text{PFIMR} = 0.0\%$, and $\text{CCR} = 0.0\%$
   - Identity Macro-$F_1 \ge 0.900$ on `SH-NT` + `sunflower-persona-trick`
   - Multi-Solution Transition Macro-$F_1 \ge 0.880$ on `SH-TL` + `SH-AM` + `labyrinth-manuscript-loop`
   - Epistemic / Diegetic Layer Macro-$F_1 \ge 0.895$ (exceeding both standalone `1.13` Arm SH1 and standalone `1.14` Arm SH2 by $\ge +0.035$)
   - Encyclopedic noise suppression $\ge 90.0\%$ on `SH-KY` and floorplan `box` accuracy ($\text{IoU} \ge 0.5$) $\ge 85.0\%$ on `SH-MM`
   - Omnibus boundary precision $= 100.0\%$ ($22/22$ sub-volumes) and coalesced hypertext recall $\ge 0.850$
2. **Reject** the hybrid router if standalone `jev-1.14` (Arm SH2) matches Arm SH3 within $0.010$ Macro-$F_1$ on classical Chinese negation (`R-03`), or if 5D coordinate indexing adds $> 15\%$ latency overhead to `TemporalProjectionEngine`.
3. **Revisit** if `PFIMR > 0.0%` on generational same-surname families (`SH-NT`, `SH-KY`), requiring stricter prompt-level disambiguation rules.

## Known confounds

- **`R-03` (Asymmetric point-release capability between `jev-1.13` and `jev-1.14`):** `typesafe/jev-1.14` introduces native `choice` (1-of-$N$ structured attribute/frame selection), `score` (continuous salience/confidence scoring), and `box` (2D visual floorplan grounding), which `1.13` lacks; however, `1.14` regresses on classical Chinese litotes (`未尝不`, `莫非`) under `noul`. Our protocol tests whether deterministic task-type routing (`jev-hybrid-1.13+1.14`) captures `1.14`'s structured primitives without inheriting its `noul` negation regression.
- **`R-04` (EPUB container vs. logical work mismatch):** Commercial and translated mystery omnibuses pack $5\text{–}9$ novels into a single EPUB container ($316\text{–}588$ HTML spines), whereas experimental metafiction splits a single novel into $308$ micro-spines. Evaluating extraction without container normalization confounds model reasoning errors with HTML spine fragmentation.
