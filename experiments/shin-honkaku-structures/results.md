# Shin-Honkaku Adversarial Narrative Structures Results (`Run sh-20261110-01`)

## Reproducibility metadata

| Field | Value |
|---|---|
| **Run ID** | `sh-20261110-01` |
| **Execution date** | `2026-11-10` |
| **Protocol version** | `experiments/shin-honkaku-structures/protocol.md` (`v1.0`) |
| **Coordinate & schema version** | `mixu-contracts@v0.2.0-sh` (`MultiFrameCoordinate`: $(t_{\text{story}}, \ell_{\text{loop}}, d_{\text{layer}}, f_{\text{frame}}, r)$) |
| **Corpus version** | 69 anonymized Shin-Honkaku logical works (`SH-NT-01..12`, `SH-TL-01..05`, `SH-MM-01..17`, `SH-KY-01..07`, `SH-AM-01..08`, `SH-EP-01..20` across 50 EPUB containers) + `mixu-fixtures@v0.1.0` (`sunflower-persona-trick`, `labyrinth-manuscript-loop`) |
| **Candidate models & routers** | Arm SH0: `rules-v1.0` flat $(t_{\text{story}}, r)$; Arm SH1: 5D coord + `typesafe/jev-1.13` (`noul` only); Arm SH2: 5D coord + `typesafe/jev-1.14` (`noul`, `choice`, `score`, `box`); Arm SH3: 5D coord + `jev-hybrid-1.13+1.14` (`1.14` `choice`/`score`/`box` + `1.13` `noul` negation guard) |
| **Reproduction command** | `./experiments/shin-honkaku-structures/run.sh` |

## Primary results across all four architectural arms (Held-out Test, $N = 828$)

| Arm | Coordinate & Model Router | Post-Filter SLR (ceil `0.000`) | Premature/False Identity Merge `PFIMR` | Cross-Loop/Hyp. Collision `CCR` | Identity Macro-$F_1$ (`SH-NT`) | Multi-Solution Transition $F_1$ (`SH-TL`/`AM`) | Epistemic & Layer Macro-$F_1$ (All) | Folklore Noise Suppression (`SH-KY`) | Floorplan `box` $\text{IoU}\ge 0.5$ (`SH-MM`) | Verdict |
|---|---|---|---|---|---|---|---|---|---|---|
| **Arm SH0** | Flat $(t_{\text{story}}, r)$ + Global Registry (`rules-v1.0`) | `0.000` | `31.4%` (`57/180`) | `42.8%` (`108/252`) | `0.584` | `0.612` | `0.668` | `28.4%` | `0.0%` (unsupported) | **Reject** (severe `PFIMR` $31.4\%$ & `CCR` $42.8\%$) |
| **Arm SH1** | 5D Coord + Standalone `typesafe/jev-1.13` (`noul`) | **`0.000`** | `2.8%` (`5/180`) | **`0.0%`** (`0/252`) | `0.864` | `0.871` | `0.854` | `76.5%` | `0.0%` (no `box` head) | **Revisit** (lacks `1.14` `choice`/`score`/`box`) |
| **Arm SH2** | 5D Coord + Standalone `typesafe/jev-1.14` (`noul`+`choice`+`score`+`box`) | **`0.000`** | **`0.0%`** (`0/180`) | **`0.0%`** (`0/252`) | **`0.914`** | `0.882` | `0.861` | **`94.2%`** | **`88.5%`** | **Revisit** (`1.14` `noul` regresses on classical negation) |
| **Arm SH3** | 5D Coord + **Hybrid Router (`jev-hybrid-1.13+1.14`)** | **`0.000`** | **`0.0%`** (`0/180`) | **`0.0%`** (`0/252`) | **`0.914`** | **`0.896`** (`+0.284`) | **`0.908`** | **`94.2%`** | **`88.5%`** | **Adopt (Passes all 6 criteria)** |

## Breakdown by the four core Shin-Honkaku empirical findings

### 1. Narrative Tricks (`SH-NT-01..12` + `sunflower-persona-trick`): Delayed Coreference & Persona Masking

In narrative-deception mysteries (`SH-NT`), authors deliberately exploit unmarked focalization switches, gender/age/species presuppositions, diary-versus-present timeline interleaving, and generational family surname sharing.

| Coreference & Entity Architecture | Premature/False Identity Merge Rate (`PFIMR`) | Same-Surname Family Collision Rate | Pre-Reveal Persona Isolation Accuracy | Post-Reveal `IdentityLink` Recall ($r_{\text{reveal}} \le h$) | Identity Macro-$F_1$ |
|---|---|---|---|---|---|
| Naïve Global / Substring Registry (Arm SH0) | `31.4%` (`57/180`) | `38.9%` | `64.2%` | `0.710` | `0.584` |
| `PERSONA` + `IdentityLink` + `jev-1.13` (`noul` binary pair, Arm SH1) | `2.8%` (`5/180`) | `4.2%` | `96.1%` | `0.852` | `0.864` |
| `PERSONA` + `IdentityLink` + `jev-1.14` `choice` Guard (Arm SH2 / Arm SH3) | **`0.0%` (`0/180`)** | **`0.0%`** | **`100.0%`** | **`0.901`** | **`0.914`** |

**Why `PERSONA` + `jev-1.14` `choice` eliminates the $31.4\%$ merge failure:**
When every chapter mention is instantiated as a scoped `PERSONA` node rather than eagerly merged into a global `PERSON` node, and `typesafe/jev-1.14` `choice` evaluates mutually exclusive attribute compatibility (`GENERATION_1` vs `GENERATION_2`, `NARRATIVE_EPOCH_DIARY` vs `NARRATIVE_EPOCH_PRESENT`, `UNMARKED` vs `EVIDENCE_GROUNDED`), Premature/False Identity Merge Rate drops from **$31.4\%$ to $0.0\%$** while lifting Identity Macro-$F_1$ from $0.584$ to **$0.914$** and preserving post-filter $\text{SLR} = 0.000$.

### 2. Time-Loop & Multi-Solution Hypothesis Indexing (`SH-TL-01..05` + `SH-AM-01..08` + `labyrinth-manuscript-loop`)

In time-loop mysteries (`SH-TL`, $3\text{–}6$ world resets) and anti-mystery multi-solution cascades (`SH-AM`, $4\text{–}7$ competing deductions per book), flat temporal indexing $(t_{\text{story}}, r)$ overwrites state edges when the same timestamp $t_{\text{story}} = \text{Day 2, 23:00}$ recurs in Loop $\ell = 3$ or when Detective B refutes Detective A's reconstruction of the exact same crime window.

| Graph Indexing Coordinate | Cross-Loop / Cross-Hypothesis Collision Rate (`CCR`) | Loop Vital-Status Isolation Accuracy (`SH-TL`) | Competing Hypothesis Frame Separation (`SH-AM`, $43$ rounds) | Multi-Solution Transition Macro-$F_1$ | $\Delta F_1$ vs Flat Baseline |
|---|---|---|---|---|---|
| Flat Dual-Timeline $(t_{\text{story}}, r)$ (Arm SH0) | `42.8%` (`108/252`) | `51.7%` | `58.1%` (`25/43`) | `0.612` | baseline (`0.000`) |
| 5D Coordinate $(t_{\text{story}}, \ell_{\text{loop}}, d_{\text{layer}}, f_{\text{frame}}, r)$ + `1.13` (Arm SH1) | **`0.0%` (`0/252`)** | **`100.0%`** | **`100.0%` (`43/43`)** | `0.871` | `+0.259` |
| 5D Coordinate + `1.14` Standalone (Arm SH2) | **`0.0%` (`0/252`)** | **`100.0%`** | **`100.0%` (`43/43`)** | `0.882` | `+0.270` |
| 5D Coordinate + **Hybrid Router `jev-hybrid-1.13+1.14`** (Arm SH3) | **`0.0%` (`0/252`)** | **`100.0%`** | **`100.0%` (`43/43`)** | **`0.896`** | **`+0.284`** |

**Why 5D indexing resolves the $42.8\%$ collision rate:**
Partitioning every assertion and epistemic transition by $(\ell_{\text{loop}}, d_{\text{layer}}, f_{\text{frame}})$ ensures that a victim's `DEAD` status in `(loop_id=1, frame=FACTUAL)` never collides with `ALIVE` in `(loop_id=3, frame=FACTUAL)` (`CCR` $= 0.0\%$), while `REFUTES_HYPOTHESIS` transitions cleanly demote `HYPOTHESIS_FRAME(detective_A, #1)` to `REFUTED` without erasing its historical clue chain, lifting Multi-Solution Transition Macro-$F_1$ from $0.612$ to **$0.896$** ($\Delta F_1 = +0.284$).

### 3. Nested Diegesis (`OUTER_REALITY` vs `INNER_WORK` vs `FOLKLORE_REFERENCE`) & Hybrid `1.13 + 1.14` Routing

We evaluated `typesafe/jev-1.13` and `typesafe/jev-1.14` across all four primitive task families on the Shin-Honkaku benchmark:

| Task Family & Primitive | Standalone `jev-1.13` (Arm SH1) | Standalone `jev-1.14` (Arm SH2) | **Hybrid `jev-hybrid-1.13+1.14` (Arm SH3)** | Routing Rule in Arm SH3 |
|---|---|---|---|---|
| **Diegetic Layer Selection (`choice`):** `OUTER_REALITY` vs `INNER_WORK` vs `DREAM` vs `FOLKLORE` | `0.838` (emulated via $4\times$ binary `noul`) | **`0.926`** (native 1-of-4 `choice`) | **`0.926`** | Routed to **`typesafe/jev-1.14` (`choice`)** |
| **Classical/Literary Negation & Indirect Speech (`noul`):** double-negation alibi refutation | **`0.890`** (pinned `1.13` `noul`) | `0.818` (`-0.072` `R-03` polarity flip) | **`0.890`** | Routed to **`typesafe/jev-1.13` (`noul`)** |
| **Encyclopedic Folklore Salience (`score`):** suppressing pedantic noise in $500\text{k}$-char `SH-KY` novels | `76.5%` suppressed (heuristic threshold) | **`94.2%` suppressed** ($\theta^* = 0.64$) | **`94.2%` suppressed** | Routed to **`typesafe/jev-1.14` (`score`)** |
| **Architectural Floorplan Grounding (`box`):** crime-scene room/passage localization ($\text{IoU} \ge 0.5$) | `0.0%` (no visual `box` head) | **`88.5%`** ($115/130$ landmarks) | **`88.5%`** ($115/130$ landmarks) | Routed to **`typesafe/jev-1.14` (`box`)** |
| **Overall Shin-Honkaku Epistemic & Layer Macro-$F_1$** | `0.854` | `0.861` | **`0.908`** (`+0.054` vs `1.13`, `+0.047` vs `1.14`) | **Deterministic task-primitive router** |

### 4. Omnibus Splitting & Micro-Spine Coalescing (`SH-MM`, `SH-EP`)

| Container Pathology Slice | Raw EPUB Spine Ingestion (Arm SH0) | Topology-Normalized Ingestion (Arm SH3) | Structural Gain |
|---|---|---|---|
| **3 Multi-Book Omnibus EPUBs** ($588$, $316$, and $54$ spines = $958$ total spines across $22$ works) | $3$ merged super-graphs ($18.4\%$ cross-book entity name contamination; $290\text{k}$-char context overflow) | **$22 / 22$ isolated novel graphs** (**$100.0\%$** volume boundary precision & recall; $0.0\%$ cross-book contamination) | Eliminates omnibus context blowup and cross-book character collisions |
| **308-Spine Hypertext / Diary Novel (`SH-MM-10`)** (median $410$ chars/spine) | Edge Recall $= \mathbf{0.142}$ ($308$ fragmented calls lose cross-paragraph coreference) | Edge Recall $= \mathbf{0.879}$ (`+0.737` recall gain; coalesced into $34$ semantic windows of $4\text{k–}8\text{k}$ chars while preserving exact `(spine_idx, char_offset)` locators) | **$6.19\times$ higher extraction recall** at $89\%$ fewer API calls |

## Negative findings and failure analysis

1. **Why standalone `typesafe/jev-1.14` cannot replace `jev-1.13` for `noul` entailment:** On literary double-negation and rhetorical counterfactuals in translated Japanese/Chinese deduction chapters (`並非不在場`, `未嘗不可能`), `jev-1.14`'s `noul` head suffers an $18.2\%$ polarity flip rate, pulling its standalone negation $F_1$ down to $0.818$ vs `jev-1.13`'s $0.890$. Routing `choice`, `score`, and `box` to `1.14` while keeping `noul` on `1.13` is essential to achieve the $0.908$ hybrid Macro-$F_1$.
2. **Reverse-chronology stories (`SH-EP-14..17`) require explicit relative-time anchoring:** When a collection narrates Chapter 1 at the culprit's arrest ($t_{\text{story}} = T_{\text{end}}$) and walks backward to the childhood motive in Chapter 8 ($t_{\text{story}} = T_0$), models prompted without explicit `StoryTimeAnchor` markers invert `CAUSES` edges in $9.4\%$ of windows.
3. **Hand-drawn ASCII/SVG schematic maps vs. raster scans (`SH-MM`):** `typesafe/jev-1.14` `box` achieves $88.5\%$ $\text{IoU} \ge 0.5$ on standard architectural floorplans (decagon/mansion/clock-tower rooms), but drops to $64.3\%$ on heavily stylized isometric perspective illustrations where room boundaries overlap vertically.

## Verdict

- **Adopt the 5D Multi-Frame Shin-Honkaku Coordinate $(t_{\text{story}}, \ell_{\text{loop}}, d_{\text{layer}}, f_{\text{frame}}, r)$** and `PERSONA` + `IdentityLink` delayed coreference across the Mixu graph and spoiler firewall (`PFIMR` $= 0.0\%$, `CCR` $= 0.0\%$, Identity Macro-$F_1 = 0.914$, Multi-Solution Transition Macro-$F_1 = 0.896$).
- **Adopt the Hybrid Decision Router (`jev-hybrid-1.13+1.14`)**: invoke `typesafe/jev-1.14` for `choice` (diegetic layer & mutually exclusive persona attribute selection), `score` ($94.2\%$ folklore noise suppression), and `box` ($88.5\%$ floorplan grounding), while pinning `typesafe/jev-1.13` for `noul` binary span entailment (achieving overall Epistemic/Layer Macro-$F_1 = 0.908$).
- **Adopt pre-extraction Omnibus Volume Splitting ($100\%$ precision across $22$ sub-volumes) and Character-Budget Micro-Spine Coalescing ($0.142 \to 0.879$ recall on 308-spine hypertext)**.
