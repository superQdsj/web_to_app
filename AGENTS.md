# Repository Guidelines

## Project Structure & Module Organization

- `nga_fetcher_dart/`: Dart CLI + parsing library.
- `fetch_dart`: convenience wrapper around the Dart CLI.
- `nga_cookie.txt`: local cookie input file (sensitive; git-ignored).
- `out/`: generated artifacts (`meta.json`, `threads.json`, optional `forum.html`/`thread.html`) and is git-ignored.

## Build, Test, and Development Commands

- Ensure `fvm` is installed and Flutter/Dart SDK is set up.
- Install deps: `cd nga_fetcher_dart && fvm dart pub get`
- Configure auth:
  - Put your copied cURL snippet (with `-b '...'`) or a `Cookie:` line into `nga_cookie.txt`.
- Export forum or thread (recommended):
  - `./fetch_dart fid7`
  - `./fetch_dart tid=45060283`
- Run tests: `cd nga_fetcher_dart && fvm dart test`

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
