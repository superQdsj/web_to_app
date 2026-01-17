# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NGA Fetcher is a Dart CLI tool for scraping [NGA Forum](https://bbs.nga.cn) content. It exports forum thread lists and thread details as structured JSON, with support for CLI-based replies and offline HTML parsing.

## Common Commands

```bash
# Install dependencies
cd nga_fetcher_dart && fvm dart pub get

# Run tests
cd nga_fetcher_dart && fvm dart test

# Run linting/analysis
cd nga_fetcher_dart && fvm dart analyze

# Format code
cd nga_fetcher_dart && fvm dart format .
```

## Running the Tool

**Prerequisites:**
- `fvm` (Flutter Version Manager) installed
- Cookie file at `private/nga_cookie.txt` (supports raw cookie, `Cookie:` header, or cURL format)

**Usage via wrapper scripts:**
```bash
# Export forum (fid=7 is water forum)
./scripts/fetch_dart fid7
./scripts/fetch_dart fid=390

# Export thread
./scripts/fetch_dart tid=45060283

# Reply to thread
./scripts/reply --tid 45960168 --fid -444012 --content "回复内容"
```

## Architecture

```
nga_fetcher_dart/
├── bin/nga_fetcher_dart.dart    # CLI entry point, argument parsing
├── lib/src/
│   ├── codec/                   # GBK/GB18030/UTF-8 encoding handling
│   ├── cookie/                  # Cookie parsing (cURL/Header/Raw formats)
│   ├── http/                    # HTTP client wrapper with cookie/timeout
│   ├── model/                   # Data classes (ThreadItem, ThreadDetail)
│   ├── parser/                  # HTML parsers (ForumParser, ThreadParser)
│   └── util/                    # Utilities
└── test/                        # Dart tests
```

**Data flow:** CLI → HTTP client → NGA server → Codec (encoding) → Parser (HTML) → Models → JSON output

## Key Conventions

- **Naming:** `lowerCamelCase` for vars/functions, `UpperCamelCase` for types, `snake_case` for files
- **Commits:** Conventional Commits (`feat:`, `fix:`, `chore:`)
- **Secrets:** Never commit cookies; use `private/` folder (git-ignored)

## Output Format

Results saved to `out/`:
- `meta.json` - URL, status, timestamp, thread count
- `threads.json` - Thread list (tid, title, author, replies, etc.)
- `thread.json` - Thread with all posts (floor, author, content_text)
