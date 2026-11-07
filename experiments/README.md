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
| _(none yet)_ | | |

The first three experiments queued by the product backlog are the spoiler-decision
comparison (A/B/C/D), the extraction model pool benchmark, and typed extraction versus
LLM plus JSON parsing.
