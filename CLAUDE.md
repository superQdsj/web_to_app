# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MVP web scraper for NGA forum (bbs.nga.cn). Fetches forum thread lists and parses HTML to structured JSON.

## Commands

**Run the application:**
```bash
python3 mvp_nga_fetcher/main.py <command>
```

**Shell wrapper (common operations):**
```bash
./fetch fid7 [out_dir]              # Fetch fid=7 forum
./fetch fid=<num> [out_dir]         # Fetch specific forum ID
./fetch url <forum_url> [out_dir]   # Fetch custom URL
```

**Subcommands:**
- `fetch` - Fetch a URL and output headers/body (supports `--json`, `--out`, `--parse-threads`)
- `serve` - Local HTTP proxy for a fetched URL (default: `http://127.0.0.1:8080`)
- `export` - Fetch + parse + write structured results (threads.json, meta.json, forum.html)

**Install dependencies:**
```bash
pip install -r requirements.txt
```

## Architecture

```
main.py
├── fetch()              # Core HTTP fetcher with cookie handling
├── parse_thread_list_from_forum_html()  # HTML parser for thread lists
└── CLI commands: fetch, serve, export
```

**Cookie sources (priority order):**
1. `--cookie-header` argument
2. `--cookie-file` (supports raw cookie, Cookie header, or cURL snippet with `-b`)
3. `NGA_COOKIE` environment variable
4. `--load-cookies` JSON file

**Encoding handling:** NGA uses GBK/GB18030; the code attempts multiple encodings as fallback.

## Key Files

- `mvp_nga_fetcher/main.py` - Main application
- `mvp_nga_fetcher/nga_cookie.txt` - Cookie file template (copy cURL with `-b '...'`)
- `out/` - Default output directory for exported data
