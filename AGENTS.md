# Repository Guidelines

## Project Structure & Module Organization

- `nga_fetcher_dart/`: Dart CLI + parsing library (current implementation).
- `scripts/fetch_dart`: convenience wrapper around the Dart CLI that exports into `out/`.
- `scripts/reply`: reply helper (uses cookie auth).
- `private/nga_cookie.txt`: local cookie input file (sensitive; git-ignored; do not commit secrets).
- `out/`: generated artifacts (`meta.json`, `threads.json`, optional `forum.html`/`thread.html`) and is git-ignored.

Optional/legacy Python notes (only if present in the repo):
- `mvp_nga_fetcher/main.py`: main CLI entrypoint (`nga-fetcher`) plus HTML fetching/decoding (GBK/GB18030) and forum thread parsing.
- `scripts/fetch`: convenience wrapper that exports a forum page into `out/`.
- `mvp_nga_fetcher/nga_cookie.txt`: local cookie input file (do not commit secrets).

## Build, Test, and Development Commands

- Dart (recommended):
  - Ensure `fvm` is installed and Flutter/Dart SDK is set up.
  - Install deps: `cd nga_fetcher_dart && fvm dart pub get`
  - Configure auth (pick one):
    - Put your copied cURL snippet (with `-b '...'`) or a `Cookie:` line into `private/nga_cookie.txt`, or
    - Pass `--cookie-file <path>` to the CLI/scripts.
  - Export forum or thread:
    - `./scripts/fetch_dart fid7`
    - `./scripts/fetch_dart tid=45060283`
  - Run tests: `cd nga_fetcher_dart && fvm dart test`
  - Reply (manual check): `./scripts/reply --tid <tid> --fid <fid> --content "text"`

Optional/legacy Python (only if present in the repo):
- Create an environment: `python3 -m venv .venv && source .venv/bin/activate`
- Install deps: `pip install -r requirements.txt`
- Configure auth (pick one):
  - `.env` with `NGA_COOKIE=...` (start from `.env.example`), or
  - `mvp_nga_fetcher/nga_cookie.txt` containing a `Cookie:` line or copied cURL snippet with `-b '...'`.
- Export a forum page (recommended): `./scripts/fetch fid7` (or `./scripts/fetch fid=7 out/nga_custom`)
- Debug fetch/parse: `python3 mvp_nga_fetcher/main.py fetch "<url>" --json --parse-threads`
- Serve locally (for quick inspection): `python3 mvp_nga_fetcher/main.py serve "<url>" --port 8080`

## Coding Style & Naming Conventions

- Python: 4-space indentation, type hints encouraged (the codebase uses modern annotations like `list[str]`).
- Dart: follow existing style; keep formatting consistent (use `dart format` if needed).
- Naming: `snake_case` for functions/vars, `PascalCase` for dataclasses, constants in `SCREAMING_SNAKE_CASE`.
- Keep changes focused: prefer small pure helpers and update `fetch`/CLI help text when user-facing behavior changes.
- Optional linting (if installed locally): `python -m ruff check .`

## Testing Guidelines

- Dart tests live under `nga_fetcher_dart/`; run with `cd nga_fetcher_dart && fvm dart test`.
- For Python changes (if/when present), add `pytest`-style tests under `tests/` with `test_*.py`.
- At minimum, include a reproducible manual check in your PR description (exact command + expected files written).

## Commit & Pull Request Guidelines

- No established commit history yet; use Conventional Commits (e.g., `feat: ...`, `fix: ...`, `chore: ...`).
- PRs should include: intent/summary, how to run (commands), and any parsing/compatibility notes.
- Never commit secrets: `.env`, cookie headers, or copied cURL snippets; redact `Cookie` values in logs and screenshots.
