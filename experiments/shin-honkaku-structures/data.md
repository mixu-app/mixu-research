# Shin-Honkaku Adversarial Narrative Structures Dataset Specification

## Corpus provenance and rights-safe anonymization policy

- **Anonymized structural evaluation manifest:** 69 logical mystery works derived from 50 structurally distinct EPUB containers (`Run sh-20261110-01`, freeze date `2026-11-10`).
- **Hard copyright firewall (`AGENTS.md` Rule 1):** Zero book text, zero verbatim excerpts, and zero copyrighted work titles or character names from the 50-EPUB local stress library are stored in this repository. Every work is referenced strictly by its anonymized structural ID (`SH-NT-01..12`, `SH-TL-01..05`, `SH-MM-01..17`, `SH-KY-01..07`, `SH-AM-01..08`, `SH-EP-01..20`) and topological statistics (spine count, character length, structural phenomenon tags).
- **Public CC0 synthetic twins (`mixu-fixtures`):** To provide fully inspectable, redistributable text and gold graph packs that mirror every adversarial Shin-Honkaku mechanism without copyright restriction, we pair the anonymized structural audit with two CC0-1.0 synthetic mystery fixtures in `mixu-fixtures`:
  - `sunflower-persona-trick` (`zh-Hans` / `ja` / `en`): Dual-timeline narrative deception, gender/age persona masking (`PERSONA` vs canonical `PERSON`), generational family surname collision, and late-horizon `IdentityLink` disclosure.
  - `labyrinth-manuscript-loop` (`zh-Hans` / `ja` / `en`): Story-within-a-story manuscript (`d_{\text{layer}} = \texttt{INNER\_WORK}` vs `\texttt{OUTER\_REALITY}`), 3-cycle time loop ($\ell_{\text{loop}} \in \{1, 2, 3\}$), architectural locked-room floorplan coordinates (`box`), and 4 competing detective solution frames ($f_{\text{frame}} \in \mathcal{F}$).

## Structural taxonomy across 69 logical works (50 EPUB containers)

Three of the 50 EPUB containers are multi-volume omnibuses (`SH-MM-01..09` in a 9-book 588-spine container; `SH-EP-01..08` in an 8-book 316-spine container; `SH-EP-09..13` in a 5-book 54-spine container), yielding $50 - 3 + (9 + 8 + 5) = 69$ distinct logical works:

| Structural Stratum | Anonymized Work IDs | Logical Works ($W_{\text{logical}}$) | EPUB Containers | Spine Count Range | Character Length Range | Primary Adversarial Mechanism Tested |Held-out Queries ($N_{\text{test}}$) |
|---|---|---|---|---|---|---|---|
| **1. Narrative Tricks (`SH-NT`)** | `SH-NT-01..12` + `sunflower-persona-trick` | 12 (+1 CC0) | 12 | $14\text{–}42$ | $145\text{k–}310\text{k}$ | Narrator/culprit persona masking, gender/age/vital-status deception, generational same-surname collision (`PFIMR`) | 180 |
| **2. Time-Loop & Sci-Fi (`SH-TL`)** | `SH-TL-01..05` + `labyrinth-manuscript-loop` | 5 (+1 CC0) | 5 | $18\text{–}36$ | $160\text{k–}295\text{k}$ | Cyclic world resets ($\ell_{\text{loop}} \in \{0..6\}$), cross-loop vital-status inversion (`DEAD` in $\ell=1$, `ALIVE` in $\ell=3$), rule-set mutations | 120 |
| **3. Meta / Mansion / Castle (`SH-MM`)** | `SH-MM-01..17` (incl. 9-vol 588-spine omnibus & 308-spine hypertext) | 17 | 9 | $16\text{–}588$ | $130\text{k–}1{,}420\text{k}$ | Nested diegetic manuscripts (`OUTER_REALITY` vs `INNER_WORK`), architectural floorplan `box` anchoring, 308-spine micro-fragmentation | 168 |
| **4. Encyclopedic / Folklore (`SH-KY`)** | `SH-KY-01..07` | 7 | 7 | $22\text{–}68$ | $380\text{k–}540\text{k}$ | Massive multi-era family chronicles, $90\%+$ folklore/demonology digression noise filtering via `jev-1.14` `score` | 108 |
| **5. Anti-Mystery / Multi-Solution (`SH-AM`)** | `SH-AM-01..08` | 8 | 8 | $15\text{–}38$ | $135\text{k–}280\text{k}$ | $4\text{–}7$ competing detective solution frames ($f_{\text{frame}} \in \mathcal{F}$) over identical physical clues; late-chapter meta-reversal | 132 |
| **6. Episodic / Omnibus / Reverse (`SH-EP`)** | `SH-EP-01..20` (incl. 8-vol 316-spine & 5-vol 54-spine omnibuses) | 20 | 9 | $8\text{–}316$ | $110\text{k–}980\text{k}$ | Multi-book omnibus boundary splitting ($22$ sub-volumes), reverse-chronology disclosure ($t_{\text{story}}$ inverse to $r$), recurring culprit across independent cases | 120 |
| **Total** | **`SH-*-01..69` + 2 CC0 Fixtures** | **69 (+2 CC0)** | **50** | **$8\text{–}588$** | **$110\text{k–}1.42\text{M}$** | **All 6 Shin-Honkaku Structural Axes** | **828** (of $1{,}380$ total) |

## Container anomaly sub-slices

To isolate container engineering from semantic graph reasoning, we track four structural stress slices inside the 69 works:

1. **Multi-Volume Omnibus Containers ($3$ EPUBs $\to 22$ Logical Works):**
   - `SH-MM-01..09`: 9-volume architectural mystery series bound in 1 EPUB ($588$ HTML spines, $1.42\text{M}$ characters).
   - `SH-EP-01..08`: 8-volume classic puzzle omnibus bound in 1 EPUB ($316$ HTML spines, $980\text{k}$ characters).
   - `SH-EP-09..13`: 5-volume career anthology bound in 1 EPUB ($54$ HTML spines, $610\text{k}$ characters).
2. **Hypertext / Micro-Spine Novel (`SH-MM-10`):**
   - 1 logical novel fragmented across $308$ HTML spines (median $410$ characters per spine) representing non-linear diary/manuscript shards.
3. **Mega-Length Encyclopedic Chronicles (`SH-KY-01..07`):**
   - 7 novels averaging $462\text{k}$ characters each, interleaving diegetic murder investigations with extensive folklore, historical, and psychological lectures (`FOLKLORE_REFERENCE`).
4. **Multi-Solution Cascade Novels (`SH-AM-01..08`):**
   - 8 novels containing $43$ distinct full-cast deduction rounds ($5.38$ competing solution frames per book), where earlier solutions are formally refuted (`REFUTED`) or superseded (`SUPERSEDED`) in the final $15\%$ of chapters.

## Deterministic split rule

- **Dev calibration split ($40\%$, $N_{\text{dev}} = 552$):** 27 logical works stratified across all 6 categories (`SH-NT-01..05`, `SH-TL-01..02`, `SH-MM-01..07`, `SH-KY-01..03`, `SH-AM-01..03`, `SH-EP-01..07`) plus Dev episodes of `sunflower-persona-trick` and `labyrinth-manuscript-loop`. Used once to tune the `jev-1.14` `score` encyclopedic salience threshold ($\theta_{\text{salience}}^* = 0.64$) and verify the `jev-hybrid-1.13+1.14` routing table.
- **Held-out test split ($60\%$, $N_{\text{test}} = 828$):** Remaining 42 logical works plus held-out test episodes of `sunflower-persona-trick` and `labyrinth-manuscript-loop`.
