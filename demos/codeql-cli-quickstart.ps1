#Requires -Version 7.0
<#
.SYNOPSIS
    CodeQL CLI Quickstart — Copy-paste commands for local analysis

.DESCRIPTION
    A focused, linear walkthrough of the CodeQL CLI workflow:
      1. Pre-flight checks (version, languages, packs)
      2. Create a JavaScript database from this repo
      3. Analyze with the security-extended suite
      4. Run a single query (eval injection / CWE-094)
      5. Inspect SARIF output structure
      6. Upload results to GitHub (commented out)

    This script is NOT menu-driven — read it top-to-bottom or copy individual
    sections into your terminal. Each section is self-contained.

    HOW TO USE THIS SCRIPT:
    ───────────────────────
    Option A: Run the whole thing
      pwsh -File demos/codeql-cli-quickstart.ps1

    Option B: Copy individual sections into your terminal
      Highlight a section, paste into PowerShell 7, and run

    Option C: Read it as a reference
      Every command has detailed comments explaining what it does and WHY

.NOTES
    Repository : timothywarner-org/globomantics-robot-fleet
    PowerShell : 7.x required
    Prerequisites:
      - CodeQL CLI installed and on PATH (codeql version should work)
      - gh CLI authenticated (gh auth status)
      - This repo cloned locally
    Companion files:
      - demos/codeql-demo.ipynb           — same commands with pre-captured output
      - demos/codeql-demo-commands.ps1     — interactive menu-driven demo console
      - demos/DEMO-PUNCHLIST.md            — full demo timing and talk tracks
#>

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────
# Update these variables to match your local environment.
# $repoDir must point to the root of your globomantics-robot-fleet clone.
# ═══════════════════════════════════════════════════════════════════════════════

$repo       = "timothywarner-org/globomantics-robot-fleet"
$repoDir    = "C:\github\globomantics-robot-fleet"
$mainBranch = "main"
$dbPath     = Join-Path $repoDir "codeql-db-javascript"

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 1: Pre-flight Checks
# ─────────────────────────────────────────────────────────────────────────────
# Verify the CodeQL CLI is installed and see what it can do.
#
# `codeql resolve languages` shows every language the CLI can extract.
# `codeql resolve packs` shows bundled query packs — these contain the rules
# that CodeQL runs during analysis (e.g., codeql/javascript-queries).
#
# GH-500 EXAM TIP: CodeQL supports 10+ languages natively. For unsupported
# languages (like Rust), you need a third-party scanner such as Semgrep.
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "`n=== CodeQL CLI Version ===" -ForegroundColor Cyan
codeql version

Write-Host "`n=== Supported Languages ===" -ForegroundColor Cyan
# Each line shows a language and its extractor version.
# JavaScript covers both .js and .ts files automatically.
codeql resolve languages

Write-Host "`n=== Bundled Query Packs (first 20) ===" -ForegroundColor Cyan
# Query packs contain the actual QL rules. The key ones for this demo:
#   codeql/javascript-queries  — JS/TS security and quality rules
#   codeql/javascript-all      — low-level library (used by queries, not run directly)
codeql resolve packs | Select-Object -First 20

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 2: Create a CodeQL Database
# ─────────────────────────────────────────────────────────────────────────────
# `codeql database create` extracts source code into a relational database.
# Queries run against this database, not directly against source files.
#
# WHY NO BUILD COMMAND?
# JavaScript is an interpreted language — CodeQL extracts directly from source
# files without needing to compile anything. This is "build-mode: none."
# For compiled languages like C++ or Java, you'd add --command="make" or
# similar to tell CodeQL how to build your project.
#
# Parameters explained:
#   --language=javascript   → extract JS and TypeScript files
#   --source-root=.         → root directory containing the source code
#   --overwrite             → replace any existing database at this path
#
# GH-500 EXAM TIP: JavaScript uses build-mode: none (direct extraction).
# Java also supports none. C++ typically needs build-mode: manual.
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "`n=== Creating CodeQL Database ===" -ForegroundColor Cyan
Write-Host "   This extracts all JS/TS source into a queryable relational database." -ForegroundColor DarkGray
Write-Host "   Takes ~30-60 seconds for this repo.`n" -ForegroundColor DarkGray

Push-Location $repoDir

codeql database create $dbPath `
    --language=javascript `
    --source-root=. `
    --overwrite

Pop-Location

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 3: Inspect the Database
# ─────────────────────────────────────────────────────────────────────────────
# `print-baseline` shows how many lines of code were extracted.
# This is a quick sanity check — if it says 0 lines, extraction failed.
#
# A typical JavaScript extraction for this repo is ~250 lines (server.js
# plus public/ JS files). The database itself is ~50-60 MB on disk because
# it stores a full relational model of the code's AST and data flow.
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "`n=== Database Baseline ===" -ForegroundColor Cyan
codeql database print-baseline $dbPath

# Show database size on disk
if (Test-Path $dbPath) {
    $sizeBytes = (Get-ChildItem $dbPath -Recurse -File | Measure-Object -Property Length -Sum).Sum
    $sizeMB = [math]::Round($sizeBytes / 1MB, 1)
    Write-Host "   Database size: ${sizeMB} MB" -ForegroundColor DarkGray
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 4: Analyze with the security-extended Suite
# ─────────────────────────────────────────────────────────────────────────────
# `codeql database analyze` runs a query suite against the database and
# outputs results in SARIF 2.1.0 format.
#
# THREE QUERY SUITES (GH-500 exam):
#   code-scanning (default)   → core security, low noise, high confidence
#   security-extended         → broader coverage, more experimental rules
#   security-and-quality      → security + code quality checks
#
# The pack:suite syntax is:
#   codeql/javascript-queries:codeql-suites/javascript-security-extended.qls
#   ─────────────────────────  ───────────────────────────────────────────────
#   query pack name            suite file within the pack
#
# --format=sarifv2.1.0 is REQUIRED for GitHub ingestion.
# The default CodeQL output format is NOT SARIF — you must specify this.
#
# GH-500 EXAM TIP: "default suite" (query set) is NOT "default setup"
# (zero-config enablement). Know the difference.
# ═══════════════════════════════════════════════════════════════════════════════

$sarifOutput = Join-Path $repoDir "codeql-results.sarif"

Write-Host "`n=== Running security-extended Analysis ===" -ForegroundColor Cyan
Write-Host "   This may take 1-3 minutes.`n" -ForegroundColor DarkGray

codeql database analyze $dbPath `
    --format=sarifv2.1.0 `
    --output=$sarifOutput `
    codeql/javascript-queries:codeql-suites/javascript-security-extended.qls

Write-Host "`n   Results written to: $sarifOutput" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 5: Run a Single Query (Code Injection / CWE-094)
# ─────────────────────────────────────────────────────────────────────────────
# Instead of running an entire suite, you can target ONE specific query.
# This is useful for:
#   - Testing a custom query you're developing
#   - Isolating a specific CWE for a compliance check
#   - Debugging false positives by running just the suspect rule
#
# Here we run the code injection query that detects the eval() vulnerability
# in server.js (the :format parameter flows to eval() with no sanitization).
#
# The query path follows the CWE hierarchy:
#   Security/CWE-094/CodeInjection.ql
#   ────────  ───────  ──────────────
#   category  CWE ID   query name
# ═══════════════════════════════════════════════════════════════════════════════

$singleQuerySarif = Join-Path $repoDir "codeql-single-query.sarif"

Write-Host "`n=== Running Single Query: Code Injection (CWE-094) ===" -ForegroundColor Cyan

codeql database analyze $dbPath `
    --format=sarifv2.1.0 `
    --output=$singleQuerySarif `
    codeql/javascript-queries:Security/CWE-094/CodeInjection.ql

Write-Host "`n   Results written to: $singleQuerySarif" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 6: List Queries in a Suite
# ─────────────────────────────────────────────────────────────────────────────
# `codeql resolve queries` shows every .ql file in a suite. This helps you
# understand exactly what CodeQL is checking when you select a suite.
#
# Useful for:
#   - Auditing what rules run in your CI pipeline
#   - Finding the right query path for single-query runs (section 5)
#   - Comparing coverage between default and security-extended
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "`n=== Queries in security-extended Suite ===" -ForegroundColor Cyan

codeql resolve queries `
    codeql/javascript-queries:codeql-suites/javascript-security-extended.qls `
    --format=text

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 7: Inspect SARIF Output
# ─────────────────────────────────────────────────────────────────────────────
# SARIF (Static Analysis Results Interchange Format) 2.1.0 is the universal
# format for security findings. GitHub ONLY accepts SARIF 2.1.0.
#
# SARIF STRUCTURE (simplified):
#   runs[]
#     tool.driver.name     → "CodeQL" or "Semgrep"
#     tool.driver.rules[]  → all rules that were evaluated
#     results[]            → actual findings with locations
#       ruleId             → e.g., "js/code-injection"
#       locations[]        → file path + line numbers
#       partialFingerprints → how GitHub tracks alerts across commits
#
# GH-500 EXAM TIP: partialFingerprints allow GitHub to track the SAME
# finding across commits, even if files are renamed or code is refactored.
# SARIF version must be 2.1.0 — no other version is accepted.
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "`n=== SARIF Results Summary ===" -ForegroundColor Cyan

if (Test-Path $sarifOutput) {
    $sarif = Get-Content $sarifOutput | ConvertFrom-Json

    foreach ($run in $sarif.runs) {
        $toolName    = $run.tool.driver.name ?? "Unknown"
        $ruleCount   = $run.tool.driver.rules.Count
        $resultCount = $run.results.Count

        Write-Host "   Tool:    $toolName" -ForegroundColor White
        Write-Host "   Rules:   $ruleCount evaluated" -ForegroundColor White
        Write-Host "   Results: $resultCount findings" -ForegroundColor White
        Write-Host ""

        # List each finding with its location
        foreach ($result in $run.results) {
            $ruleId  = $result.ruleId
            $level   = $result.level
            $message = $result.message.text
            $loc     = $result.locations[0].physicalLocation
            $file    = $loc.artifactLocation.uri
            $line    = $loc.region.startLine

            Write-Host "   [$level] $ruleId" -ForegroundColor Yellow
            Write-Host "     File: ${file}:${line}" -ForegroundColor DarkGray
            Write-Host "     $($message.Substring(0, [Math]::Min($message.Length, 100)))" -ForegroundColor DarkGray
            Write-Host ""
        }
    }
} else {
    Write-Host "   SARIF file not found at $sarifOutput" -ForegroundColor Red
    Write-Host "   Run section 4 first." -ForegroundColor Red
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 8: Upload Results to GitHub
# ─────────────────────────────────────────────────────────────────────────────
# `codeql github upload-results` pushes local SARIF to GitHub's Security tab.
#
# THREE WAYS TO GET SARIF INTO GITHUB (GH-500 exam):
#   1. codeql-action/upload-sarif  — in a GitHub Actions workflow
#   2. codeql github upload-results — via the CodeQL CLI (shown here)
#   3. REST API POST to /sarifs     — via gh api or curl
#
# Parameters explained:
#   --repository       → owner/repo on GitHub
#   --ref              → git ref (branch) the results apply to
#   --commit           → exact commit SHA for code-to-finding mapping
#   --sarif            → path to the SARIF file
#   --sarif-category   → UNIQUE label — prevents overwriting other results
#
# WHY CATEGORIES MATTER:
# Without --sarif-category, each upload overwrites the previous one. If you
# have CodeQL default setup + a CLI upload + Semgrep, you need three different
# categories so all results coexist in the Security tab.
#
# GH-500 EXAM TIP: --sarif-category is REQUIRED when multiple scanners or
# multiple runs upload to the same repo. Without it, results overwrite.
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "`n=== Upload SARIF to GitHub ===" -ForegroundColor Cyan

$commitSha = git -C $repoDir rev-parse HEAD

Write-Host "   Repository: $repo" -ForegroundColor White
Write-Host "   Branch:     $mainBranch" -ForegroundColor White
Write-Host "   Commit:     $commitSha" -ForegroundColor White
Write-Host "   SARIF:      $sarifOutput" -ForegroundColor White
Write-Host "   Category:   codeql-cli-local" -ForegroundColor White
Write-Host ""

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  UNCOMMENT THE BLOCK BELOW TO UPLOAD RESULTS TO GITHUB             ║
# ║  This pushes findings to Security > Code scanning in the GitHub UI  ║
# ╚══════════════════════════════════════════════════════════════════════╝

# codeql github upload-results `
#     --repository=$repo `
#     --ref=refs/heads/$mainBranch `
#     --commit=$commitSha `
#     --sarif=$sarifOutput `
#     --sarif-category=codeql-cli-local

Write-Host "   Upload command is commented out." -ForegroundColor Yellow
Write-Host "   Uncomment the block above to push results to GitHub." -ForegroundColor Yellow

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 9: Cleanup
# ─────────────────────────────────────────────────────────────────────────────
# CodeQL databases are typically 50-100 MB. Remove them when you're done to
# save disk space. The SARIF files are small (a few KB) and safe to keep.
#
# Note: .gitignore should already exclude codeql-db-* directories. If not,
# make sure you don't accidentally commit a 50 MB database.
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "`n=== Cleanup ===" -ForegroundColor Cyan

if (Test-Path $dbPath) {
    $sizeBytes = (Get-ChildItem $dbPath -Recurse -File | Measure-Object -Property Length -Sum).Sum
    $sizeMB = [math]::Round($sizeBytes / 1MB, 1)
    Write-Host "   Database at: $dbPath (${sizeMB} MB)" -ForegroundColor White
}

# UNCOMMENT TO DELETE the database:
# Remove-Item -Recurse -Force $dbPath
# Write-Host "   Database removed." -ForegroundColor Green

Write-Host "   Cleanup command is commented out. Uncomment to delete the database." -ForegroundColor Yellow

# ═══════════════════════════════════════════════════════════════════════════════
# GH-500 EXAM QUICK REFERENCE
# ─────────────────────────────────────────────────────────────────────────────
# CodeQL CLI command cheat sheet:
#
#   codeql version                    → verify installation
#   codeql resolve languages          → list supported languages
#   codeql resolve packs              → list available query packs
#   codeql resolve queries <suite>    → list queries in a suite
#   codeql database create            → extract source into database
#   codeql database print-baseline    → show extracted line count
#   codeql database analyze           → run queries, output SARIF
#   codeql github upload-results      → push SARIF to GitHub
#
# Key facts:
#   - SARIF version must be 2.1.0 (--format=sarifv2.1.0)
#   - --sarif-category prevents multi-scanner overwrites
#   - JavaScript = build-mode: none (no build step needed)
#   - C++ = build-mode: manual (explicit build commands required)
#   - Java supports build-mode: none (common exam question)
#   - "default setup" ≠ "default suite" — know the difference
#
# Companion files:
#   - demos/codeql-demo.ipynb           → pre-captured output for all commands
#   - demos/codeql-demo-commands.ps1    → interactive menu-driven console
#   - demos/DEMO-PUNCHLIST.md           → demo timing and talk tracks
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "`n=== Done ===" -ForegroundColor Green
Write-Host "   Full CodeQL CLI quickstart complete." -ForegroundColor White
Write-Host "   See demos/codeql-demo.ipynb for pre-captured output of every command." -ForegroundColor DarkGray
Write-Host ""
