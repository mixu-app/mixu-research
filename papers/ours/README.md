# Our papers

Each paper gets a directory: `papers/ours/<slug>/`.

| File | Contents |
|---|---|
| `paper.md` | abstract, claims, status, authors, venue |
| `artifacts.md` | which experiments and datasets it rests on, with links into `experiments/` |
| `review.md` | reviewer comments and how each was answered (kept after publication) |

## Rules

1. Status is one of `idea`, `draft`, `submitted`, `under-review`, `published`, `abandoned`.
   Never describe a draft as published.
2. Every number in the abstract must be traceable to an `experiments/<slug>/results.md`.
3. The data availability statement points at `corpora/manifest.json` plus the fetch script —
   never at a redistributed book.
4. A negative result that was published stays listed even if a later paper supersedes it.
