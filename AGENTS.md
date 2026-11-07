# mixu-research agent guide

## Scope and authority

- Governs only this repository. Workspace rules in `../AGENTS.md` apply.
- Public repository. Code and scripts are Apache-2.0; prose and paper notes are
  CC-BY-4.0; corpus metadata is CC0-1.0.
- Research lives here; product behaviour lives in the component repositories. A finding
  here informs an ADR, it does not amend one.

## Hard rules

1. **No book text.** Not a chapter, not a paragraph, not a "sample" file, not a fetched
   EPUB. `corpora/cache/` is ignored and never committed. A short quote inside an analysis
   is allowed with attribution and must not substitute for the work.
2. **Rights are computed, not asserted.** Every corpus entry carries first-publication year
   and author death year; `tools/check_corpus.py` recomputes US/CN/EU status. A hand-written
   flag that disagrees with the arithmetic fails the gate.
3. **No claim without a number or a citation.** "Better" needs a metric and a comparison; a
   literature note needs a citation with year and venue.
4. **Failures are recorded.** A negative result is a result; deleting a failed experiment to
   keep the repository tidy is falsification.
5. **Reproducibility metadata is mandatory**: model id, provider, prompt version, corpus
   version, and the date, for every number quoted.

## Structure

| Path | Rule |
|---|---|
| `corpora/manifest.json` | metadata only; `role` explains why the work is here |
| `papers/literature/<slug>.md` | one file per paper: citation, claim, relevance, reproduction status |
| `papers/ours/` | abstract, claims, status (`draft`/`submitted`/`published`), artifact links |
| `experiments/<slug>/` | `protocol.md`, `data.md`, `results.md`, optional `run.sh` |
| `tools/` | scripts; standard library only unless a lockfile is added |

## Gates

```sh
just check     # markdownlint + corpus manifest validation
just corpus    # recompute and print the rights table
just fetch --list
```

## Writing

English for technical notes, protocols and results. The repository README may be Chinese.
A literature note states what the paper claims *in its own terms* before saying anything
about Mixu; paraphrasing a paper into our vocabulary hides disagreements.

## CarryCtx

- `cd` here before `carryctx` or Git; branches `ctx-XXXX/<type>-<slug>`.
- No commit, push or release without authorization.
