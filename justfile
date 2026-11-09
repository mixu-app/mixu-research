# mixu-research gates
set shell := ["bash", "-euo", "pipefail", "-c"]

check: lint-md corpus paper

lint-md:
    markdownlint-cli2 --config .markdownlint-cli2.jsonc

corpus:
    python3 tools/check_corpus.py

paper:
    python3 tools/check_paper_consistency.py

fetch id="":
    python3 tools/fetch_corpus.py {{id}}
