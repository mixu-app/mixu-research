# Progress-Aware Narrative Knowledge Engineering: Epistemic Horizon Filtering for Mystery Fiction

- **Status:** `draft` (honest pre-submission draft; not yet submitted or peer-reviewed)
- **Authors:** Mixu Research Group
- **Target venue:** ACL / EMNLP (Track: Information Extraction, Discourse, and Interactive NLP Systems)
- **Version date:** `2026-11-08`
- **Artifact manifest:** [artifacts.md](artifacts.md) | **Self-review log:** [review.md](review.md)

## Abstract

Readers of mystery and detective fiction routinely abandon digital character glossaries and knowledge graphs because static, book-global representations leak late-book plot twists, premature alias merges, and culprit centrality. Conversely, generating on-the-fly summaries with a retrieval-augmented language model conditioned on chapters $[1..h]$ still leaks spoilers on canonical novels due to parametric pretraining memorization (`R-01`). We introduce **Progress-Aware Narrative Knowledge Engineering**, an extraction and deterministic projection architecture that indexes every entity mention, alias equivalence, relational edge, and epistemic state transition by both diegetic story time ($t_{\text{story}}$) and narrative disclosure locus ($r \in \mathbb{N}$), gating reader-visible projections behind a four-tier epistemic lattice (`OBSERVED`, `CLAIMED`, `HYPOTHESIS_EDGE`, `INFERRED`). We establish three empirical claims across five public-domain detective classics (`corpora/manifest.json`, `schema_version: 1`, `as_of: 2026-11-08`) and three rights-cleared multilingual synthetic mysteries (`mixu-fixtures@v0.1.0` in `zh-Hans`, `en`, and `ja`):

1. **Zero-Leakage Horizon Firewall with Calibrated Epistemic Gains:** Combining our deterministic `TemporalProjectionEngine` + `RedactionPolicy` firewall with a dev-calibrated compact decision classifier (`jev-decision-1.13` at $\tau^* = 0.72$, Run `sd-20261108-01`, $N = 720$ held-out test queries) guarantees a post-filter Spoiler Leakage Rate of $\text{SLR} = 0.000$ ($0/720$), reduces pre-filter spoiler proposals from $0.039$ ($28/720$ in unconstrained LLM JSON Arm B) to $0.003$ ($2/720$ in Arm C), and lifts four-tier epistemic Macro-$F_1$ from $0.742$ (deterministic rules floor, Arm A) to $0.858$ ($\Delta F_1 = +0.116$, $\text{ECE}_{10} = 0.031$, $P_{95} = 142\text{ ms}$, $\$0.09 / 1{,}000\text{ decisions}$)—and to $0.889$ ($\Delta F_1 = +0.147$, $\text{ECE}_{10} = 0.024$, $\$0.34 / 1{,}000\text{ decisions}$) when escalating the $18.3\%$ of queries inside the uncertainty band $p \in [0.45, 0.72)$ (Arm D; [../../experiments/spoiler-decisions/results.md](../../experiments/spoiler-decisions/results.md)).
2. **Superiority of Chapter-Chunked Span-Grounded Extraction over 128k Single-Pass Windows:** Across $W = 150$ chapter windows ($1{,}354$ gold edges, Run `emp-20261108-01`), chapter-chunked extraction ($4\text{k–}8\text{k}$ tokens paired with a $\le 1.5\text{k}$-token horizon entity registry) achieves overall Edge Macro-$F_1 = 0.824\text{–}0.841$ and mid-book ($30\%\text{–}70\%$ depth) Edge Macro-$F_1 = 0.812\text{–}0.833$ at a retry-adjusted cost of $\$0.44\text{–}\$0.46$ per accepted 24-chapter novel graph (`qwen2.5-72b-instruct` Arm E2 and `deepseek-v3-0324` Arm E3), whereas whole-book single-pass $128\text{k}$ extraction (Arm E4) suffers a $-0.194$ mid-book Edge $F_1$ collapse ($0.618$ vs $0.812$), increases ungrounded span citations (`EVIDENCE_NOT_SUBSTRING`) from $3.1\%$ to $14.8\%$, introduces $6.4\%$ pre-validator cross-chapter `HORIZON_VIOLATION` edges, and inflates retry-adjusted cost by $2.18\times$ to $\$0.96$ per novel ([../../experiments/extraction-model-pool/results.md](../../experiments/extraction-model-pool/results.md)).
3. **Robustness Against Parametric Memorization (`R-01`) and Multilingual Point-Release Drift (`R-03`):** Separating canonical public-domain works ($n = 360$) from unseen CC0 synthetic mysteries ($n = 360$) demonstrates that unconstrained LLM generation leaks $8.6\times$ more often on famous novels ($6.9\%$ vs $0.8\%$ pre-filter $\text{SLR}$), whereas span-grounded entailment classification achieves equal or higher epistemic gains on unseen narratives (Arm C Macro-$F_1 = 0.862$ unseen vs $0.854$ famous; Arm D $0.892$ vs $0.886$) and prevents the $-0.064$ Chinese classical-negation/indirect-speech regression observed between decision model releases `1.13` and `1.14` ($0.851$ vs $0.787$ Macro-$F_1$ on `zh-Hans`; [../../experiments/spoiler-decisions/results.md](../../experiments/spoiler-decisions/results.md), [../../experiments/extraction-model-pool/results.md](../../experiments/extraction-model-pool/results.md)).

## 1. Architecture and Formal Model

### 1.1 Dual-Timeline Narrative Indexing: Story Time ($t_{\text{story}}$) vs. Disclosure Time ($r \in \mathbb{N}$)

Mystery narratives deliberately decouple the chronological order of events in the fictional world (**Story Time**, $t_{\text{story}}$: when the crime was committed, when an alibi occurred, or when an identity was forged) from the linear order in which those facts are disclosed to the reader (**Disclosure Time**, $r = (c, o) \in \mathbb{N} \times \mathbb{N}$, indexed by chapter $c \in \{1..K\}$ and character offset interval $o = [s, e)$ within chapter $c$).

A conventional knowledge graph collapses both timelines into a timeless triple $(u, \text{rel}, v)$. In detective fiction, that collapse is a spoiler engine: if Chapter 26 reveals that suspect $u$ ("Monsieur Darzac") and identity $v$ ("Frédéric Larsan") are the same person, or that an alibi at $t_{\text{story}} = \text{23:30}$ was fabricated, storing the resolved graph leaks the ending to a reader at horizon $h = \text{Chapter 8}$.

We define a **Progress-Aware Narrative Knowledge Graph** as an append-only tuple:

$$G = (V, A, E, T)$$

where:

- $V$ is the set of surface-anchored entity records $v$, each carrying creation locus $\text{first\_seen}(v) \in \mathbb{N}$ and a time-indexed attribute log.
- $A \subseteq V \times V \times \mathbb{N}$ is the set of explicit alias-equivalence links $(u, v, r_{\text{reveal}})$ asserting that surface entities $u$ and $v$ resolve to the same canonical referent only at disclosure locus $r_{\text{reveal}}$ (accompanied by verbatim character span $o_{\text{reveal}} \subset \text{text}(r_{\text{reveal}})$).
- $E$ is the set of directed relational assertions $e = (u, v, \text{pred}, \varepsilon_0, t_{\text{story}}, r_{\text{assert}}, o_{\text{assert}})$, where $\varepsilon_0$ is the initial epistemic tier and $r_{\text{assert}}$ is the chapter locus licensing the assertion.
- $T$ is an append-only log of epistemic state transitions $\tau = (e, \sigma, r_{\text{trans}}, o_{\text{trans}})$ recording how subsequent evidence corroborates, contradicts, or retracts edge $e$ at disclosure locus $r_{\text{trans}} \ge r_{\text{assert}}$.

### 1.2 Four-Tier Epistemic Lattice and Append-Only State Transitions

Unlike encyclopedic fact extraction, mystery prose consists primarily of competing claims, lies, and provisional deductions. Every relational edge $e \in E$ is typed by a four-tier epistemic status lattice $(\mathcal{E}, \sqsubseteq)$:

$$\texttt{HYPOTHESIS\_EDGE} \sqsubseteq \texttt{CLAIMED} \sqsubseteq \texttt{INFERRED} \sqsubseteq \texttt{OBSERVED}$$

1. **`OBSERVED`:** Directly witnessed by the narrative camera or established via uncontested physical inspection at locus $r_{\text{assert}}$ (e.g., the locked bolt on the inside of Mademoiselle Stangerson's door in `leroux-yellow-room`).
2. **`CLAIMED`:** Asserted in dialogue, testimony, or written correspondence by an in-story speaker $s \in V$ (e.g., a suspect's spatiotemporal alibi), carrying speaker commitment without narrator endorsement.
3. **`HYPOTHESIS_EDGE`:** Explicitly framed in the text or by the reader's case board as a tentative theory or suspect hypothesis prior to decisive proof.
4. **`INFERRED`:** Derived via a multi-premise deductive step written in the narrative text at locus $r_{\text{assert}}$, citing $\ge 2$ antecedent edges visible at $r \le r_{\text{assert}}$.

As the reader advances from horizon $h_1$ to $h_2 > h_1$, an existing edge $e \in E$ is never destructively overwritten. Instead, new evidence at locus $r_{\text{trans}} \in (h_1, h_2]$ appends a transition record $\sigma \in \{\texttt{CORROBORATED}, \texttt{CONTRADICTED}, \texttt{RETRACTED}, \texttt{UNRESOLVED}\}$ to $T$:

- **`CORROBORATED`:** Independent witness or physical clue at $r_{\text{trans}}$ confirms a previously `CLAIMED` or `HYPOTHESIS_EDGE` assertion.
- **`CONTRADICTED`:** Evidence at $r_{\text{trans}}$ refutes the assertion (e.g., Poirot proving in `christie-styles` or `christie-ackroyd` that a timeline alibi is impossible).
- **`RETRACTED`:** The original claimant withdraws their testimony at $r_{\text{trans}}$.
- **`UNRESOLVED`:** Default initial state when evidence at $r \le h$ is insufficient or falls below the calibrated decision confidence threshold $\tau^*$.

### 1.3 Deterministic Horizon Projection Invariant $P(G, h)$

Given a reader's current reading horizon $h \in \mathbb{N}$, the deterministic projection operator $P(G, h) = (V_h, \sim_h, E_h, T_h)$ implemented by `TemporalProjectionEngine` + `RedactionPolicy` computes the exact subgraph visible at $h$:

$$V_h = \{v \in V \mid \text{first\_seen}(v) \le h \land \text{valid\_substring}(o_v, \text{text}(\text{first\_seen}(v)))\}$$

$$u \sim_h v \iff (u = v) \lor \exists (u, v, r_{\text{reveal}}) \in A \text{ such that } r_{\text{reveal}} \le h$$

$$E_h = \{e \in E \mid u \in V_h \land v \in V_h \land r_{\text{assert}}(e) \le h \land \text{valid\_substring}(o_{\text{assert}}(e), \text{text}(r_{\text{assert}}(e)))\}$$

$$T_h(e) = \{\tau \in T(e) \mid r_{\text{trans}}(\tau) \le h \land \text{valid\_substring}(o_{\text{trans}}(\tau), \text{text}(r_{\text{trans}}(\tau)))\}$$

**Horizon Safety Invariant:** Because $P(G, h)$ admits an entity, alias merge, edge, or epistemic transition if and only if its disclosure locus satisfies $r \le h$ and its character offset span is a verified verbatim substring of chapter $r$, **no upstream classifier error or LLM hallucination can leak an item anchored at $r > h$**, guaranteeing post-filter $\text{SLR} = 0.000$ across all model arms.

## 2. Empirical Claims and Experimental Verification

Every number reported in this paper is reproduced by committed scripts in `experiments/` and traced below.

| Claim | Experiment run & report | Core quantitative result | Verification command |
|---|---|---|---|
| **Claim 1:** Calibrated compact decision model behind deterministic projection achieves $\text{SLR} = 0.000$ and $\Delta F_1 = +0.116$ ($+0.147$ with escalation) | Run `sd-20261108-01` ([../../experiments/spoiler-decisions/results.md](../../experiments/spoiler-decisions/results.md)) | Post-filter $\text{SLR} = 0.000$; Pre-filter $\text{SLR} = 0.003$ (Arm C) vs $0.039$ (Arm B); Macro-$F_1 = 0.858$ (Arm C, $\$0.09/1\text{k}$) and $0.889$ (Arm D, $\$0.34/1\text{k}$) vs $0.742$ (Arm A); $\text{ECE}_{10} = 0.031$ | `./experiments/spoiler-decisions/run.sh` |
| **Claim 2:** Chapter-chunked extraction ($4\text{k–}8\text{k}$) outperforms whole-book $128\text{k}$ single-pass by $+0.194$ mid-book Edge $F_1$ at $46\%$ of the cost | Run `emp-20261108-01` ([../../experiments/extraction-model-pool/results.md](../../experiments/extraction-model-pool/results.md)) | Mid-book Edge $F_1 = 0.812$ (Arm E2) / $0.833$ (Arm E3) vs $0.618$ (Arm E4 128k); `EVIDENCE_NOT_SUBSTRING` $= 3.1\%$ vs $14.8\%$; Novel cost $= \$0.44\text{–}\$0.46$ vs $\$0.96$ ($2.18\times$) | `./experiments/extraction-model-pool/run.sh` |
| **Claim 3:** Span-grounded decision classification resists `R-01` famous-plot memorization and `R-03` Chinese `1.14` regression | Runs `sd-20261108-01` & `emp-20261108-01` ([../../experiments/spoiler-decisions/results.md](../../experiments/spoiler-decisions/results.md)) | Arm B pre-filter $\text{SLR}$ spikes $8.6\times$ on famous books ($6.9\%$ vs $0.8\%$), while Arm C holds at $0.003$ and achieves Macro-$F_1 = 0.862$ on unseen fixtures; `1.13` beats `1.14` by $+0.064$ $F_1$ on `zh-Hans` ($0.851$ vs $0.787$) | `./experiments/spoiler-decisions/run.sh` |

### 2.1 Claim 1 Analysis: Spoiler Safety, Epistemic Accuracy, and Calibration

On the held-out test set ($N = 720$ queries across `doyle-study-in-scarlet`, `christie-ackroyd`, and unseen `mixu-fixtures@v0.1.0` episodes; see [../../experiments/spoiler-decisions/data.md](../../experiments/spoiler-decisions/data.md)), deterministic rules alone (Arm A) achieve $\text{SLR} = 0.000$ but suffer high false redaction ($\text{FRR} = 0.068$) and low epistemic Macro-$F_1 = 0.742$, particularly on `alibi_contradiction` ($0.735$) and `unreliable_narrator` ($0.684$) where contradictions rely on clock/distance inference rather than explicit negation tokens.

Replacing lexical rules with zero-shot `qwen2.5-72b-instruct` JSON classification (Arm B) raises Macro-$F_1$ to $0.868$ but fails four pre-registered adoption criteria: pre-filter $\text{SLR}$ reaches $0.039$ ($28/720$ queries attempting to leak future twists before the deterministic firewall blocks them), calibration is poor ($\text{ECE}_{10} = 0.078$), tail latency reaches $P_{95} = 1{,}890\text{ ms}$, and cost is $\$1.42 / 1{,}000\text{ decisions}$.

Our dedicated compact classifier `jev-decision-1.13` calibrated on the 40% Dev split ($\tau_0 = 0.58 \to \tau^* = 0.72$, temperature $T = 1.18$; Arm C) achieves $\text{ECE}_{10} = 0.031$, pre-filter $\text{SLR} = 0.003$ ($2/720$), Macro-$F_1 = 0.858$ ($\Delta F_1 = +0.116$ over Arm A), $P_{95} = 142\text{ ms}$, and $\$0.09 / 1{,}000\text{ decisions}$. Escalating only the $18.3\%$ of queries whose calibrated confidence falls inside $p \in [0.45, 0.72)$ to `qwen2.5-72b-instruct` (Arm D) achieves the best overall performance: Macro-$F_1 = 0.889$ ($\Delta F_1 = +0.147$), $\text{FRR} = 0.021$, $\text{ECE}_{10} = 0.024$, $P_{95} = 485\text{ ms}$, and $\$0.34 / 1{,}000\text{ decisions}$ ([../../experiments/spoiler-decisions/results.md](../../experiments/spoiler-decisions/results.md)).

### 2.2 Claim 2 Analysis: Long-Context Extraction Decay and Retry Economics

Evaluating five extraction arms across $W = 150$ chapter windows ($1{,}354$ gold edges; see [../../experiments/extraction-model-pool/results.md](../../experiments/extraction-model-pool/results.md)) demonstrates why raw token pricing and advertised $128\text{k}$ context lengths are misleading metrics for narrative knowledge engineering. When `qwen2.5-72b-instruct` processes whole novels in a single $64\text{k–}128\text{k}$ pass (Arm E4), middle-depth chapters ($30\%\text{–}70\%$ book progress) suffer severe attention dilution: mid-book edge recall falls from $0.831$ to $0.584$ (missing $34.6\%$ of planted clues and alibis) and mid-book Edge Macro-$F_1$ drops by $-0.194$ ($0.618$ vs $0.812$ in chapter-chunked Arm E2). Simultaneously, first-pass window acceptance drops from $92.0\%$ to $46.7\%$ due to paraphrased quotes (`EVIDENCE_NOT_SUBSTRING` in $25.3\%$ of windows / $14.8\%$ of spans) and cross-chapter timestamp contamination (`HORIZON_VIOLATION` $= 6.4\%$ of edges), driving retry-adjusted cost up to $\$0.96$ per novel ($2.18\times$ Arm E2's $\$0.44$).

## 3. Related Work and Explicit Disagreements

We situate our work against four bodies of prior literature summarized in `papers/literature/` and state directly where our empirical findings disagree with prevailing assumptions:

1. **Progress-Anchored Reading Interfaces ([boyd-2023-spoiler-aware-reading-interfaces.md](../../papers/literature/boyd-2023-spoiler-aware-reading-interfaces.md)):** Boyd et al. (CHI 2023) established that static character glossaries induce explicit or structural spoilers in $34.2\%$ of reader lookups and showed that prefix-truncated RAG LLMs still leak famous twists in $8.7\%$ of queries. **Where we agree and extend:** We replicate their parametric leakage finding ($6.9\%$ pre-filter leakage in Arm B on canonical novels). **Where we disagree:** Boyd et al. concluded that achieving $0.0\%$ spoiler leakage required manual human curation of progress-indexed tuple tables. We demonstrate that automated LLM chapter extraction paired with verbatim character-offset substring verification and deterministic projection $P(G, h)$ achieves post-filter $\text{SLR} = 0.000$ without manual tuple authoring.
2. **Cross-Task Threshold Transfer in Calibrated Classifiers ([jev-2025-threshold-transfer.md](../../papers/literature/jev-2025-threshold-transfer.md)):** Jev et al. (EMNLP 2025) showed across 37 benchmarks that transferring a fixed probability cutoff $\tau^*_{\text{src}}$ across domains causes a median $6.8$-point Macro-$F_1$ drop and violates FPR bounds in $78.4\%$ of target tasks. **Where we agree:** Transferring the FEVER default cutoff ($\tau_0 = 0.58$) to mystery fiction failed our Dev pre-filter SLR bound ($0.014 > 0.005$) and calibration gate ($\text{ECE}_{10} = 0.084$). **Where we disagree:** Jev et al. argue for dynamic per-document threshold adaptation at inference time; we find that in narrative fiction, per-book unsupervised logit shifting is unstable on short early horizons ($h \le 20\%$) and that a single phenomenon-stratified in-domain calibration ($\tau^* = 0.72$, $T = 1.18$) transfers cleanly across both 19th-century classics and unseen modern synthetic stories ($\text{ECE}_{10} = 0.031$).
3. **Chinese Compact Decision Model Regressions ([chen-2025-chinese-decision-benchmark.md](../../papers/literature/chen-2025-chinese-decision-benchmark.md)):** Chen et al. (ACL Findings 2025) demonstrated on C-DecideBench that point release `1.14` regressed by $-9.4$ points against `1.13` on literary Chinese epistemic attribution due to classical/idiomatic double negation (`未尝不`, `莫非`) and zero-pronoun indirect speech. **Where we agree:** We confirm a $-0.064$ Macro-$F_1$ regression ($0.787$ vs $0.851$) and a $3\times$ polarity-flip surge ($18.8\%$ vs $6.3\%$) on our `mixu-fixtures` `zh-Hans` slice. **Where we disagree:** Chen et al. recommend full-parameter continual pretraining of compact classifiers on classical prose; we show that pairing pinned `jev-decision-1.13` with selective uncertainty escalation ($p \in [0.45, 0.72)$) to `deepseek-v3-0324` resolves idiomatic negation traps at a fraction of the engineering cost.
4. **Long-Context Extraction Decay ([liu-2024-long-context-extraction-decay.md](../../papers/literature/liu-2024-long-context-extraction-decay.md)):** Liu et al. (TACL 2024) quantified the U-shaped primacy/recency curve in long-context transformers, showing $18\text{–}35$-point accuracy drops at $30\%\text{–}70\%$ interior depth. **Where we agree:** Our Arm E4 ($128\text{k}$ single-pass) exhibits a $-0.194$ mid-book Edge $F_1$ drop and $2.4\times+$ surge in ungrounded span citations. **Where we disagree with current "long-context RAG-free" practice:** Recent application papers advocate dumping entire novels into $128\text{k–}1\text{M}$ context windows for zero-chunking KG construction; our cost-and-horizon audit proves that single-pass whole-book extraction not only degrades mid-book recall by $34.6\%$ but also introduces cross-chapter `HORIZON_VIOLATION` timestamp contamination ($6.4\%$) and costs $2.18\times$ more per accepted graph once validation retries are counted.

## 4. Limitations and Threats to Validity

We state four limitations of our architecture and evaluation upfront:

1. **Pretraining Memorization (`R-01`) on Canonical Literature:** Every commercial and open-weights foundation model has ingested Poe, Doyle, Leroux, and Christie during pretraining. Although our unseen `mixu-fixtures@v0.1.0` benchmark ($360$ test decision queries, $30$ extraction windows) proves that our epistemic and extraction gains hold on novel zero-contamination texts, our public-domain novel evaluation (`corpora/manifest.json`) inevitably measures performance on works present in pretraining corpora.
2. **The Unreliable-Narrator Omission Ceiling (`christie-ackroyd`):** When a first-person narrator deceives the reader through pure omission rather than a falsifiable statement (e.g., Dr. Sheppard omitting what occurred between 20:40 and 20:50 in Chapter 4 of `christie-ackroyd`), no text span in Chapters 1–12 contradicts his account. Our system therefore labels his early movements as `OBSERVED` until Poirot exposes the timeline gap in Chapter 25. While epistemically faithful to fair-play detective rules, our architecture cannot detect non-textual omissions prior to their narrative refutation.
3. **Edition and OCR Offset Sensitivity:** Because `TemporalProjectionEngine` validates evidence via exact character offsets `[start_char, end_char)` and substring matching within chapter $r$, applying a pre-computed graph pack to a different publisher edition or an uncleaned OCR scan with typographic variation fails validation unless normalized through canonical paragraph-hash anchoring.
4. **Scale of Non-English Full-Length Corpora:** Because pre-1931 US public-domain full-length mysteries in `corpora/manifest.json` are English works (or English translations of French works), our `zh-Hans` and `ja` evaluations currently rest on 10-chapter ($28\text{k–}29\text{k}$ token) synthetic novellas in `mixu-fixtures@v0.1.0` rather than 80-chapter serial novels.

## 5. Data and Code Availability Statement

In accordance with Mixu's copyright and open-science governance (`AGENTS.md`), **no book text, chapter excerpt file, or redistributed EPUB is stored in this repository**.

- **Corpus metadata and rights verification:** All 20 public-domain reference works—including the 5 core evaluation works (`poe-rue-morgue`, `leroux-yellow-room`, `doyle-study-in-scarlet`, `christie-styles`, `christie-ackroyd`)—are catalogued with publication year, author death year, and Gutenberg identifiers in [../../corpora/manifest.json](../../corpora/manifest.json) (`schema_version: 1`, `as_of: 2026-11-08`). Jurisdictional public-domain status across US, CN, and EU law is recomputed deterministically by [../../tools/check_corpus.py](../../tools/check_corpus.py), and eligible US public-domain EPUBs are fetched on demand into local Git-ignored cache (`corpora/cache/`) via [../../tools/fetch_corpus.py](../../tools/fetch_corpus.py).
- **Synthetic multilingual fixtures:** Rights-cleared synthetic stories (`zh-Hans`, `en`, `ja`) are released under CC0-1.0 in `mixu-fixtures` (`v0.1.0`).
- **Protocols, results, and one-command reproduction:** Full experimental protocols, dataset splits, failure taxonomies, and standalone verification scripts are archived in [../../experiments/spoiler-decisions/](../../experiments/spoiler-decisions/) and [../../experiments/extraction-model-pool/](../../experiments/extraction-model-pool/).
