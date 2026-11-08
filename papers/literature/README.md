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

## Summary index and ADR traceability

Every claim that Mixu relies on from the literature is marked either `verified-in-paper`
(directly supported by the cited study's tables/experiments) or `verified-by-us`
(replicated on Mixu's mystery corpus and synthetic fixtures in `experiments/`).

| Note | Primary question | Informs ADR / OQ / Task | Key claim relied on by Mixu | Verification status |
|---|---|---|---|---|
| [jev-2025-threshold-transfer.md](jev-2025-threshold-transfer.md) | Does a decision probability threshold $\tau^*$ transfer across tasks? | `ADR-021`, `OQ-03`, `P-06`, `P-09` (`CTX-0002`) | Cross-task scalar thresholds drift by $\lvert \Delta \tau^* \rvert = 0.14 \pm 0.06$ and violate strict FPR bounds in $29/37$ datasets (`verified-in-paper`); mystery fiction requires in-domain stratified calibration ($\tau^* = 0.72$, $\text{ECE}_{10} = 0.031$, `verified-by-us`). | `verified-in-paper` & `verified-by-us` |
| [chen-2025-chinese-decision-benchmark.md](chen-2025-chinese-decision-benchmark.md) | Where did compact decision model `1.14` regress against `1.13` on Chinese prose? | `ADR-021`, `ADR-034`, `OQ-03`, `P-07`, `P-09` (`CTX-0002`, `CTX-0003`) | Model `1.14` regresses by $-9.4$ points on Chinese narrative epistemic attribution due to classical/idiomatic negation polarity flips ($22.6\%$ vs $6.1\%$) and unmarked indirect-speech over-promotion ($18.9\%$ vs $7.4\%$, `verified-in-paper`); `1.13` outperforms `1.14` by $+0.064$ macro-$F_1$ on `mixu-fixtures` `zh-Hans` (`verified-by-us`). | `verified-in-paper` & `verified-by-us` |
| [boyd-2023-spoiler-aware-reading-interfaces.md](boyd-2023-spoiler-aware-reading-interfaces.md) | Do spoiler-aware / progress-aware reading interfaces exist in the literature, and why does prefix-RAG still leak? | `ADR-021`, `OQ-03`, `P-06`, `P-10` (`CTX-0002`, `CTX-0004`) | Book-global entity graphs cause explicit or structural spoilers in $34.2\%$ of lookups, and prefix-truncated RAG LLMs still leak famous plot twists in $8.7\%$ of queries due to parametric memory (`verified-in-paper`); deterministic horizon projection (`first_seen <= h`, `reveal_at <= h`) enforces post-filter $\text{SLR} = 0.000$ (`verified-by-us`). | `verified-in-paper` & `verified-by-us` |
| [liu-2024-long-context-extraction-decay.md](liu-2024-long-context-extraction-decay.md) | How fast does multi-hop entity-relation extraction decay as context length grows? | `ADR-034`, `OQ-03`, `P-07`, `P-10` (`CTX-0003`, `CTX-0004`) | Mid-context ($30\%\text{–}70\%$ depth) extraction accuracy drops by $18\text{–}35$ points above $16\text{k–}32\text{k}$ tokens (`verified-in-paper`); single-pass $128\text{k}$ whole-book extraction degrades mid-novel edge-$F_1$ by $-0.194$ ($0.618$ vs $0.812$) and raises `EVIDENCE_NOT_SUBSTRING` from $3.1\%$ to $14.8\%$ compared with chapter-chunked $4\text{k–}8\text{k}$ windows (`verified-by-us`). | `verified-in-paper` & `verified-by-us` |
