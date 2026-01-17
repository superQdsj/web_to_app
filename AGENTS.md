# Repository Guidelines

## Project Structure & Module Organization

- `nga_fetcher_dart/`: Dart CLI + parsing library (current implementation).
- `scripts/fetch_dart`: convenience wrapper around the Dart CLI that exports into `out/`.
- `scripts/reply`: reply helper (uses cookie auth).
- `.env`: local cookie input (sensitive; git-ignored; do not commit secrets).
- `out/`: generated artifacts (`meta.json`, `threads.json`, optional `forum.html`/`thread.html`) and is git-ignored.

## Build, Test, and Development Commands

- Ensure `fvm` is installed and Flutter/Dart SDK is set up.
- Install deps: `cd nga_fetcher_dart && fvm dart pub get`
- Configure auth:
  - Put your cookie into `.env` as `NGA_COOKIE=...` (supports raw cookie, `Cookie:` header, or cURL snippet with `-b '...'`).
- Export forum or thread:
  - `./scripts/fetch_dart fid7`
  - `./scripts/fetch_dart tid=45060283`
- Reply (manual check): `./scripts/reply --tid <tid> --fid <fid> --content "text"`
- Run tests: `cd nga_fetcher_dart && fvm dart test`

## Coding Style & Naming Conventions

- Dart: follow existing style; keep formatting consistent (use `fvm dart format .` if needed).
- Naming (Dart): `lowerCamelCase` for vars/functions, `UpperCamelCase` for types, `snake_case` for filenames.
- Keep changes focused: prefer small pure helpers and update `fetch`/CLI help text when user-facing behavior changes.
- Optional linting (if installed locally): `cd nga_fetcher_dart && fvm dart analyze`

## Testing Guidelines

- Dart tests live under `nga_fetcher_dart/`; run with `cd nga_fetcher_dart && fvm dart test`.
- At minimum, include a reproducible manual check in your PR description (exact command + expected files written).

## Commit & Pull Request Guidelines

- No established commit history yet; use Conventional Commits (e.g., `feat: ...`, `fix: ...`, `chore: ...`).
- PRs should include: intent/summary, how to run (commands), and any parsing/compatibility notes.
- Never commit secrets: cookie headers or copied cURL snippets; redact `Cookie` values in logs and screenshots.
