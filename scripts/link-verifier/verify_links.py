"""
Link Verifier - Extract URLs from markdown and check HTTP status codes in parallel.

Usage:
    python verify_links.py <markdown_file> [--timeout 10] [--workers 10] [--json]

Output:
    JSON report to stdout with status for each link.
"""

import argparse
import json
import re
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import asdict, dataclass
from pathlib import Path
from urllib.parse import urlparse

import requests


@dataclass(frozen=True)
class LinkResult:
    url: str
    status_code: int
    final_url: str
    category: str
    error: str
    line_number: int
    link_text: str


MARKDOWN_LINK_PATTERN = re.compile(
    r'\[([^\]]*)\]\((https?://[^\s\)]+)\)'
)

BARE_URL_PATTERN = re.compile(
    r'(?<!\()(https?://[^\s\)\]>]+)'
)

BROWSER_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/120.0.0.0 Safari/537.36"
    ),
    "Accept": (
        "text/html,application/xhtml+xml,application/xml;"
        "q=0.9,image/webp,*/*;q=0.8"
    ),
    "Accept-Language": "en-US,en;q=0.5",
}


def extract_links(filepath):
    """Extract all URLs from a markdown file with line numbers and link text."""
    links = []
    seen_urls = set()
    text = Path(filepath).read_text(encoding="utf-8")

    for line_num, line in enumerate(text.splitlines(), start=1):
        for match in MARKDOWN_LINK_PATTERN.finditer(line):
            url = match.group(2).rstrip(".,;:")
            if url not in seen_urls:
                seen_urls.add(url)
                links.append({
                    "url": url,
                    "line_number": line_num,
                    "link_text": match.group(1),
                })

        stripped = MARKDOWN_LINK_PATTERN.sub("", line)
        for match in BARE_URL_PATTERN.finditer(stripped):
            url = match.group(1).rstrip(".,;:")
            if url not in seen_urls:
                seen_urls.add(url)
                links.append({
                    "url": url,
                    "line_number": line_num,
                    "link_text": "",
                })

    return links


def categorize(status_code):
    """Classify HTTP status into action category."""
    if status_code == 200:
        return "ok"
    if status_code in (301, 302, 303, 307, 308):
        return "redirect"
    if status_code == 403:
        return "blocked"
    if status_code == 404:
        return "dead"
    if 400 <= status_code < 500:
        return "client_error"
    if 500 <= status_code < 600:
        return "server_error"
    return "unknown"


def check_link(url, timeout, retries=1):
    """Check a single URL. Returns (status_code, final_url, error)."""
    for attempt in range(retries + 1):
        try:
            resp = requests.get(
                url,
                headers=BROWSER_HEADERS,
                timeout=timeout,
                allow_redirects=True,
                stream=True,
            )
            resp.close()
            return resp.status_code, resp.url, ""
        except requests.exceptions.TooManyRedirects:
            return 310, url, "Too many redirects"
        except requests.exceptions.SSLError as exc:
            return 495, url, f"SSL error: {exc}"
        except requests.exceptions.ConnectionError as exc:
            if attempt < retries:
                continue
            return 0, url, f"Connection error: {exc}"
        except requests.exceptions.Timeout:
            if attempt < retries:
                continue
            return 408, url, "Request timed out"
        except requests.exceptions.RequestException as exc:
            return 0, url, f"Request error: {exc}"
    return 0, url, "All retries exhausted"


def verify_links(filepath, timeout=10, max_workers=10):
    """Extract and verify all links from a markdown file."""
    links = extract_links(filepath)
    results = []

    with ThreadPoolExecutor(max_workers=max_workers) as pool:
        future_map = {}
        for link in links:
            future = pool.submit(check_link, link["url"], timeout)
            future_map[future] = link

        for future in as_completed(future_map):
            link = future_map[future]
            status_code, final_url, error = future.result()
            results.append(LinkResult(
                url=link["url"],
                status_code=status_code,
                final_url=final_url,
                category=categorize(status_code),
                error=error,
                line_number=link["line_number"],
                link_text=link["link_text"],
            ))

    return sorted(results, key=lambda r: r.line_number)


def print_table(results):
    """Print a human-readable summary table."""
    counts = {"ok": 0, "redirect": 0, "dead": 0, "blocked": 0, "error": 0}
    print(f"\n{'#':<4} {'Status':<8} {'Category':<14} {'URL'}")
    print("-" * 100)

    for i, r in enumerate(results, 1):
        status_str = str(r.status_code) if r.status_code else "ERR"
        print(f"{i:<4} {status_str:<8} {r.category:<14} {r.url}")
        if r.category == "redirect" and r.final_url != r.url:
            print(f"{'':>27} -> {r.final_url}")
        if r.error:
            print(f"{'':>27} !! {r.error}")

        if r.category in counts:
            counts[r.category] += 1
        else:
            counts["error"] += 1

    print("-" * 100)
    total = len(results)
    print(
        f"Total: {total} links | "
        f"{counts['ok']} OK | "
        f"{counts['redirect']} redirects | "
        f"{counts['dead']} dead | "
        f"{counts['blocked']} blocked | "
        f"{counts['error']} errors"
    )


def main():
    parser = argparse.ArgumentParser(
        description="Verify hyperlinks in markdown files"
    )
    parser.add_argument("file", help="Path to the markdown file")
    parser.add_argument(
        "--timeout", type=int, default=10,
        help="HTTP request timeout in seconds (default: 10)"
    )
    parser.add_argument(
        "--workers", type=int, default=10,
        help="Number of parallel workers (default: 10)"
    )
    parser.add_argument(
        "--json", action="store_true",
        help="Output JSON instead of table"
    )
    args = parser.parse_args()

    if not Path(args.file).exists():
        print(f"Error: File not found: {args.file}", file=sys.stderr)
        sys.exit(1)

    results = verify_links(args.file, args.timeout, args.workers)

    if args.json:
        report = {
            "file": args.file,
            "total": len(results),
            "results": [asdict(r) for r in results],
            "summary": {
                "ok": sum(1 for r in results if r.category == "ok"),
                "redirect": sum(1 for r in results if r.category == "redirect"),
                "dead": sum(1 for r in results if r.category == "dead"),
                "blocked": sum(1 for r in results if r.category == "blocked"),
                "errors": sum(
                    1 for r in results
                    if r.category not in ("ok", "redirect", "dead", "blocked")
                ),
            },
        }
        print(json.dumps(report, indent=2))
    else:
        print_table(results)

    dead_count = sum(1 for r in results if r.category == "dead")
    sys.exit(1 if dead_count > 0 else 0)


if __name__ == "__main__":
    main()
