# Our papers

Each paper gets a directory: `papers/ours/<slug>/`.

| File | Contents |
|---|---|
| `paper.md` | abstract, claims, status, authors, venue |
| `latex/` | ACL/EMNLP camera-ready LaTeX source (`main.tex`, `references.bib`, `tables/*.tex`), verified by `tools/check_paper_consistency.py` |
| `artifacts.md` | which experiments, LaTeX sources, and datasets it rests on, with links into `experiments/` |
| `review.md` | reviewer comments and how each was answered (kept after publication) |

## Index

| Paper | Title | Status | Target Venue | Primary Artifacts |
|---|---|---|---|---|
| [progress-aware-narrative-kg](progress-aware-narrative-kg/paper.md) | *Progress-Aware Narrative Knowledge Engineering: Epistemic Horizon Filtering for Mystery Fiction* | `draft` | ACL / EMNLP | [latex/main.tex](progress-aware-narrative-kg/latex/main.tex), [latex/references.bib](progress-aware-narrative-kg/latex/references.bib), [latex/tables/](progress-aware-narrative-kg/latex/tables/), [artifacts.md](progress-aware-narrative-kg/artifacts.md), [review.md](progress-aware-narrative-kg/review.md), [check_paper_consistency.py](../../tools/check_paper_consistency.py), [spoiler-decisions](../../experiments/spoiler-decisions/results.md), [extraction-model-pool](../../experiments/extraction-model-pool/results.md) |

## Rules

1. Status is one of `idea`, `draft`, `submitted`, `under-review`, `published`, `abandoned`.
   Never describe a draft as published.
2. Every number in the abstract must be traceable to an `experiments/<slug>/results.md`.
3. The data availability statement points at `corpora/manifest.json` plus the fetch script —
   never at a redistributed book.
4. A negative result that was published stays listed even if a later paper supersedes it.
