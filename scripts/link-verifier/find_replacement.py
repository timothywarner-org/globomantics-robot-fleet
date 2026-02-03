"""
Dead-Link Replacement Finder - Multi-strategy search for the best substitute URL.

Usage:
    python find_replacement.py --url "<dead_url>" --context "<surrounding text>"
    python find_replacement.py --url "<dead_url>" --context "<text>" --json

Strategies (executed in order, results merged and scored):
    1. Wayback Machine  - archived snapshot + redirect detection
    2. Domain search     - site-scoped search on the original domain
    3. Web search        - broad search for the page title + domain
    4. Semantic search   - topic-based search using the surrounding context

Each candidate gets a composite confidence score (0.0 - 1.0).
"""

import argparse
import json
import re
import sys
from dataclasses import asdict, dataclass
from difflib import SequenceMatcher
from urllib.parse import urlparse

import requests

BROWSER_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/120.0.0.0 Safari/537.36"
    ),
    "Accept": "text/html,application/xhtml+xml,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.5",
}

AUTHORITY_DOMAINS = {
    "docs.github.com": 1.0,
    "github.com": 0.95,
    "learn.microsoft.com": 1.0,
    "developer.mozilla.org": 0.95,
    "nvd.nist.gov": 0.95,
    "cisa.gov": 0.9,
    "www.cisa.gov": 0.9,
    "spdx.dev": 0.9,
    "owasp.org": 0.9,
}


@dataclass
class Candidate:
    url: str
    title: str
    strategy: str
    domain_match: float
    path_similarity: float
    content_relevance: float
    authority: float
    confidence: float


def path_similarity(url_a, url_b):
    """Compute normalized path similarity between two URLs."""
    path_a = urlparse(url_a).path.strip("/")
    path_b = urlparse(url_b).path.strip("/")
    return SequenceMatcher(None, path_a, path_b).ratio()


def domain_match_score(original_url, candidate_url):
    """Score how closely the candidate domain matches the original."""
    orig = urlparse(original_url).netloc.lower()
    cand = urlparse(candidate_url).netloc.lower()
    if orig == cand:
        return 1.0
    orig_base = ".".join(orig.split(".")[-2:])
    cand_base = ".".join(cand.split(".")[-2:])
    if orig_base == cand_base:
        return 0.8
    return 0.0


def authority_score(url):
    """Score the trustworthiness of the candidate domain."""
    domain = urlparse(url).netloc.lower()
    if domain in AUTHORITY_DOMAINS:
        return AUTHORITY_DOMAINS[domain]
    base = ".".join(domain.split(".")[-2:])
    for auth_domain, score in AUTHORITY_DOMAINS.items():
        if base == ".".join(auth_domain.split(".")[-2:]):
            return score * 0.9
    return 0.3


def content_relevance_score(title, context):
    """Score how relevant a candidate page title is to the context."""
    if not title or not context:
        return 0.3
    title_lower = title.lower()
    context_lower = context.lower()
    context_words = set(re.findall(r'\b\w{4,}\b', context_lower))
    title_words = set(re.findall(r'\b\w{4,}\b', title_lower))
    if not context_words:
        return 0.3
    overlap = context_words & title_words
    ratio = len(overlap) / max(len(context_words), 1)
    seq_score = SequenceMatcher(None, title_lower, context_lower).ratio()
    return min(1.0, (ratio * 0.6) + (seq_score * 0.4))


def compute_confidence(candidate):
    """Compute composite confidence from individual signals."""
    return (
        candidate.domain_match * 0.30
        + candidate.path_similarity * 0.25
        + candidate.content_relevance * 0.25
        + candidate.authority * 0.20
    )


def is_alive(url, timeout=8):
    """Quick check if a URL returns 200."""
    try:
        resp = requests.head(
            url, headers=BROWSER_HEADERS,
            timeout=timeout, allow_redirects=True
        )
        if resp.status_code == 405:
            resp = requests.get(
                url, headers=BROWSER_HEADERS,
                timeout=timeout, allow_redirects=True, stream=True
            )
            resp.close()
        return resp.status_code == 200
    except requests.RequestException:
        return False


def strategy_wayback(dead_url, context):
    """Check the Wayback Machine for archived versions."""
    candidates = []
    api_url = f"https://archive.org/wayback/available?url={dead_url}"
    try:
        resp = requests.get(api_url, timeout=10)
        data = resp.json()
        snapshot = data.get("archived_snapshots", {}).get("closest", {})
        if snapshot and snapshot.get("available"):
            archive_url = snapshot.get("url", "")
            title = f"Archived: {dead_url.split('/')[-1]}"
            candidates.append({
                "url": dead_url,
                "title": title,
                "strategy": "wayback",
                "note": f"Archive available at {archive_url}",
            })
    except (requests.RequestException, json.JSONDecodeError):
        pass
    return candidates


def strategy_domain_search(dead_url, context):
    """Search the same domain for similar content using common patterns."""
    candidates = []
    parsed = urlparse(dead_url)
    domain = parsed.netloc
    path_parts = [
        p for p in parsed.path.strip("/").split("/") if p
    ]

    probe_urls = []

    if len(path_parts) >= 2:
        trimmed = "/".join(path_parts[:-1])
        probe_urls.append(f"{parsed.scheme}://{domain}/{trimmed}")

    slug = path_parts[-1] if path_parts else ""
    if slug:
        if "docs.github.com" in domain:
            probe_urls.append(
                f"https://docs.github.com/en/search?query={slug.replace('-', '+')}"
            )
        if "learn.microsoft.com" in domain:
            probe_urls.append(
                f"https://learn.microsoft.com/en-us/search/?terms={slug.replace('-', '+')}"
            )

    for probe in probe_urls:
        if is_alive(probe):
            candidates.append({
                "url": probe,
                "title": f"Domain probe: {probe.split('/')[-1]}",
                "strategy": "domain_search",
            })

    return candidates


def strategy_web_search(dead_url, context):
    """
    Use DuckDuckGo Instant Answer API as a free web search fallback.
    Returns candidates based on related topics.
    """
    candidates = []
    parsed = urlparse(dead_url)
    slug = parsed.path.strip("/").split("/")[-1] if parsed.path else ""
    domain_base = ".".join(parsed.netloc.split(".")[-2:])
    query = f"{slug.replace('-', ' ')} site:{domain_base}"

    try:
        resp = requests.get(
            "https://api.duckduckgo.com/",
            params={"q": query, "format": "json", "no_html": 1},
            headers=BROWSER_HEADERS,
            timeout=10,
        )
        data = resp.json()

        if data.get("AbstractURL"):
            candidates.append({
                "url": data["AbstractURL"],
                "title": data.get("Heading", ""),
                "strategy": "web_search",
            })

        for topic in data.get("RelatedTopics", [])[:5]:
            first_url = topic.get("FirstURL", "")
            if first_url and first_url.startswith("http"):
                candidates.append({
                    "url": first_url,
                    "title": topic.get("Text", "")[:80],
                    "strategy": "web_search",
                })
    except (requests.RequestException, json.JSONDecodeError):
        pass

    return candidates


def strategy_semantic_search(dead_url, context):
    """Search based on the surrounding context text."""
    candidates = []
    if not context or len(context.strip()) < 10:
        return candidates

    keywords = re.findall(r'\b\w{5,}\b', context.lower())
    if not keywords:
        return candidates

    top_keywords = list(dict.fromkeys(keywords))[:5]
    query = " ".join(top_keywords)

    try:
        resp = requests.get(
            "https://api.duckduckgo.com/",
            params={"q": query, "format": "json", "no_html": 1},
            headers=BROWSER_HEADERS,
            timeout=10,
        )
        data = resp.json()

        if data.get("AbstractURL"):
            candidates.append({
                "url": data["AbstractURL"],
                "title": data.get("Heading", ""),
                "strategy": "semantic_search",
            })

        for topic in data.get("RelatedTopics", [])[:3]:
            first_url = topic.get("FirstURL", "")
            if first_url and first_url.startswith("http"):
                candidates.append({
                    "url": first_url,
                    "title": topic.get("Text", "")[:80],
                    "strategy": "semantic_search",
                })
    except (requests.RequestException, json.JSONDecodeError):
        pass

    return candidates


def find_replacements(dead_url, context="", top_n=5):
    """Run all strategies and return scored, ranked candidates."""
    raw_candidates = []
    for strategy_fn in [
        strategy_wayback,
        strategy_domain_search,
        strategy_web_search,
        strategy_semantic_search,
    ]:
        try:
            raw_candidates.extend(strategy_fn(dead_url, context))
        except Exception:
            continue

    seen = set()
    scored = []
    for raw in raw_candidates:
        url = raw["url"]
        if url in seen or url == dead_url:
            continue
        seen.add(url)

        candidate = Candidate(
            url=url,
            title=raw.get("title", ""),
            strategy=raw["strategy"],
            domain_match=domain_match_score(dead_url, url),
            path_similarity=path_similarity(dead_url, url),
            content_relevance=content_relevance_score(
                raw.get("title", ""), context
            ),
            authority=authority_score(url),
            confidence=0.0,
        )
        candidate.confidence = round(compute_confidence(candidate), 3)
        scored.append(candidate)

    scored.sort(key=lambda c: c.confidence, reverse=True)
    return scored[:top_n]


def print_table(candidates, dead_url):
    """Print a human-readable ranked list."""
    print(f"\nReplacement candidates for: {dead_url}")
    print("=" * 90)

    if not candidates:
        print("  No candidates found. Manual search required.")
        return

    print(
        f"  {'Rank':<5} {'Confidence':<12} {'Strategy':<18} "
        f"{'Domain':<8} {'Path':<8} {'Relevance':<10} {'URL'}"
    )
    print("-" * 90)

    for i, c in enumerate(candidates, 1):
        print(
            f"  {i:<5} {c.confidence:<12.3f} {c.strategy:<18} "
            f"{c.domain_match:<8.2f} {c.path_similarity:<8.2f} "
            f"{c.content_relevance:<10.2f} {c.url}"
        )
        if c.title:
            print(f"{'':>8} Title: {c.title[:70]}")

    print("-" * 90)
    best = candidates[0]
    if best.confidence >= 0.8:
        print(f"  RECOMMENDATION: Use {best.url} (high confidence)")
    elif best.confidence >= 0.5:
        print(f"  SUGGESTION: Consider {best.url} (medium confidence, verify manually)")
    else:
        print("  WARNING: No high-confidence replacement found. Manual search needed.")


def main():
    parser = argparse.ArgumentParser(
        description="Find replacement URLs for dead links"
    )
    parser.add_argument(
        "--url", required=True,
        help="The dead URL to find a replacement for"
    )
    parser.add_argument(
        "--context", default="",
        help="Surrounding text from the markdown for semantic matching"
    )
    parser.add_argument(
        "--top", type=int, default=5,
        help="Number of top candidates to return (default: 5)"
    )
    parser.add_argument(
        "--json", action="store_true",
        help="Output JSON instead of table"
    )
    args = parser.parse_args()

    candidates = find_replacements(args.url, args.context, args.top)

    if args.json:
        report = {
            "dead_url": args.url,
            "context": args.context[:200],
            "candidates": [asdict(c) for c in candidates],
            "recommendation": (
                candidates[0].url if candidates and candidates[0].confidence >= 0.8
                else None
            ),
        }
        print(json.dumps(report, indent=2))
    else:
        print_table(candidates, args.url)

    if candidates and candidates[0].confidence >= 0.8:
        sys.exit(0)
    elif candidates:
        sys.exit(2)
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
