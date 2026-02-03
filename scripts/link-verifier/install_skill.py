"""
Run this script to install the link-verifier skill into .claude/skills/.

Usage:
    python scripts/link-verifier/install_skill.py
"""

import os
from pathlib import Path

SKILL_CONTENT = r"""# Link Verifier Skill

Comprehensive hyperlink verification and dead-link remediation for markdown documents.

## When to Use

Use this skill when the user asks to:
- Verify, check, or validate links/URLs in a document
- Find broken links in markdown files
- Fix dead links or 404s
- Audit a document for link rot
- Create a learner-resources or reference document with verified links

## Workflow

### Phase 1: Extract and Batch

1. Read the target markdown file(s).
2. Run `python scripts/link-verifier/verify_links.py <file>` to extract every URL and check HTTP status codes in parallel.
3. The script outputs a JSON report to stdout with status for each link.

### Phase 2: Triage Results

Parse the JSON report. Classify each link:

| Status | Action |
|--------|--------|
| 200 | No action needed |
| 301/302 | Update URL to final redirect target |
| 403 | Flag for manual review (may be geo/auth blocked but still valid) |
| 404 | Run replacement finder |
| 5xx | Retry once, then flag |
| Connection error | Retry once, then flag |

### Phase 3: Find Replacements for Dead Links

For any 404 or confirmed-dead link, run:

```
python scripts/link-verifier/find_replacement.py --url "<dead_url>" --context "<surrounding text from the markdown>"
```

The replacement finder uses a multi-strategy approach:
1. **Wayback Machine** - Check if an archived version exists and extract the canonical URL it redirected to.
2. **Domain search** - Search the same domain for the content (handles restructured docs).
3. **Web search** - Search for the page title + domain to find where content moved.
4. **Semantic search** - Search for the topic described by the surrounding markdown context.

Each candidate is scored by:
- **Domain match** (same domain as original = highest trust, weight 0.30)
- **Path similarity** (Levenshtein distance to original path, weight 0.25)
- **Content relevance** (page title/description matches context, weight 0.25)
- **Authority** (prefer official docs domains, weight 0.20)

The script outputs a ranked list of replacement candidates with confidence scores.

### Phase 4: Apply Fixes

1. For redirects (301/302): silently update the URL in the markdown.
2. For dead links with a high-confidence replacement (score >= 0.8): update the URL and note the change.
3. For dead links with medium-confidence replacements (0.5-0.8): present options to the user via AskUserQuestion.
4. For dead links with no good replacement: flag in a summary table for the user.

### Phase 5: Verification Pass

After all fixes, re-run `verify_links.py` on the updated file to confirm zero broken links remain.

## Output Format

Always produce a summary table:

```
## Link Verification Report

| # | URL | Status | Action Taken |
|---|-----|--------|-------------|
| 1 | https://example.com/good | 200 OK | None |
| 2 | https://example.com/moved | 301 -> new | Updated URL |
| 3 | https://example.com/dead | 404 | Replaced with https://example.com/new |
| 4 | https://example.com/unknown | 403 | Flagged for manual review |

**Total:** X links checked, Y OK, Z fixed, W flagged
```

## Scripts Reference

| Script | Purpose |
|--------|---------|
| `scripts/link-verifier/verify_links.py` | Extract URLs from markdown + parallel HTTP status check |
| `scripts/link-verifier/find_replacement.py` | Multi-strategy dead-link replacement finder |
| `scripts/link-verifier/requirements.txt` | Python dependencies |

### Installation

```bash
pip install -r scripts/link-verifier/requirements.txt
```

## Tips

- Run verification in parallel batches of 4 agents for large documents (split URLs evenly across agents).
- For GitHub docs, the URL structure changes frequently. The domain-search strategy catches most of these.
- For Microsoft Learn docs, use the microsoft_docs_search MCP tool as an additional signal when the Python scripts cannot resolve a replacement.
- 403 responses from government sites (whitehouse.gov, cisa.gov) are often false negatives due to bot protection. Flag but do not replace.
- Always follow redirects to their final destination to get the canonical URL.
"""


def main():
    repo_root = Path(__file__).resolve().parent.parent.parent
    skill_dir = repo_root / ".claude" / "skills"
    skill_dir.mkdir(parents=True, exist_ok=True)
    skill_path = skill_dir / "link-verifier.md"
    skill_path.write_text(SKILL_CONTENT.strip() + "\n", encoding="utf-8")
    print(f"Skill installed: {skill_path}")


if __name__ == "__main__":
    main()
