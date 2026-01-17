#!/usr/bin/env python3
"""MVP: fetch HTML from an NGA URL without a browser.

Notes:
- NGA may deny unauthenticated access for some endpoints (e.g. ERROR:15).
- This tool focuses on retrieving the raw response body + headers, handling
  common encodings (GBK/GB18030), and persisting cookies.

Usage:
  python3 main.py fetch "https://bbs.nga.cn/thread.php?fid=7" --out out.html

"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
from dataclasses import dataclass
from http.cookiejar import CookieJar
from html import unescape
from typing import Dict, List, Optional, Tuple
from urllib.error import HTTPError, URLError
from urllib.parse import urlparse
from urllib.request import HTTPCookieProcessor, Request, build_opener

from dotenv import load_dotenv

load_dotenv()

DEFAULT_UA = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/120.0.0.0 Safari/537.36"
)


def _normalize_cookie_header(cookie: str) -> str:
    c = cookie.strip()
    if not c:
        return ""
    if c.lower().startswith("cookie:"):
        c = c.split(":", 1)[1].strip()
    return " ".join(c.split())


def _load_cookie_header_from_file(path: str) -> str:
    with open(path, "r", encoding="utf-8") as f:
        raw = f.read()

    # Support:
    # 1) raw cookie value: "a=1; b=2"
    # 2) full header line: "Cookie: a=1; b=2"
    # 3) a copied cURL snippet containing: -b 'a=1; b=2'
    m = re.search(r"-b\s+['\"]([^'\"]+)['\"]", raw)
    if m:
        return _normalize_cookie_header(m.group(1))

    return _normalize_cookie_header(raw)


@dataclass
class FetchResult:
    url: str
    status: int
    headers: Dict[str, str]
    body: bytes


@dataclass
class ThreadItem:
    tid: int
    url: str
    title: str
    replies: Optional[int]
    author: Optional[str]
    author_uid: Optional[int]
    post_ts: Optional[int]
    last_replyer: Optional[str]


def _decode_best_effort(body: bytes, content_type: Optional[str]) -> str:
    # NGA frequently uses GBK / GB18030.
    if content_type and "charset=" in content_type.lower():
        charset = content_type.split("charset=")[-1].split(";")[0].strip()
        for enc in (charset, charset.lower(), "gb18030", "gbk", "utf-8"):
            try:
                return body.decode(enc)
            except Exception:
                pass

    for enc in ("gb18030", "gbk", "utf-8"):
        try:
            return body.decode(enc)
        except Exception:
            continue

    return body.decode("utf-8", errors="replace")


def fetch(
    url: str,
    *,
    cookie_jar_path: Optional[str] = None,
    load_cookies_path: Optional[str] = None,
    cookie_header: Optional[str] = None,
    cookie_file: Optional[str] = None,
    timeout: int = 30,
) -> FetchResult:
    cookie_jar = CookieJar()
    opener = build_opener(HTTPCookieProcessor(cookie_jar))

    headers = {
        "User-Agent": DEFAULT_UA,
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8",
    }

    # Cookie sources, in priority order:
    # 1) Explicit cookie header string
    # 2) Cookie file containing header/value
    # 3) NGA_COOKIE from .env
    # 4) cookies JSON previously exported by this tool
    if cookie_header:
        headers["Cookie"] = _normalize_cookie_header(cookie_header)
    elif cookie_file:
        loaded = _load_cookie_header_from_file(cookie_file)
        if loaded:
            headers["Cookie"] = loaded
    elif os.getenv("NGA_COOKIE"):
        headers["Cookie"] = _normalize_cookie_header(os.getenv("NGA_COOKIE"))
    elif load_cookies_path:
        with open(load_cookies_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        cookies = data.get("cookies", [])
        pairs = [
            f"{c['name']}={c['value']}"
            for c in cookies
            if c.get("name") and c.get("value") is not None
        ]
        if pairs:
            headers["Cookie"] = "; ".join(pairs)

    req = Request(url, headers=headers)

    try:
        with opener.open(req, timeout=timeout) as resp:
            body = resp.read()
            resp_headers = {k: v for k, v in resp.headers.items()}
            status = resp.status
    except HTTPError as e:
        body = e.read()
        resp_headers = {k: v for k, v in e.headers.items()}
        status = e.code
    except URLError as e:
        raise RuntimeError(f"Network error fetching {url}: {e}")

    # Best-effort cookie persistence (very MVP).
    if cookie_jar_path:
        # We store cookies as JSON for simplicity.
        cookies_out = []
        for c in cookie_jar:
            cookies_out.append(
                {
                    "domain": c.domain,
                    "path": c.path,
                    "name": c.name,
                    "value": c.value,
                    "secure": bool(c.secure),
                    "expires": c.expires,
                }
            )
        os.makedirs(os.path.dirname(cookie_jar_path), exist_ok=True)
        with open(cookie_jar_path, "w", encoding="utf-8") as f:
            json.dump(
                {"url": url, "fetched_at": int(time.time()), "cookies": cookies_out},
                f,
                ensure_ascii=False,
                indent=2,
            )

    return FetchResult(url=url, status=status, headers=resp_headers, body=body)


def parse_thread_list_from_forum_html(
    html_text: str, base_url: str = "https://bbs.nga.cn"
) -> List[ThreadItem]:
    # We target the rows under <table id='topicrows'> (topicliststart marker).
    # Each thread row follows the pattern:
    # - replies: <a id='t_rc1_i' ... href='/read.php?tid=123' class='replies'>514</a>
    # - title:   <a href='/read.php?tid=123' id='t_tt1_i' class='topic'>...</a>
    # - author:  <a href='/nuke.php?func=ucp&uid=...' class='author' ...>name</a>
    # - post ts: <span class='silver postdate' ...>1757489679</span>
    # - last replyer: <span class='replyer' ...>name</span>

    # Extract from the main forum table (per requirement: table.forumbox).
    # This keeps us focused on the topic list area.
    m = re.search(
        r"<table[^>]+class='forumbox[^']*'[^>]*>.*?</table>", html_text, re.I | re.S
    )
    region = m.group(0) if m else html_text

    row_re = re.compile(r"<tr\s+class='row\d+\s+topicrow'>.*?</tr>", re.I | re.S)
    rows = row_re.findall(region)

    def _to_int(s: str) -> Optional[int]:
        s = s.strip()
        if not s:
            return None
        try:
            return int(s)
        except ValueError:
            return None

    def _abs_url(path: str) -> str:
        if path.startswith("http://") or path.startswith("https://"):
            return path
        if not path.startswith("/"):
            path = "/" + path
        return base_url.rstrip("/") + path

    items: List[ThreadItem] = []
    for row in rows:
        # Prefer title link to get tid & title.
        mt = re.search(
            r"<a[^>]+href='(?P<href>/read\.php\?tid=(?P<tid>\d+)[^']*)'[^>]*class='topic'[^>]*>(?P<title>.*?)</a>",
            row,
            re.I | re.S,
        )
        if not mt:
            continue

        tid = int(mt.group("tid"))
        href = mt.group("href")
        title_html = mt.group("title")
        title = unescape(re.sub(r"<.*?>", "", title_html)).strip()

        mr = re.search(r"class='replies'[^>]*>(\d+)</a>", row, re.I)
        replies = _to_int(mr.group(1)) if mr else None

        ma = re.search(
            r"<a[^>]+href='[^']*uid=(?P<uid>\d+)[^']*'[^>]*class='author'[^>]*>(?P<name>.*?)</a>",
            row,
            re.I | re.S,
        )
        author = None
        author_uid = None
        if ma:
            author = unescape(re.sub(r"<.*?>", "", ma.group("name"))).strip()
            author_uid = _to_int(ma.group("uid"))

        mp = re.search(r"class='silver\s+postdate'[^>]*>(\d+)</span>", row, re.I)
        post_ts = _to_int(mp.group(1)) if mp else None

        mrr = re.search(r"class='replyer'[^>]*>(.*?)</span>", row, re.I | re.S)
        last_replyer = (
            unescape(re.sub(r"<.*?>", "", mrr.group(1))).strip() if mrr else None
        )

        items.append(
            ThreadItem(
                tid=tid,
                url=_abs_url(href),
                title=title,
                replies=replies,
                author=author,
                author_uid=author_uid,
                post_ts=post_ts,
                last_replyer=last_replyer,
            )
        )

    return items


def _cmd_fetch(args: argparse.Namespace) -> int:
    result = fetch(
        args.url,
        cookie_jar_path=args.cookies,
        load_cookies_path=args.load_cookies,
        cookie_header=args.cookie_header,
        cookie_file=args.cookie_file,
        timeout=args.timeout,
    )

    if args.json:
        # base64 body would be too big; only emit decoded preview.
        content_type = result.headers.get("Content-Type")
        decoded = _decode_best_effort(result.body, content_type)
        out = {
            "url": result.url,
            "status": result.status,
            "headers": result.headers,
            "body_preview": decoded[:1000],
            "body_bytes": len(result.body),
        }
        if args.parse_threads:
            out["threads"] = [
                t.__dict__ for t in parse_thread_list_from_forum_html(decoded)
            ]
        sys.stdout.write(json.dumps(out, ensure_ascii=False, indent=2) + "\n")
    else:
        sys.stdout.write(f"status={result.status}\n")
        for k, v in result.headers.items():
            sys.stdout.write(f"{k}: {v}\n")
        sys.stdout.write("\n")
        content_type = result.headers.get("Content-Type")
        sys.stdout.write(_decode_best_effort(result.body, content_type))

    if args.out:
        with open(args.out, "wb") as f:
            f.write(result.body)

    return 0


def _cmd_serve(args: argparse.Namespace) -> int:
    from http.server import BaseHTTPRequestHandler, HTTPServer

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self) -> None:  # noqa: N802
            url = args.url
            result = fetch(
                url,
                cookie_jar_path=args.cookies,
                load_cookies_path=args.load_cookies,
                cookie_header=args.cookie_header,
                cookie_file=args.cookie_file,
                timeout=args.timeout,
            )
            self.send_response(result.status)
            # Forward content-type if present, else default.
            ct = result.headers.get("Content-Type") or "text/html"
            self.send_header("Content-Type", ct)
            self.end_headers()
            self.wfile.write(result.body)

        def log_message(self, format: str, *rest) -> None:  # silence default logs
            if args.verbose:
                super().log_message(format, *rest)

    server = HTTPServer((args.host, args.port), Handler)
    print(f"Serving {args.url} at http://{args.host}:{args.port}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        return 0

    return 0


def _cmd_export(args: argparse.Namespace) -> int:
    result = fetch(
        args.url,
        cookie_file=args.cookie_file,
        cookie_header=args.cookie_header,
        load_cookies_path=args.load_cookies,
        timeout=args.timeout,
    )

    content_type = result.headers.get("Content-Type")
    html_text = _decode_best_effort(result.body, content_type)
    threads = parse_thread_list_from_forum_html(html_text)

    os.makedirs(args.out_dir, exist_ok=True)
    meta = {
        "url": args.url,
        "status": result.status,
        "fetched_at": int(time.time()),
        "thread_count": len(threads),
    }

    meta_path = os.path.join(args.out_dir, "meta.json")
    with open(meta_path, "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=2)

    threads_path = os.path.join(args.out_dir, "threads.json")
    with open(threads_path, "w", encoding="utf-8") as f:
        json.dump([t.__dict__ for t in threads], f, ensure_ascii=False, indent=2)

    if args.save_html:
        html_path = os.path.join(args.out_dir, "forum.html")
        with open(html_path, "wb") as f:
            f.write(result.body)

    print(f"Wrote {threads_path}")
    return 0


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="nga-fetcher")
    sub = p.add_subparsers(dest="cmd", required=True)

    p_fetch = sub.add_parser("fetch", help="Fetch a URL")
    p_fetch.add_argument("url")
    p_fetch.add_argument("--out", help="Write raw body to file")
    p_fetch.add_argument("--cookies", help="Write cookies JSON to file")
    p_fetch.add_argument(
        "--load-cookies",
        help="Load cookies JSON (from previous run) and attach as Cookie header",
    )
    p_fetch.add_argument(
        "--cookie-file",
        help="Read Cookie header/value from a local file",
    )
    p_fetch.add_argument(
        "--cookie-header",
        help="Provide Cookie header/value directly (be careful, this is sensitive)",
    )
    p_fetch.add_argument("--timeout", type=int, default=30)
    p_fetch.add_argument("--json", action="store_true", help="Emit JSON summary")
    p_fetch.add_argument(
        "--parse-threads",
        action="store_true",
        help="Parse thread list from forum HTML (best-effort)",
    )
    p_fetch.set_defaults(func=_cmd_fetch)

    p_serve = sub.add_parser("serve", help="Serve fetched URL via local HTTP")
    p_serve.add_argument("url")
    p_serve.add_argument("--host", default="127.0.0.1")
    p_serve.add_argument("--port", type=int, default=8080)
    p_serve.add_argument("--cookies", help="Write cookies JSON to file")
    p_serve.add_argument("--load-cookies")
    p_serve.add_argument("--cookie-file")
    p_serve.add_argument("--cookie-header")
    p_serve.add_argument("--timeout", type=int, default=30)
    p_serve.add_argument("--verbose", action="store_true")
    p_serve.set_defaults(func=_cmd_serve)

    p_export = sub.add_parser("export", help="Fetch+parse and write results")
    p_export.add_argument(
        "url",
        nargs="?",
        default="https://bbs.nga.cn/thread.php?fid=7",
        help="Forum URL (default: fid=7)",
    )
    p_export.add_argument(
        "--cookie-file",
        default="mvp_nga_fetcher/nga_cookie.txt",
        help="Cookie file (can contain full cURL snippet)",
    )
    p_export.add_argument("--cookie-header")
    p_export.add_argument("--load-cookies")
    p_export.add_argument("--timeout", type=int, default=30)
    p_export.add_argument(
        "--out-dir",
        default="out/nga_fid7",
        help="Output directory to write results",
    )
    p_export.add_argument(
        "--save-html",
        action="store_true",
        help="Also save raw forum HTML to out dir",
    )
    p_export.set_defaults(func=_cmd_export)

    return p


def main(argv: Optional[list[str]] = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
