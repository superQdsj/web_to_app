# Repository Guidelines

## Project Structure & Module Organization

- `mvp_nga_fetcher/main.py`: main CLI entrypoint (`nga-fetcher`) plus HTML fetching, decoding (GBK/GB18030), and forum thread parsing.
- `fetch`: convenience wrapper that exports a forum page into `out/` (see examples below).
- `mvp_nga_fetcher/nga_cookie.txt`: local cookie input file (do not commit secrets).
- `out/`: generated artifacts (`meta.json`, `threads.json`, optional `forum.html`) and is git-ignored.

## Build, Test, and Development Commands

- Create an environment: `python3 -m venv .venv && source .venv/bin/activate`
- Install deps: `pip install -r requirements.txt`
- Configure auth (pick one):
  - `.env` with `NGA_COOKIE=...` (start from `.env.example`), or
  - `mvp_nga_fetcher/nga_cookie.txt` containing a `Cookie:` line or copied cURL snippet with `-b '...'`.
- Export a forum page (recommended): `./fetch fid7` (or `./fetch fid=7 out/nga_custom`)
- Debug fetch/parse: `python3 mvp_nga_fetcher/main.py fetch "<url>" --json --parse-threads`
- Serve locally (for quick inspection): `python3 mvp_nga_fetcher/main.py serve "<url>" --port 8080`

## Coding Style & Naming Conventions

- Python: 4-space indentation, type hints encouraged (the codebase uses modern annotations like `list[str]`).
- Naming: `snake_case` for functions/vars, `PascalCase` for dataclasses, constants in `SCREAMING_SNAKE_CASE`.
- Keep changes focused: prefer small pure helpers and update `fetch`/CLI help text when user-facing behavior changes.
- Optional linting (if installed locally): `python -m ruff check .`

## Testing Guidelines

- No automated test suite is committed yet. For new behavior, add `pytest`-style tests under `tests/` with `test_*.py`.
- At minimum, include a reproducible manual check in your PR description (exact command + expected files written).

## Commit & Pull Request Guidelines

- No established commit history yet; use Conventional Commits (e.g., `feat: ...`, `fix: ...`, `chore: ...`).
- PRs should include: intent/summary, how to run (commands), and any parsing/compatibility notes.
- Never commit secrets: `.env`, cookie headers, or copied cURL snippets; redact `Cookie` values in logs and screenshots.
