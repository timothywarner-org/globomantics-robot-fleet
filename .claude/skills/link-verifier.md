# Link Verifier

Comprehensive hyperlink verification and dead-link remediation for markdown documents. Uses Claude's native tools and MCP servers - no external dependencies, no bash, fully cross-platform.

## When to Use

Activate this skill when the user asks to:
- Verify, check, or validate links/URLs in markdown files
- Find or fix broken links, dead links, or 404s
- Audit documents for link rot
- Create or maintain reference documents with verified links
- Run a "link check" or "URL audit" on any file or directory

Trigger phrases: "verify links", "check links", "validate links", "find broken links", "fix dead links", "audit link rot", "check hyperlinks", "link check", "URL audit"

## MCP Tool Reference

This skill leverages multiple MCP servers. Use the right tool for the right domain:

### Microsoft Learn MCP (`microsoft-learn`)

Use for ANY URL on `learn.microsoft.com`, `docs.microsoft.com`, `azure.microsoft.com`, `msdn.microsoft.com`, `technet.microsoft.com`, or `devblogs.microsoft.com`.

| Tool | When to Use |
|------|-------------|
| `microsoft_docs_search` | Find current URL for moved/dead Microsoft docs. Pass the page topic as query. Returns up to 10 chunks with titles and URLs. |
| `microsoft_code_sample_search` | When a dead link pointed to a Microsoft code sample or SDK reference. Pass SDK/method name as query. Optional `language` param. |
| `microsoft_docs_fetch` | Verify a candidate Microsoft URL is correct by fetching its full content. Pass the candidate URL. |

**Domain mapping** - these all resolve through Microsoft Learn MCP:
- `learn.microsoft.com` - Current docs platform
- `docs.microsoft.com` - Legacy (redirects to learn.microsoft.com)
- `msdn.microsoft.com` - Very old (often completely restructured)
- `technet.microsoft.com` - Retired (content migrated to learn.microsoft.com)
- `azure.microsoft.com` - Azure product pages and docs
- `devblogs.microsoft.com` - Microsoft developer blogs

### Context7 MCP (`context7`)

Use for ANY URL pointing to library/framework/SDK documentation - npm packages, Python libraries, Rust crates, Go modules, etc.

| Tool | When to Use |
|------|-------------|
| `resolve-library-id` | First step: resolve a library name to a Context7 library ID. Pass `libraryName` and `query` (the topic). |
| `query-docs` | Second step: query the library's docs for the specific topic. Pass the `libraryId` from step 1 and a descriptive `query`. |

**Use Context7 for these domains:**
- `docs.python.org`, `pypi.org` - Python ecosystem
- `www.npmjs.com`, `nodejs.org` - Node.js ecosystem
- `docs.rs`, `crates.io` - Rust ecosystem
- `pkg.go.dev` - Go ecosystem
- `react.dev`, `nextjs.org`, `angular.io`, `vuejs.org` - Frontend frameworks
- `expressjs.com`, `fastapi.tiangolo.com` - Backend frameworks
- `docs.langchain.com`, `python.langchain.com` - LangChain
- `platform.openai.com/docs` - OpenAI API docs
- `docs.anthropic.com` - Anthropic API docs
- `huggingface.co/docs` - Hugging Face
- `docs.llamaindex.ai` - LlamaIndex
- `sdk.vercel.ai` - Vercel AI SDK
- Any library/framework documentation site

### Mermaid MCP (`mermaid`)

Not directly used for link checking, but if the user asks for a visual report of link health across a large document set, use `mermaid_preview` to generate a status diagram.

### MarkItDown MCP (`markitdown`)

| Tool | When to Use |
|------|-------------|
| `convert_to_markdown` | When a dead link points to a non-HTML resource (PDF, DOCX, PPTX) and you need to verify or inspect its content. Pass the URI. |

## Workflow

Execute these phases in order. Use TaskCreate to track progress through each phase.

### Phase 1: Extract URLs

1. Use **Glob** to find target markdown files (e.g., `**/*.md` or a specific file).
2. Use **Read** to load each file.
3. Extract all URLs using these patterns:
   - Markdown links: `[text](https://...)`
   - Bare URLs: `https://...` (not inside parentheses)
   - Reference-style links: `[text][ref]` with `[ref]: https://...`
   - HTML anchor tags: `<a href="https://...">`
4. Deduplicate URLs. Record for each: URL, file path, line number, link text, surrounding context (the full line or paragraph).

### Phase 2: Verify URLs in Batches

For each unique URL, use **WebFetch** to check if it's alive:
- Use the prompt: `"Return ONLY the HTTP status code and page title. If the page loaded successfully, say 'STATUS: 200 OK' and 'TITLE: <title>'. If it redirected, say 'STATUS: REDIRECT' and 'FINAL_URL: <url>'. If it failed, say 'STATUS: FAILED' and describe why."`
- Process URLs in parallel batches using multiple **WebFetch** calls in a single message (up to 8-10 at a time).
- For URLs that WebFetch cannot reach (403, timeout, etc.), note them as "inconclusive" rather than dead.

Classify each result:

| Category | Condition | Action |
|----------|-----------|--------|
| OK | Page loads, content relevant | No action |
| Redirect | URL redirected to different URL | Update to final URL |
| Dead | 404, domain gone, connection refused | Find replacement (Phase 3) |
| Blocked | 403, bot protection | Flag for manual review |
| Server Error | 5xx | Retry once, then flag |
| Inconclusive | Timeout, SSL error | Flag for manual review |

### Phase 3: Find Replacements for Dead Links

For each dead link, first identify its **domain category**, then execute the matching strategy path:

#### Path A: Microsoft Domains (learn.microsoft.com, docs.microsoft.com, msdn.microsoft.com, technet.microsoft.com, azure.microsoft.com)

1. **microsoft_docs_search** - Search by page topic extracted from the URL slug and link text. This is the single best source for finding where Microsoft content moved.
2. **microsoft_code_sample_search** - If the dead link was to a code sample or API reference, search by SDK/class/method name.
3. **microsoft_docs_fetch** - Verify the top candidate by fetching its full content.
4. Fall back to **WebSearch** with `site:learn.microsoft.com <topic>` only if MCP tools return nothing.

#### Path B: GitHub Domains (docs.github.com, github.com/docs, github.blog)

1. **WebSearch** with `site:docs.github.com <slug_keywords>` - GitHub restructures docs constantly.
2. **WebSearch** with `site:github.blog <topic>` for blog posts.
3. For GitHub repo links (`github.com/<org>/<repo>`), check if the repo was renamed/transferred by using **WebFetch** on the original URL (GitHub auto-redirects renamed repos).

#### Path C: AI/ML Documentation (OpenAI, Anthropic, Hugging Face, LangChain, LlamaIndex, etc.)

1. **context7 resolve-library-id** with the library name, then **context7 query-docs** with the topic.
2. **WebSearch** with `site:<domain> <topic>` as fallback.
3. These docs change rapidly. Prefer the most recent version found.

#### Path D: Azure Service Documentation

1. **microsoft_docs_search** with the Azure service name + topic.
2. **microsoft_code_sample_search** if the link was to SDK usage or quickstart code. Use `language` param when known.
3. **WebSearch** with `site:learn.microsoft.com azure <service> <topic>` as secondary.

#### Path E: General / Other Domains

1. **Wayback Machine** - Use **WebFetch** on `https://web.archive.org/web/2024*/<dead_url>` to check for archived versions. Note as fallback.
2. **Domain-scoped search** - Use **WebSearch** with `site:<original_domain> <slug_keywords>`.
3. **Broad web search** - Use **WebSearch** with `<link_text> <domain_name> <key_terms_from_context>`.
4. **context7** - If the dead link was to any library/framework docs, try resolve-library-id + query-docs.

#### Path F: Package Registry Links (npm, PyPI, crates.io, NuGet, Go)

1. **WebFetch** on the package page directly (registries rarely die; 404 usually means the package was renamed/unpublished).
2. **WebSearch** with `<package_name> <registry>` to find renamed packages.
3. **context7 resolve-library-id** to find the current canonical docs.

#### Scoring Candidates

Rate each candidate replacement (0.0 - 1.0):

| Signal | Weight | Description |
|--------|--------|-------------|
| Domain match | 0.30 | Same domain as original = 1.0, same base domain = 0.8, different = 0.0 |
| Path similarity | 0.25 | How similar the URL path is to the original |
| Content relevance | 0.25 | Does the page title/content match the link text and context? |
| Authority | 0.20 | Is the domain a known-trustworthy source? |

Authority domain scores:
- `learn.microsoft.com`, `docs.github.com`: 1.0
- `github.com`, `developer.mozilla.org`, `nvd.nist.gov`: 0.95
- `platform.openai.com`, `docs.anthropic.com`: 0.95
- `cisa.gov`, `spdx.dev`, `owasp.org`: 0.90
- `docs.langchain.com`, `huggingface.co`, `docs.llamaindex.ai`: 0.90
- `react.dev`, `nextjs.org`, `nodejs.org`, `docs.python.org`: 0.90
- `stackoverflow.com`, `wikipedia.org`: 0.80
- Other `.gov`, `.edu`: 0.75
- Unknown: 0.30

#### Verification
Before recommending any replacement, use **WebFetch** (or **microsoft_docs_fetch** for Microsoft URLs) to confirm the candidate URL is alive and the content is relevant.

### Phase 4: Apply Fixes

Use **Edit** to update the markdown file(s):

1. **Redirects** (301/302): Silently update URL to the final redirect target.
2. **High-confidence replacements** (score >= 0.8): Update URL automatically.
3. **Medium-confidence replacements** (score 0.5 - 0.8): Use **AskUserQuestion** to present the top 2-3 candidates with their confidence scores and let the user choose.
4. **No good replacement found** (score < 0.5): Leave the link unchanged, flag in the summary.

IMPORTANT: When updating a URL, preserve the original link text unless it no longer makes sense with the new URL.

### Phase 5: Verification Pass

After all fixes are applied:
1. Re-read the updated file.
2. Re-check every URL that was modified to confirm it now returns 200.
3. Report any remaining issues.

## Output Format

Always produce a summary report at the end:

```
## Link Verification Report

**File:** `<filename>`
**Date:** <current date>
**Total links:** X | **OK:** Y | **Fixed:** Z | **Flagged:** W

### Changes Made

| # | Original URL | Status | Action | New URL |
|---|-------------|--------|--------|---------|
| 1 | https://example.com/moved | 301 | Updated redirect | https://example.com/new-location |
| 2 | https://example.com/dead | 404 | Replaced (confidence: 0.85) | https://example.com/replacement |

### Flagged for Manual Review

| # | URL | Status | Reason |
|---|-----|--------|--------|
| 1 | https://example.gov/page | 403 | Bot protection (likely valid) |
| 2 | https://example.com/gone | 404 | No replacement found |
```

## Special Handling Rules

### Government Sites (.gov)
403 responses from government sites are almost always bot protection, NOT dead links. Flag as "likely valid" and do NOT replace unless confirmed dead through WebSearch evidence.

### GitHub Documentation
GitHub restructures docs frequently. Always try `site:docs.github.com <slug>` search before declaring a GitHub docs link dead. For GitHub repo links, check for repo renames/transfers via WebFetch (GitHub 301-redirects renamed repos).

### Microsoft Learn / Azure Docs
ALWAYS use **microsoft_docs_search** MCP as the PRIMARY strategy for any Microsoft domain URL. It has the most current index and is far more reliable than generic web search for Microsoft content. Use **microsoft_docs_fetch** to verify candidates. For old `msdn.microsoft.com` or `technet.microsoft.com` links, the content has been migrated to `learn.microsoft.com` - search there.

### Azure AI / OpenAI Service
Azure OpenAI docs move frequently between preview and GA. Use **microsoft_docs_search** with queries like `"azure openai <feature>"` to find current locations. The `api-version` in Azure REST URLs changes often - verify the latest via microsoft_docs_search.

### AI/ML Framework Docs (LangChain, Hugging Face, LlamaIndex, etc.)
These ecosystems evolve rapidly and break URLs constantly. Use **context7 resolve-library-id** + **query-docs** as the primary strategy. These tools have the most current documentation index.

### npm / PyPI / Package Registry Links
Package pages rarely die. If a package link 404s, the package was likely renamed or deprecated. Use **context7** to find the current canonical package, then WebSearch the registry.

### Anchor Links (#section)
For links with anchors (e.g., `page#section`), verify both the page AND the anchor. Use WebFetch and check if the anchor text appears in the page content.

### Relative Links
For relative links (`./other-file.md`, `../docs/guide.md`), use **Glob** to verify the target file exists. Do NOT use WebFetch for these.

### NuGet / .NET API References
For `learn.microsoft.com/dotnet/api/` URLs, use **microsoft_docs_search** with the fully qualified type name (e.g., `"System.Text.Json.JsonSerializer"`). For NuGet package pages, use **WebFetch** on `https://www.nuget.org/packages/<name>`.

## Performance Tips

- Process WebFetch calls in parallel batches of 8-10 URLs per message.
- For files with 50+ links, split into chunks and process each chunk before moving to the next.
- Skip duplicate URLs (same URL appearing in multiple places only needs one check).
- Cache results: if the same URL appears in multiple files during a directory scan, check it only once.
- Use domain-specific MCP tools BEFORE falling back to generic WebSearch - they're faster and more accurate.
- For Microsoft URLs, **microsoft_docs_search** is almost always sufficient. Only use WebSearch as a last resort.
- For library docs, **context7** is almost always sufficient. Only use WebSearch as a last resort.
