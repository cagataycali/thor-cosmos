# Contributing to thor-cosmos

Thanks for your interest! This repo is small and opinionated. Please read
[`AGENTS.md`](AGENTS.md) first — it explains the architecture (justfile is the
single source of truth) and the ToolResult contract.

## Ground rules

1. **The `justfile` is the API.** If you need a command, add a recipe first,
   then wrap it in a thin Python tool. Never inline shell calls in Python.
2. **Tools return `ToolResult`.** Use `ok()` / `err()` / `proc_result()` from
   `thor_cosmos/tools/_common.py` — never hand-build the dict.
3. **Image-producing tools embed JPEG bytes.** No "saved to disk, here's the
   path" anti-pattern — the agent needs the bytes in the response.
4. **No hallucinated features in docs.** Document only what exists in the
   `justfile` or `thor_cosmos/tools/`.

## Adding a new tool

1. Add the recipe to `justfile` (under the correct family section).
2. Create `thor_cosmos/tools/<name>.py` (see AGENTS.md §"How to add a new tool").
3. Register in `thor_cosmos/tools/__init__.py` and `thor_cosmos/agent.py`.
4. Smoke-test: `just <recipe> <args>` → then `thor-cosmos` → call the tool.
5. Document the tool in `docs/api-reference.md`.

## Dev workflow

```bash
# install deps
pipx install thor-cosmos
pip install -e '.[dev]'       # if you maintain a dev extras group

# sanity
just smoke                    # env + sysinfo + serve-status
just --list                   # every recipe should print

# docs
mkdocs serve                  # live preview at http://localhost:8000
mkdocs build --strict         # CI runs this

# before PR
python -m compileall thor_cosmos
xmllint --noout docs/assets/*.svg web/assets/*.svg
```

## Commit messages

Conventional-ish, short first line, imperative mood:

- `feat: add <recipe or tool>`
- `fix: <what broke, what now works>`
- `docs: <scope>`
- `ci: <workflow change>`
- `chore: <bump/cleanup>`

## Style

- Python 3.10+, `from __future__ import annotations`, line length 100.
- Imports: stdlib → 3rd-party → local (`._common`).
- Never `raise` in a tool — return `err(...)` so the agent can recover.
- No emojis in code. Emojis in tool `text` output are fine for operator UX.
- No secrets ever — always via env vars or `.env` (which is gitignored).

## Reporting issues

Include:
- OS + arch (`uname -a`)
- `thor-cosmos --version` / commit SHA
- `just env` output (scrub secrets)
- Minimal repro (just command or one-liner)

PRs welcome.
