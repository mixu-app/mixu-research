# Experiments

One directory per experiment: `experiments/<slug>/`. The registry below is the index; a
directory without an entry, or an entry without a directory, is a defect.

## Required files

| File | Contents |
|---|---|
| `protocol.md` | hypothesis, arms, metrics, decision threshold, what result would change our mind |
| `data.md` | corpus ids from `corpora/manifest.json`, versions, fetch date, known biases |
| `results.md` | numbers, tables, the verdict, and what failed |
| `run.sh` | one command to reproduce, if it can be automated |

## Protocol template

```markdown
# <experiment>

**Question:** one sentence, answerable by a number.

**Arms:** what is compared with what, including the floor (rules only).

**Data:** corpus ids, size, split rule.

**Metrics:** ordered by importance, with the formula or the tool that computes it.

**Decision rule:** "adopt if X ≥ …, reject if …, revisit if …" written before the run.

**Known confounds:** what would make a positive result misleading.
```

## Registry

| Experiment | Question | Status |
|---|---|---|
| [spoiler-decisions](spoiler-decisions/protocol.md) | Does a calibrated compact decision model (`jev-decision-1.13` at $\tau^* = 0.72$, alone or with selective uncertainty escalation) behind Mixu's deterministic horizon filter improve epistemic Macro-$F_1$ by $\ge +0.040$ over deterministic rules while keeping post-filter $\text{SLR} = 0.000$ and pre-filter $\text{SLR} \le 0.005$? | Completed (`Adopt Arm C / Arm D`, run `sd-20261108-01`) |
| [extraction-model-pool](extraction-model-pool/protocol.md) | Which candidate extraction model and context-window strategy achieves overall Edge Macro-$F_1 \ge 0.800$, mid-book ($30\%\text{–}70\%$) Edge Macro-$F_1 \ge 0.780$, and retry-adjusted cost $\le \$0.50$ per accepted 24-chapter novel graph without ungrounded spans or horizon violations? | Completed (`Adopt Arm E2 + Arm E3 chapter-chunked pool; Reject Arm E1 & Arm E4 128k single-pass`, run `emp-20261108-01`) |
| [shin-honkaku-structures](shin-honkaku-structures/protocol.md) | Does extending flat $(t_{\text{story}}, r)$ indexing to the 5D Multi-Frame Shin-Honkaku Coordinate $(t_{\text{story}}, \ell_{\text{loop}}, d_{\text{layer}}, f_{\text{frame}}, r)$ with `PERSONA` delayed coreference and `jev-hybrid-1.13+1.14` (`choice`/`score`/`box` + `1.13` `noul`) eliminate premature identity merges ($\text{PFIMR} = 0.0\%$) and cross-loop/hypothesis collisions ($\text{CCR} = 0.0\%$) across 69 adversarial Shin-Honkaku mystery works? | Completed (`Adopt Arm SH3 5D Coordinate + jev-hybrid-1.13+1.14`, run `sh-20261110-01`) |

The first three experiments queued by the product backlog are the spoiler-decision
comparison (A/B/C/D), the extraction model pool benchmark, and typed extraction versus
LLM plus JSON parsing.
