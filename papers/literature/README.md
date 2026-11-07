# Literature notes

One file per paper, named `<first-author>-<year>-<short-slug>.md`. A note that only
summarises the abstract is not worth writing; the value is in the last two sections.

## Template

```markdown
# <Title>

- **Citation:** authors, venue, year, DOI or arXiv id
- **Artifact:** code / dataset link, or "none"
- **Read on:** YYYY-MM-DD

## What it claims, in its own terms

Two or three sentences using the paper's vocabulary, not ours. If the paper says
"event extraction", do not write "graph construction".

## Method

Task, data, model, metric. Enough that a reader can judge the comparison.

## Relevance to Mixu

Which of our open questions this touches. Name the question, not the feature.

## Reproduce?

- [ ] Not attempted
- [ ] Attempted: what we ran, what we saw (numbers), what differed
```

## Already in the backlog

The first notes to write, because they decide open questions:

1. The Jev evaluation across 37 datasets — does a threshold transfer between tasks?
2. The Chinese decision benchmark comparing 1.13 and 1.14 — where did it regress?
3. Any study of spoiler-aware or progress-aware reading interfaces — does the concept exist
   in the literature under another name?
4. Long-context extraction quality papers — how much does accuracy fall as context grows?
