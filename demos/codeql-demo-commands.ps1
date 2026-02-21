#Requires -Version 7.0
<#
.SYNOPSIS
    Globomantics Robot Fleet — Code Scanning Demo Console (Modules 5 & 6)

.DESCRIPTION
    Interactive presenter console for the GH-500 / GHAS course covering:
      - Module 5: Third-party scanners (Semgrep), SARIF upload, CLI integration
      - Module 6: Alert triage, dismissal/reopen, workflow troubleshooting, Copilot Chat prompts

    Features a numbered menu so the presenter can jump to any section.

    HOW THIS CONSOLE WORKS FOR LEARNERS:
    ─────────────────────────────────────
    This script is a "live demo safety net." Each menu option runs real GitHub CLI
    and Semgrep commands against the repo, with talk tracks and exam tips displayed
    inline. If a live command fails during a presentation, the companion Jupyter
    notebooks (codeql-demo.ipynb, semgrep-demo.ipynb) have pre-captured output.

    KEY GHAS CONCEPTS DEMONSTRATED:
    ─────────────────────────────────
    1. CodeQL = GitHub's native SAST engine (uses codeql-action/analyze)
    2. Semgrep = third-party scanner (uses codeql-action/upload-sarif)
    3. SARIF 2.1.0 = the universal interchange format for security findings
    4. Categories prevent multiple scanners from overwriting each other's results
    5. The gh CLI provides full programmatic access to the Security tab

.NOTES
    Repository : timothywarner-org/globomantics-robot-fleet
    PowerShell : 7.x required (PowerShell 5.1 will NOT work — missing features)
    Prerequisites:
      - gh CLI authenticated (gh auth status)
      - Semgrep CLI installed (pip install semgrep)
      - CodeQL CLI installed (for SARIF upload and local analysis)
      - Repo cloned locally
    Companion files:
      - demos/codeql-demo.ipynb      — pre-captured CodeQL CLI outputs
      - demos/semgrep-demo.ipynb      — pre-captured Semgrep scan outputs
      - demos/DEMO-PUNCHLIST.md       — full demo timing and talk tracks
#>

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────
# Update $repoDir if your local clone lives in a different path.
# The $repo variable matches the GitHub owner/repo format used by gh CLI.
# ═══════════════════════════════════════════════════════════════════════════════

$repo       = "timothywarner-org/globomantics-robot-fleet"
$repoDir    = "C:\repos\globomantics-robot-fleet"
$mainBranch = "main"

# IMPORTANT: Semgrep is a Python tool. On Windows, Python defaults to the system
# locale encoding, which can crash Semgrep when it encounters non-ASCII characters
# in source files. Setting PYTHONUTF8=1 forces UTF-8 encoding globally.
# Without this, you'll see: UnicodeEncodeError: 'charmap' codec can't encode...
$env:PYTHONUTF8 = "1"

# ═══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ─────────────────────────────────────────────────────────────────────────────
# These utility functions handle the console UI: banners, menus, color-coded
# output, talk track prompts, and exam tips. They keep the demo section
# functions focused on the actual GHAS commands rather than formatting.
# ═══════════════════════════════════════════════════════════════════════════════

# Clears screen and displays the demo console header
function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║                                                          ║" -ForegroundColor Cyan
    Write-Host "  ║   🛡️  GHAS Code Scanning Demo Console                    ║" -ForegroundColor Cyan
    Write-Host "  ║   Globomantics Robot Fleet Manager                       ║" -ForegroundColor Cyan
    Write-Host "  ║                                                          ║" -ForegroundColor Cyan
    Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# Displays the numbered menu. Sections [1]-[7] align with Module 5 (third-party
# scanners, SARIF, Autofix). Sections [8]-[15] align with Module 6 (analysis
# model, triage, troubleshooting). See DEMO-PUNCHLIST.md for timing guidance.
function Show-Menu {
    Write-Host "  📋 Select a demo section:" -ForegroundColor White
    Write-Host ""
    Write-Host "  ── Module 5: Third-Party Scanners & SARIF ──────────────" -ForegroundColor DarkGray
    Write-Host "   [1]  🔧 Pre-flight Checks" -ForegroundColor White
    Write-Host "   [2]  📊 Semgrep Workflow Reference" -ForegroundColor White
    Write-Host "   [3]  🔍 Run Semgrep Locally (Rust CLI)" -ForegroundColor White
    Write-Host "   [4]  🚀 Upload SARIF via CodeQL CLI" -ForegroundColor White
    Write-Host "   [5]  📊 Examine SARIF Structure" -ForegroundColor White
    Write-Host "   [6]  📋 List & Filter Code Scanning Alerts" -ForegroundColor White
    Write-Host "   [7]  🎯 Copilot Autofix (UI Reference)" -ForegroundColor White
    Write-Host ""
    Write-Host "  ── Module 6: Analysis Model & Troubleshooting ──────────" -ForegroundColor DarkGray
    Write-Host "   [8]  🔧 Query Suites, Show Paths, Copilot Chat (UI)" -ForegroundColor White
    Write-Host "   [9]  📊 List All Code Scanning Alerts" -ForegroundColor White
    Write-Host "  [10]  🔍 Filter Alerts by Severity" -ForegroundColor White
    Write-Host "  [11]  ⚡ Dismiss an Alert (with confirmation)" -ForegroundColor White
    Write-Host "  [12]  ⚡ Re-open a Dismissed Alert" -ForegroundColor White
    Write-Host "  [13]  🚀 Check Workflow Run Status" -ForegroundColor White
    Write-Host "  [14]  📋 View Workflow Logs" -ForegroundColor White
    Write-Host "  [15]  ⚠️  Common Failure Scenarios Reference" -ForegroundColor White
    Write-Host ""
    Write-Host "  ── Bonus ───────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "  [16]  🔍 Full Semgrep Scan (entire repo)" -ForegroundColor White
    Write-Host "  [17]  🚀 Run All Sections Sequentially" -ForegroundColor White
    Write-Host ""
    Write-Host "   [0]  🚪 Exit" -ForegroundColor White
    Write-Host ""
}

# Renders a cyan box around a section title — visual separator for the presenter
function Show-SectionHeader {
    param([string]$Title, [string]$Emoji = "📌")
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║  $Emoji  $($Title.PadRight(53))║" -ForegroundColor Cyan
    Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# Shows the exact command about to run — helps learners follow along and
# copy commands for their own practice
function Show-Command {
    param([string]$Command)
    Write-Host "  ⚡ Running:" -ForegroundColor Yellow -NoNewline
    Write-Host " $Command" -ForegroundColor Yellow
    Write-Host "  ─────────────────────────────────────────────────────────" -ForegroundColor DarkGray
}

# Displays presenter talk track text — what the instructor should SAY while
# the command output is on screen. Greyed out so it doesn't distract from output.
function Show-TalkTrack {
    param([string]$Text)
    Write-Host ""
    Write-Host "  🎙️  TALK TRACK:" -ForegroundColor DarkGray
    $Text -split "`n" | ForEach-Object {
        Write-Host "     $_" -ForegroundColor DarkGray
    }
    Write-Host ""
}

# Renders exam tips in a magenta box — these are the specific facts learners
# should memorize for the GH-500 certification exam
function Show-ExamTip {
    param([string]$Text)
    Write-Host ""
    Write-Host "  ╭─────────────────────────────────────────────────────────╮" -ForegroundColor Magenta
    Write-Host "  │ 💡 GH-500 EXAM TIP                                     │" -ForegroundColor Magenta
    $Text -split "`n" | ForEach-Object {
        $padded = "  │   $($_.TrimStart())"
        Write-Host "$($padded.PadRight(62))│" -ForegroundColor Magenta
    }
    Write-Host "  ╰─────────────────────────────────────────────────────────╯" -ForegroundColor Magenta
    Write-Host ""
}

# Color-coded result display helpers
function Show-Result {
    param([string]$Label, [string]$Value, [string]$Color = "White")
    Write-Host "     $Label" -ForegroundColor DarkGray -NoNewline
    Write-Host " $Value" -ForegroundColor $Color
}

function Show-Success {
    param([string]$Message)
    Write-Host "  ✅ $Message" -ForegroundColor Green
}

function Show-Failure {
    param([string]$Message)
    Write-Host "  ❌ $Message" -ForegroundColor Red
}

function Show-Warning {
    param([string]$Message)
    Write-Host "  ⚠️  $Message" -ForegroundColor Yellow
}

# Pauses execution so the presenter can discuss what just happened on screen
function Pause-Demo {
    param([string]$Message = "Press Enter to return to the menu...")
    Write-Host ""
    Write-Host "  ⏸️  $Message" -ForegroundColor DarkGray
    Read-Host
}

# Safety gate for destructive actions (dismissing alerts, running full scans).
# Returns $true only if the presenter explicitly types 'y'.
function Confirm-Action {
    param([string]$Message)
    Write-Host ""
    Write-Host "  ⚠️  $Message" -ForegroundColor Yellow
    $response = Read-Host "     Type 'y' to confirm (y/N)"
    return ($response -eq 'y' -or $response -eq 'Y')
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION FUNCTIONS
# ─────────────────────────────────────────────────────────────────────────────
# Each function below corresponds to one menu option. They follow a consistent
# pattern: header → talk track → live commands → exam tips → pause.
#
# LEARNER NOTE: The gh CLI commands here use the REST API via `gh api`. This is
# the same API that GitHub Actions workflows and third-party integrations use.
# Mastering `gh api` gives you full control over code scanning programmatically.
# ═══════════════════════════════════════════════════════════════════════════════

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 1: Pre-flight Checks
# ─────────────────────────────────────────────────────────────────────────────
# Validates that all required CLI tools are installed and authenticated before
# the demo begins. Nothing worse than discovering a missing tool mid-presentation.
#
# Tools verified:
#   - gh CLI    → GitHub API access (alerts, workflows, SARIF upload)
#   - semgrep   → third-party SAST scanner (pattern-based, supports 30+ langs)
#   - codeql    → GitHub's native SAST engine CLI (database creation, analysis)
#
# Also checks the CodeQL "default setup" configuration via the API, which is
# the zero-config enablement option that scans interpreted languages automatically.
# ─────────────────────────────────────────────────────────────────────────────
function Invoke-PreflightChecks {
    Show-SectionHeader "Pre-flight Checks" "🔧"

    Show-TalkTrack "Before we begin, let's verify all our tools are ready."

    # GitHub CLI — required for ALL API interactions in this demo.
    # `gh auth status` confirms the token is valid and shows which account/org.
    Write-Host "  🔍 Checking GitHub CLI..." -ForegroundColor White
    Show-Command "gh auth status"
    try {
        gh auth status 2>&1 | ForEach-Object { Write-Host "     $_" -ForegroundColor White }
        Show-Success "GitHub CLI authenticated"
    } catch {
        Show-Failure "GitHub CLI not authenticated. Run: gh auth login"
    }
    Write-Host ""

    # Semgrep CLI — the third-party scanner. Installed via pip (it's a Python tool).
    # Semgrep is pattern-based: it matches code patterns using rules from the
    # Semgrep registry (p/security-audit, p/rust, etc.) rather than building a
    # full semantic model like CodeQL does.
    Write-Host "  🔍 Checking Semgrep CLI..." -ForegroundColor White
    Show-Command "semgrep --version"
    try {
        $semgrepVersion = semgrep --version 2>&1
        Show-Success "Semgrep version: $semgrepVersion"
    } catch {
        Show-Failure "Semgrep CLI not found. Install with: pip install semgrep"
    }
    Write-Host ""

    # CodeQL CLI — GitHub's native SAST engine. Used here for:
    #   1. Creating local databases (codeql database create)
    #   2. Running queries locally (codeql database analyze)
    #   3. Uploading SARIF results (codeql github upload-results)
    # Note: CodeQL in GitHub Actions uses the codeql-action, not the CLI directly.
    Write-Host "  🔍 Checking CodeQL CLI..." -ForegroundColor White
    Show-Command "codeql version"
    try {
        $codeqlVersion = codeql version 2>&1 | Select-Object -First 1
        Show-Success "CodeQL version: $codeqlVersion"
    } catch {
        Show-Failure "CodeQL CLI not found. SARIF upload section will not work."
    }
    Write-Host ""

    # Verify the repo directory exists locally
    Write-Host "  🔍 Checking repository directory..." -ForegroundColor White
    if (Test-Path $repoDir) {
        Show-Success "Repo directory exists: $repoDir"
    } else {
        Show-Failure "Repo directory not found at $repoDir — update `$repoDir variable."
    }
    Write-Host ""

    # Check CodeQL default setup configuration via the REST API.
    # "Default setup" is GitHub's zero-config option that automatically enables
    # CodeQL for interpreted languages (JavaScript, Python, Ruby, etc.).
    #
    # GH-500 DISTINCTION: "default setup" (enablement method) is NOT the same as
    # "default suite" (the query set). The default SUITE is the minimal query pack.
    # The default SETUP can use any suite (default, security-extended, etc.).
    Write-Host "`n🔧 CodeQL Repository Configuration:" -ForegroundColor Cyan
    $setupJson = gh api repos/timothywarner-org/globomantics-robot-fleet/code-scanning/default-setup 2>&1
    if ($LASTEXITCODE -eq 0) {
        $setup = $setupJson | ConvertFrom-Json
        Write-Host "   ✅ State:      $($setup.state)" -ForegroundColor Green
        Write-Host "   📋 Languages:  $($setup.languages -join ', ')" -ForegroundColor White
        Write-Host "   🔍 Query Suite: $($setup.query_suite)" -ForegroundColor White
        Write-Host "   📅 Updated:    $($setup.updated_at)" -ForegroundColor DarkGray

        if ($setup.state -eq 'configured') {
            Write-Host "   💡 Using DEFAULT SETUP (zero-config)" -ForegroundColor Magenta
            Write-Host "      GH-500 TIP: 'default setup' ≠ 'default suite'" -ForegroundColor Magenta
        }
    } else {
        Write-Host "   ⚠️  CodeQL default setup not configured" -ForegroundColor Yellow
        Write-Host "   Checking for advanced setup (custom workflow)..." -ForegroundColor DarkGray
        gh run list --repo timothywarner-org/globomantics-robot-fleet --workflow=codeql.yml --limit=3
    }

    # Configuration summary — confirms what values the script will use
    Write-Host ""
    Write-Host "  ╭─────────────────────────────────────────────────────────╮" -ForegroundColor Cyan
    Write-Host "  │ 🔧 Configuration                                        │" -ForegroundColor Cyan
    Write-Host "  │   Repo     : $($repo.PadRight(42))│" -ForegroundColor Cyan
    Write-Host "  │   RepoDir  : $($repoDir.PadRight(42))│" -ForegroundColor Cyan
    Write-Host "  │   Branch   : $($mainBranch.PadRight(42))│" -ForegroundColor Cyan
    Write-Host "  ╰─────────────────────────────────────────────────────────╯" -ForegroundColor Cyan

    Pause-Demo
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 2: Semgrep Workflow Reference
# ─────────────────────────────────────────────────────────────────────────────
# Displays the key configuration points of the Semgrep GitHub Actions workflow.
# This is a REFERENCE section — the actual workflow is created live in the
# GitHub UI during the demo (see DEMO-PUNCHLIST.md, Module 5, step 2).
#
# THREE CRITICAL POINTS for the GH-500 exam:
#   1. `security-events: write` permission — required for SARIF upload (403 without it)
#   2. `upload-sarif` action — lives in the codeql-action repo but is NOT CodeQL
#   3. `category` field — prevents Semgrep results from overwriting CodeQL results
# ─────────────────────────────────────────────────────────────────────────────
function Invoke-SemgrepWorkflowRef {
    Show-SectionHeader "Semgrep Workflow Reference" "📊"

    Show-TalkTrack @"
The Semgrep workflow is created via the GitHub UI during the live demo.
The workflow file .github/workflows/semgrep-analysis.yml is committed to main.
"@

    Write-Host "  📋 Key workflow configuration points:" -ForegroundColor White
    Write-Host ""
    Write-Host "     ┌──────────────────────────────────────────────────────┐" -ForegroundColor DarkGray
    Write-Host "     │  permissions:                                        │" -ForegroundColor Yellow
    Write-Host "     │    security-events: write   ← 403 without this!     │" -ForegroundColor Yellow
    Write-Host "     │                                                      │" -ForegroundColor DarkGray
    Write-Host "     │  uses: github/codeql-action/upload-sarif@v4          │" -ForegroundColor Yellow
    Write-Host "     │         ↑ same repo, different action                │" -ForegroundColor DarkGray
    Write-Host "     │                                                      │" -ForegroundColor DarkGray
    Write-Host "     │  category: semgrep-security-audit                    │" -ForegroundColor Yellow
    Write-Host "     │         ↑ prevents overwriting CodeQL results        │" -ForegroundColor DarkGray
    Write-Host "     └──────────────────────────────────────────────────────┘" -ForegroundColor DarkGray

    Show-ExamTip "Third-party scanners use upload-sarif, NOT codeql-action/analyze."

    Pause-Demo
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 3: Run Semgrep Locally (Rust CLI)
# ─────────────────────────────────────────────────────────────────────────────
# Demonstrates running Semgrep outside of GitHub Actions — critical for orgs
# using Jenkins, Azure DevOps, GitLab CI, or other non-GitHub CI systems.
#
# WHY RUST? CodeQL does NOT support Rust. This is the key selling point for
# third-party scanners: they fill language coverage gaps. Semgrep supports
# 30+ languages including Rust, Go, Ruby, and many others.
#
# The --sarif flag tells Semgrep to output in SARIF 2.1.0 format, which is
# the ONLY format GitHub's Security tab accepts. The --output flag writes to
# a file instead of stdout (cleaner for subsequent upload).
#
# Rule packs used:
#   p/rust — Rust-specific security rules from the Semgrep registry
# ─────────────────────────────────────────────────────────────────────────────
function Invoke-SemgrepLocalScan {
    Show-SectionHeader "Run Semgrep Locally (Rust CLI)" "🔍"

    Show-TalkTrack @"
Not everyone uses GitHub Actions. Jenkins, Azure DevOps, GitLab CI —
they all need to get results into GitHub. Running Semgrep locally and
uploading via CLI bridges that gap. Here we scan just the Rust directory.

CodeQL doesn't support Rust. Third-party scanners like Semgrep output
SARIF and land results in the same Security tab.
"@

    Push-Location $repoDir

    # Run Semgrep against ONLY the Rust telemetry CLI subdirectory.
    # --config p/rust   → pull Rust security rules from the Semgrep registry
    # --sarif           → output in SARIF 2.1.0 format (required for GitHub)
    # --output          → write to file instead of stdout
    Show-Command "semgrep scan --config p/rust --sarif --output rust-scan.sarif ./rust-telemetry-cli"
    Write-Host ""
    semgrep scan `
        --config p/rust `
        --sarif `
        --output rust-scan.sarif `
        ./rust-telemetry-cli

    # Verify the SARIF file was created and show basic file info
    Write-Host ""
    if (Test-Path rust-scan.sarif) {
        Show-Success "SARIF file created"
        Write-Host ""
        Write-Host "  📊 SARIF file details:" -ForegroundColor White
        $item = Get-Item rust-scan.sarif
        Show-Result "Name    :" $item.Name
        Show-Result "Size    :" "$($item.Length) bytes"
        Show-Result "Modified:" $item.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
    } else {
        Show-Failure "SARIF file was not created. Check Semgrep output above."
    }

    Pop-Location

    Show-ExamTip @"
Third-party scanners use upload-sarif, NOT codeql-action/analyze.
SARIF 2.1.0 is the only supported version.
"@

    Pause-Demo
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 4: Upload SARIF via CodeQL CLI
# ─────────────────────────────────────────────────────────────────────────────
# Uploads the locally-generated SARIF file to GitHub's Security tab using the
# CodeQL CLI's `github upload-results` command.
#
# KEY CONCEPT: There are THREE ways to get SARIF into GitHub:
#   1. codeql-action/upload-sarif  — in a GitHub Actions workflow
#   2. codeql github upload-results — via the CodeQL CLI (shown here)
#   3. REST API POST to /sarifs     — via gh api or curl
#
# The --sarif-category flag is CRITICAL when multiple scanners upload results.
# Without it, each upload overwrites the previous one. The category creates a
# separate "slot" in the Security tab for each scanner/run combination.
#
# GH-500 EXAM: Know all three upload methods and when to use each.
# ─────────────────────────────────────────────────────────────────────────────
function Invoke-UploadSarif {
    Show-SectionHeader "Upload SARIF via CodeQL CLI" "🚀"

    Show-TalkTrack @"
Same SARIF, different transport. The --sarif-category distinguishes
this CLI upload from the Actions workflow upload. Two Semgrep runs,
two categories, zero overwrites. You can also use the REST API with gh api.
"@

    Push-Location $repoDir

    # Get the current commit SHA — the upload must reference the exact commit
    # so GitHub can map findings to the correct source code version
    $commitSha = git rev-parse HEAD

    Write-Host "  🎯 Upload target:" -ForegroundColor White
    Show-Result "Repository :" $repo
    Show-Result "Ref        :" "refs/heads/$mainBranch"
    Show-Result "Commit     :" $commitSha
    Show-Result "Category   :" "semgrep-rust-local"
    Write-Host ""

    # Upload SARIF to GitHub. Each parameter explained:
    #   --repository       → owner/repo target
    #   --ref              → git ref (branch) the results apply to
    #   --commit           → exact commit SHA for code mapping
    #   --sarif            → path to the SARIF file
    #   --sarif-category   → UNIQUE label to prevent overwriting other results
    Show-Command "codeql github upload-results --repository=$repo --ref=refs/heads/$mainBranch --commit=$commitSha --sarif=rust-scan.sarif --sarif-category=semgrep-rust-local"
    Write-Host ""

    codeql github upload-results `
        --repository=$repo `
        --ref=refs/heads/$mainBranch `
        --commit=$commitSha `
        --sarif=rust-scan.sarif `
        --sarif-category=semgrep-rust-local

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Show-Success "SARIF uploaded successfully"
    } else {
        Write-Host ""
        Show-Failure "Upload failed. Check CodeQL CLI output above."
    }

    Pop-Location

    Show-ExamTip @"
SARIF categories prevent result overwrites. Always set
--sarif-category or the category input when using multiple scanners.
"@

    Pause-Demo
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 5: Examine SARIF Structure
# ─────────────────────────────────────────────────────────────────────────────
# Parses the SARIF JSON to show learners what's inside. Understanding SARIF
# structure is essential for troubleshooting "no results" or "wrong results."
#
# SARIF 2.1.0 STRUCTURE (simplified):
#   {
#     "$schema": "https://raw.githubusercontent.com/.../sarif-schema-2.1.0.json",
#     "version": "2.1.0",
#     "runs": [
#       {
#         "tool": { "driver": { "name": "Semgrep", "rules": [...] } },
#         "results": [
#           {
#             "ruleId": "rust.lang.security...",
#             "message": { "text": "..." },
#             "locations": [...],
#             "partialFingerprints": { ... }  ← how GitHub tracks alerts
#           }
#         ]
#       }
#     ]
#   }
#
# GH-500 EXAM: partialFingerprints allow GitHub to track the SAME finding
# across commits, even if files are renamed or code is refactored.
# ─────────────────────────────────────────────────────────────────────────────
function Invoke-ExamineSarif {
    Show-SectionHeader "Examine SARIF Structure" "📊"

    Show-TalkTrack @"
SARIF 2.1.0 has a clean structure — runs at the top level, each run
has a tool driver with rules, and results with locations. The
partialFingerprints field is how GitHub tracks alerts across commits.
Even if you rename files or refactor, GitHub knows it is the same finding.
"@

    Push-Location $repoDir

    $sarifPath = Join-Path $repoDir "rust-scan.sarif"
    if (Test-Path $sarifPath) {
        Show-Command "ConvertFrom-Json rust-scan.sarif | Select runs"
        Write-Host ""

        # Parse SARIF JSON and extract the summary: tool name, rule count, result count.
        # Each "run" represents one scanner execution. A SARIF file can contain
        # multiple runs (e.g., if you ran Semgrep with multiple rule packs).
        $sarif = Get-Content $sarifPath | ConvertFrom-Json

        Write-Host "  📊 SARIF summary:" -ForegroundColor White
        Write-Host ""
        Write-Host "     ┌──────────────┬──────────┬───────────┐" -ForegroundColor DarkGray
        Write-Host "     │ Tool         │ Rules    │ Results   │" -ForegroundColor White
        Write-Host "     ├──────────────┼──────────┼───────────┤" -ForegroundColor DarkGray

        foreach ($run in $sarif.runs) {
            $toolName   = ($run.tool.driver.name ?? "Unknown").PadRight(12)
            $ruleCount  = ("$($run.tool.driver.rules.Count)").PadRight(8)
            $resultCount = ("$($run.results.Count)").PadRight(9)
            Write-Host "     │ $toolName │ $ruleCount │ $resultCount │" -ForegroundColor Green
        }

        Write-Host "     └──────────────┴──────────┴───────────┘" -ForegroundColor DarkGray
    } else {
        Show-Failure "rust-scan.sarif not found. Run section [3] first."
    }

    Pop-Location

    Pause-Demo
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 6: List & Filter Code Scanning Alerts
# ─────────────────────────────────────────────────────────────────────────────
# Uses the gh CLI to query code scanning alerts via the REST API. This is the
# same API that automation tools, SIEM integrations, and compliance dashboards
# call to pull security data from GitHub.
#
# The --jq flag uses jq syntax to filter/transform JSON responses. Key fields:
#   .rule.id       → the rule that triggered (e.g., "js/code-injection")
#   .tool.name     → which scanner found it ("CodeQL" or "Semgrep")
#   .rule.severity → "error" (high), "warning" (medium), "note" (low)
#   .state         → "open" or "dismissed"
#
# This section shows three progressively filtered views:
#   1. All alert rule IDs (quick overview)
#   2. Alerts with details (number, rule, tool, severity)
#   3. Filtered by tool (Semgrep-only, then CodeQL-only)
# ─────────────────────────────────────────────────────────────────────────────
function Invoke-ListFilterAlerts {
    Show-SectionHeader "List & Filter Code Scanning Alerts" "📋"

    Show-TalkTrack @"
The gh CLI gives you programmatic access to everything in the
Security tab. Let us list all alerts and then filter by scanner tool.
"@

    # View 1: Just the rule IDs — quick overview of what was found
    Write-Host "  📋 All alert rule IDs:" -ForegroundColor White
    Show-Command "gh api repos/$repo/code-scanning/alerts --jq '.[].rule.id'"
    Write-Host ""
    gh api "repos/$repo/code-scanning/alerts" `
        --jq '.[].rule.id' 2>&1 | ForEach-Object { Write-Host "     $_" -ForegroundColor White }

    Write-Host ""

    # View 2: Alerts with details — number + rule + tool + severity
    Write-Host "  📊 Alerts with details (number, rule, tool, severity):" -ForegroundColor White
    Show-Command "gh api repos/$repo/code-scanning/alerts --jq '.[] | {number, rule, tool, severity}'"
    Write-Host ""
    gh api "repos/$repo/code-scanning/alerts" `
        --jq '.[] | {number, rule: .rule.id, tool: .tool.name, severity: .rule.severity}' 2>&1 | ForEach-Object { Write-Host "     $_" -ForegroundColor White }

    Write-Host ""

    # View 3a: Filter to Semgrep-only alerts using jq's select() function.
    # This shows what the THIRD-PARTY scanner found (Rust + JS patterns).
    Write-Host "  🔍 Semgrep alerts only:" -ForegroundColor White
    Show-Command "gh api ... --jq '.[] | select(.tool.name == \"Semgrep\") | {number, rule}'"
    Write-Host ""
    gh api "repos/$repo/code-scanning/alerts" `
        --jq '.[] | select(.tool.name == "Semgrep") | {number, rule: .rule.id}' 2>&1 | ForEach-Object { Write-Host "     $_" -ForegroundColor Green }

    Write-Host ""

    # View 3b: Filter to CodeQL-only alerts.
    # This shows what GitHub's NATIVE scanner found (deeper semantic analysis).
    Write-Host "  🔍 CodeQL alerts only:" -ForegroundColor White
    Show-Command "gh api ... --jq '.[] | select(.tool.name == \"CodeQL\") | {number, rule}'"
    Write-Host ""
    gh api "repos/$repo/code-scanning/alerts" `
        --jq '.[] | select(.tool.name == "CodeQL") | {number, rule: .rule.id}' 2>&1 | ForEach-Object { Write-Host "     $_" -ForegroundColor Green }

    Pause-Demo
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 7: Copilot Autofix (UI Reference)
# ─────────────────────────────────────────────────────────────────────────────
# Copilot Autofix is a browser-only feature — no CLI equivalent. This section
# provides the step-by-step walkthrough for the presenter to follow in the UI.
#
# KEY LICENSING DISTINCTION (GH-500 exam favorite):
#   - Copilot AUTOFIX → included with GHAS, no extra subscription
#   - Copilot CHAT    → requires Copilot Enterprise license (separate cost)
#
# Autofix ONLY works on CodeQL alerts. Third-party scanner results (like
# Semgrep) do NOT get Autofix suggestions. This is because Autofix needs
# CodeQL's semantic code understanding to generate safe patches.
# ─────────────────────────────────────────────────────────────────────────────
function Invoke-CopilotAutofixRef {
    Show-SectionHeader "Copilot Autofix (UI Reference)" "🎯"

    Show-TalkTrack @"
Copilot Autofix is demonstrated in the GitHub web UI. Navigate to:
Security > Code scanning > Filter by Tool: CodeQL > Click eval injection alert
"@

    Write-Host "  📋 Demo steps:" -ForegroundColor White
    Write-Host ""
    Write-Host "     1️⃣  Click ""Generate fix"" on the alert page" -ForegroundColor White
    Write-Host "     2️⃣  Wait 10-30 seconds for AI generation" -ForegroundColor White
    Write-Host "     3️⃣  Review the code diff and plain-English explanation" -ForegroundColor White
    Write-Host "     4️⃣  Click ""Create PR with fix"" (creates a draft PR)" -ForegroundColor White

    Show-ExamTip @"
Autofix works on CodeQL alerts only — not third-party results.
It ships with GHAS, no separate Copilot subscription required.
The draft PR ensures humans make the final judgment call.
"@

    Pause-Demo
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 8: Query Suites, Show Paths, Copilot Chat
# ─────────────────────────────────────────────────────────────────────────────
# This section transitions from Module 5 to Module 6. It covers three
# interconnected concepts that control HOW CodeQL analyzes code and HOW
# you investigate the findings.
#
# QUERY SUITES — control what CodeQL looks for:
#   default              → fewer queries, lower false positive rate
#   security-extended    → broader coverage, more experimental rules
#   security-and-quality → adds code quality checks on top of security
#
# BUILD MODES — control how CodeQL extracts code:
#   none      → interpreted languages (JS, Python, Ruby, Java*)
#   autobuild → GitHub guesses your build system
#   manual    → you provide explicit build commands (needed for C/C++)
#   * Java supports 'none' mode — a common GH-500 exam question
#
# SHOW PATHS — traces data flow from source (user input) to sink (dangerous
# function). An unbroken path = confirmed true positive. This is the single
# most important feature for validating whether an alert is real.
#
# COPILOT CHAT — AI-powered plain-English explanations of vulnerabilities.
# Requires Copilot Enterprise license (separate from GHAS).
# ─────────────────────────────────────────────────────────────────────────────
function Invoke-QuerySuitesRef {
    Show-SectionHeader "Query Suites, Show Paths, Copilot Chat" "🔧"

    Show-TalkTrack @"
In Module 5 we added a second scanner and used Autofix. Now we dig
into query suites, trace data flow with show paths, use Copilot Chat
to explain vulnerabilities, triage alerts, and troubleshoot workflows.
"@

    Write-Host "  📋 Query Suites (Settings > Advanced Security > Code scanning):" -ForegroundColor White
    Write-Host ""
    Write-Host "     ┌────────────────────────┬──────────────────────────────────────┐" -ForegroundColor DarkGray
    Write-Host "     │ Suite                  │ Description                          │" -ForegroundColor White
    Write-Host "     ├────────────────────────┼──────────────────────────────────────┤" -ForegroundColor DarkGray
    Write-Host "     │ default                │ Fewer queries, lower noise, core     │" -ForegroundColor White
    Write-Host "     │ security-extended      │ Wider net, more experimental checks  │" -ForegroundColor White
    Write-Host "     │ security-and-quality   │ Adds code quality on top             │" -ForegroundColor White
    Write-Host "     └────────────────────────┴──────────────────────────────────────┘" -ForegroundColor DarkGray

    Show-ExamTip @"
'default' suite is NOT the same as 'default setup.'
Default setup is zero-config enablement. Default suite is a query set.
"@

    Write-Host ""
    Write-Host "  📋 Build Modes:" -ForegroundColor White
    Write-Host ""
    Write-Host "     ┌─────────────┬───────────────────────────────────────────────┐" -ForegroundColor DarkGray
    Write-Host "     │ Mode        │ Description                                   │" -ForegroundColor White
    Write-Host "     ├─────────────┼───────────────────────────────────────────────┤" -ForegroundColor DarkGray
    Write-Host "     │ none        │ Interpreted languages (JS, Python)             │" -ForegroundColor White
    Write-Host "     │ autobuild   │ GitHub guesses your build system               │" -ForegroundColor White
    Write-Host "     │ manual      │ You specify exact build commands               │" -ForegroundColor White
    Write-Host "     └─────────────┴───────────────────────────────────────────────┘" -ForegroundColor DarkGray

    Show-ExamTip @"
Java supports 'none' mode. C++ typically needs 'manual.'
"@

    Write-Host ""
    Write-Host "  📋 Show Paths (Security > Code scanning > click alert > Show paths):" -ForegroundColor White
    Write-Host ""
    Write-Host "     • Only appears on path-problem queries (source-to-sink data flow)" -ForegroundColor White
    Write-Host "     • Click intermediate nodes to jump to exact code lines" -ForegroundColor White
    Write-Host "     • Validates true positives — unbroken path = confirmed vulnerability" -ForegroundColor White

    Write-Host ""
    Write-Host "  📋 Copilot Chat prompts (on alert detail page, click Copilot icon):" -ForegroundColor White
    Write-Host ""
    Write-Host "     1. ""Explain how this alert introduces a vulnerability.""" -ForegroundColor Yellow
    Write-Host "     2. ""What is the recommended fix for this vulnerability?""" -ForegroundColor Yellow
    Write-Host "     3. ""Why doesn't the existing code prevent exploitation?""" -ForegroundColor Yellow
    Write-Host "     4. ""How can I test that my fix prevents this vulnerability?""" -ForegroundColor Yellow

    Show-ExamTip @"
Copilot Chat requires Copilot Enterprise license (separate from GHAS).
Autofix ships with GHAS alone; Chat is the add-on.
"@

    Pause-Demo
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 9: List All Code Scanning Alerts
# ─────────────────────────────────────────────────────────────────────────────
# Simple listing of all alerts with key metadata. This is the starting point
# for triage — you need to see the full landscape before deciding what to
# dismiss, fix, or escalate.
# ─────────────────────────────────────────────────────────────────────────────
function Invoke-ListAllAlerts {
    Show-SectionHeader "List All Code Scanning Alerts" "📊"

    Show-TalkTrack @"
Before triaging, let us see what we are working with.
List every alert with its number, rule, tool, and severity.
"@

    Show-Command "gh api repos/$repo/code-scanning/alerts --jq '.[] | {number, rule, tool, severity}'"
    Write-Host ""

    gh api "repos/$repo/code-scanning/alerts" `
        --jq '.[] | {number, rule: .rule.id, tool: .tool.name, severity: .rule.severity}' 2>&1 | ForEach-Object { Write-Host "     $_" -ForegroundColor White }

    Pause-Demo
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 10: Filter Alerts by Severity
# ─────────────────────────────────────────────────────────────────────────────
# Demonstrates severity-based triage using jq's select() function.
#
# SEVERITY MAPPING (GH-500 exam):
#   "error"   → high/critical findings  → fix immediately
#   "warning" → medium findings          → fix in next sprint
#   "note"    → low/informational        → address when convenient
#
# In real triage workflows, security teams typically:
#   1. Filter to "error" severity first
#   2. Validate each with Show Paths (true positive check)
#   3. Assign to developers for remediation
#   4. Dismiss false positives with documented reasoning
# ─────────────────────────────────────────────────────────────────────────────
function Invoke-FilterBySeverity {
    Show-SectionHeader "Filter Alerts by Severity" "🔍"

    Show-TalkTrack @"
Severity 'error' maps to high/critical findings. This is what the
security team should prioritize. Warnings and notes can wait.
"@

    # High/critical alerts — the "fix now" category
    Write-Host "  🔴 High/Critical alerts (severity = error):" -ForegroundColor White
    Show-Command "gh api ... --jq '.[] | select(.rule.severity == \"error\") | {number, rule}'"
    Write-Host ""
    gh api "repos/$repo/code-scanning/alerts" `
        --jq '.[] | select(.rule.severity == "error") | {number, rule: .rule.id}' 2>&1 | ForEach-Object { Write-Host "     $_" -ForegroundColor Red }

    Write-Host ""

    # Warning-level alerts — the "fix soon" category
    Write-Host "  🟡 Warning-level alerts:" -ForegroundColor White
    Show-Command "gh api ... --jq '.[] | select(.rule.severity == \"warning\") | {number, rule}'"
    Write-Host ""
    gh api "repos/$repo/code-scanning/alerts" `
        --jq '.[] | select(.rule.severity == "warning") | {number, rule: .rule.id}' 2>&1 | ForEach-Object { Write-Host "     $_" -ForegroundColor Yellow }

    Show-ExamTip @"
Severity 'error' maps to high/critical. 'warning' is medium.
'note' is low. Triage by severity to focus on what matters.
"@

    Pause-Demo
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 11: Dismiss an Alert
# ─────────────────────────────────────────────────────────────────────────────
# Demonstrates alert dismissal via the REST API. This is a core triage action
# that creates an AUDIT TRAIL — critical for compliance (SOC 2, ISO 27001).
#
# THREE DISMISSAL REASONS (GH-500 exam):
#   1. "false positive"  → the scanner is wrong, this isn't a real vulnerability
#   2. "won't fix"       → real issue but accepted risk (business decision)
#   3. "used in tests"   → vulnerable code is intentional (test/demo context)
#
# The dismissed_comment field provides free-text documentation. In regulated
# environments, this comment should be defensible in an audit.
#
# IMPORTANT: This section includes a confirmation prompt because dismissing
# alerts is a state-changing operation. The presenter picks an alert number
# interactively to keep the demo flexible.
# ─────────────────────────────────────────────────────────────────────────────
function Invoke-DismissAlert {
    Show-SectionHeader "Dismiss an Alert via API" "⚡"

    Show-TalkTrack @"
Not every alert demands immediate remediation. The dismissal workflow
lets you document decisions and creates an audit trail.
Three reasons: false positive, won't fix, used in tests.
"@

    Show-ExamTip @"
Dismissals require documentation. All three reasons create
audit trails. This is important for compliance.
"@

    # First, show what's available to dismiss
    Write-Host "  📋 Current open alerts:" -ForegroundColor White
    Show-Command "gh api repos/$repo/code-scanning/alerts --jq '.[] | select(.state == \"open\")'"
    Write-Host ""
    gh api "repos/$repo/code-scanning/alerts" `
        --jq '.[] | select(.state == "open") | {number, rule: .rule.id, tool: .tool.name}' 2>&1 | ForEach-Object { Write-Host "     $_" -ForegroundColor White }

    Write-Host ""
    $alertNumber = Read-Host "  🎯 Enter alert number to dismiss (or press Enter to skip)"

    if ($alertNumber -and $alertNumber -match '^\d+$') {
        if (Confirm-Action "Dismiss alert #$alertNumber with reason 'used in tests'?") {
            # PATCH request to change alert state. The API fields:
            #   state              → "dismissed" (or "open" to reopen)
            #   dismissed_reason   → one of the three allowed values
            #   dismissed_comment  → free-text audit documentation
            Show-Command "gh api repos/$repo/code-scanning/alerts/$alertNumber --method PATCH --field state=dismissed"
            Write-Host ""

            gh api "repos/$repo/code-scanning/alerts/$alertNumber" `
                --method PATCH `
                --field state=dismissed `
                --field dismissed_reason="used in tests" `
                --field dismissed_comment="Educational demo repo with intentional vulnerabilities"

            if ($LASTEXITCODE -eq 0) {
                Show-Success "Alert #$alertNumber dismissed"
            } else {
                Show-Failure "Failed to dismiss alert #$alertNumber"
            }

            # Verify the dismissal by fetching the alert's current state
            Write-Host ""
            Write-Host "  🔍 Verification:" -ForegroundColor White
            gh api "repos/$repo/code-scanning/alerts/$alertNumber" `
                --jq '{number, state, dismissed_reason, dismissed_comment}' 2>&1 | ForEach-Object { Write-Host "     $_" -ForegroundColor Green }
        } else {
            Write-Host "     Skipped dismissal." -ForegroundColor DarkGray
        }
    } else {
        Write-Host "     No alert selected — skipping dismissal demo." -ForegroundColor DarkGray
    }

    Pause-Demo
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 12: Re-open a Dismissed Alert
# ─────────────────────────────────────────────────────────────────────────────
# Demonstrates that dismissals are NOT permanent. Alerts can be reopened when:
#   - A false positive turns out to be a true positive after further analysis
#   - A "won't fix" decision is reversed due to new threat intelligence
#   - Demo/test code is promoted to production (changes context)
#
# This uses the same PATCH endpoint but sets state back to "open".
# The previous dismissal metadata (reason, comment, who dismissed it, when)
# remains in the alert's history for audit purposes.
# ─────────────────────────────────────────────────────────────────────────────
function Invoke-ReopenAlert {
    Show-SectionHeader "Re-open a Dismissed Alert" "⚡"

    Show-TalkTrack @"
Dismissals are not permanent. If circumstances change — say a demo
repo becomes production code — you can re-open alerts.
"@

    # List dismissed alerts so the presenter can pick one to reopen
    Write-Host "  📋 Dismissed alerts:" -ForegroundColor White
    Show-Command "gh api repos/$repo/code-scanning/alerts?state=dismissed"
    Write-Host ""
    gh api "repos/$repo/code-scanning/alerts?state=dismissed" `
        --jq '.[] | {number, rule: .rule.id, dismissed_reason}' 2>&1 | ForEach-Object { Write-Host "     $_" -ForegroundColor White }

    Write-Host ""
    $reopenNumber = Read-Host "  🎯 Enter alert number to re-open (or press Enter to skip)"

    if ($reopenNumber -and $reopenNumber -match '^\d+$') {
        if (Confirm-Action "Re-open alert #${reopenNumber}?") {
            # Setting state back to "open" — no reason or comment needed for reopening
            Show-Command "gh api repos/$repo/code-scanning/alerts/$reopenNumber --method PATCH --field state=open"
            Write-Host ""

            gh api "repos/$repo/code-scanning/alerts/$reopenNumber" `
                --method PATCH `
                --field state=open

            if ($LASTEXITCODE -eq 0) {
                Show-Success "Alert #$reopenNumber re-opened"
            } else {
                Show-Failure "Failed to re-open alert #$reopenNumber"
            }

            # Verify it's back to open state
            Write-Host ""
            Write-Host "  🔍 Verification:" -ForegroundColor White
            gh api "repos/$repo/code-scanning/alerts/$reopenNumber" `
                --jq '{number, state, dismissed_reason}' 2>&1 | ForEach-Object { Write-Host "     $_" -ForegroundColor Green }
        } else {
            Write-Host "     Skipped re-open." -ForegroundColor DarkGray
        }
    } else {
        Write-Host "     No alert selected — skipping re-open demo." -ForegroundColor DarkGray
    }

    Pause-Demo
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 13: Check Workflow Run Status
# ─────────────────────────────────────────────────────────────────────────────
# First step in troubleshooting: is the workflow passing, failing, or stuck?
# `gh run list` shows recent workflow runs with their status and conclusion.
#
# We check both the CodeQL workflow (codeql.yml) and the Semgrep workflow
# (semgrep-analysis.yml) separately since they run as independent jobs.
# ─────────────────────────────────────────────────────────────────────────────
function Invoke-WorkflowStatus {
    Show-SectionHeader "Check Workflow Run Status" "🚀"

    Show-TalkTrack @"
When troubleshooting, start with the workflow status. Is it passing,
failing, or stuck? The gh CLI gives you a quick summary.
"@

    Write-Host "  📊 Recent CodeQL workflow runs:" -ForegroundColor White
    Show-Command "gh run list --repo $repo --workflow=codeql.yml --limit 5"
    Write-Host ""
    gh run list `
        --repo $repo `
        --workflow=codeql.yml `
        --limit 5 2>&1 | ForEach-Object { Write-Host "     $_" -ForegroundColor White }

    Write-Host ""

    Write-Host "  📊 Recent Semgrep workflow runs:" -ForegroundColor White
    Show-Command "gh run list --repo $repo --workflow=semgrep-analysis.yml --limit 5"
    Write-Host ""
    gh run list `
        --repo $repo `
        --workflow=semgrep-analysis.yml `
        --limit 5 2>&1 | ForEach-Object { Write-Host "     $_" -ForegroundColor White }

    Pause-Demo
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 14: View Workflow Logs
# ─────────────────────────────────────────────────────────────────────────────
# Deep-dive into workflow logs for a specific run. This is where you find the
# root cause of failures: permission errors (403), build failures, extraction
# issues, timeout problems, etc.
#
# The presenter picks a run ID from the list (section 13) and views the first
# 100 lines of logs. In practice, you'd search for "error" or "failed" in the
# full log output.
#
# TIP FOR LEARNERS: The most common CodeQL failures and their log signatures:
#   - "403 Forbidden"          → missing security-events: write permission
#   - "No source code found"   → wrong working directory or language mismatch
#   - "Build failed"           → need build-mode: manual with explicit commands
#   - "Timed out"              → increase timeout-minutes or split into matrix
# ─────────────────────────────────────────────────────────────────────────────
function Invoke-WorkflowLogs {
    Show-SectionHeader "View Workflow Logs" "📋"

    Show-TalkTrack @"
The logs tell you everything. Permission failures show 403. Build
failures show compiler errors. Extraction issues list which files
could not be processed. When someone says 'CodeQL isn't working,'
the first thing you do is read the logs.
"@

    Write-Host "  📋 Recent workflow runs (all workflows):" -ForegroundColor White
    Show-Command "gh run list --repo $repo --limit 10"
    Write-Host ""
    gh run list --repo $repo --limit 10 2>&1 | ForEach-Object { Write-Host "     $_" -ForegroundColor White }

    Write-Host ""
    $runId = Read-Host "  🎯 Enter a run ID to view logs (or press Enter to skip)"

    if ($runId -and $runId -match '^\d+$') {
        # Truncate to first 100 lines — full logs can be thousands of lines
        Show-Command "gh run view $runId --repo $repo --log | Select-Object -First 100"
        Write-Host ""
        gh run view $runId --repo $repo --log 2>&1 | Select-Object -First 100 | ForEach-Object { Write-Host "     $_" -ForegroundColor White }
        Write-Host ""
        Write-Host "     (Output truncated to first 100 lines)" -ForegroundColor DarkGray
    } else {
        Write-Host "     No run selected — skipping log view." -ForegroundColor DarkGray
    }

    Pause-Demo
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 15: Common Failure Scenarios Reference
# ─────────────────────────────────────────────────────────────────────────────
# Quick-reference troubleshooting table. These are the five most common CodeQL
# and SARIF upload failures that learners will encounter in practice.
#
# THE 90% RULE: Most CodeQL failures come from not being explicit enough in
# configuration. The default auto-detection works for simple projects, but
# enterprise codebases with custom build systems, monorepos, or unusual
# directory structures need explicit configuration.
# ─────────────────────────────────────────────────────────────────────────────
function Invoke-FailureScenariosRef {
    Show-SectionHeader "Common Failure Scenarios Reference" "⚠️"

    Write-Host "  📋 Common CodeQL / SARIF upload failures:" -ForegroundColor White
    Write-Host ""
    Write-Host "  ┌───────────────────────────┬──────────────────────────┬──────────────────────────────┐" -ForegroundColor DarkGray
    Write-Host "  │ Error                     │ Cause                    │ Fix                          │" -ForegroundColor White
    Write-Host "  ├───────────────────────────┼──────────────────────────┼──────────────────────────────┤" -ForegroundColor DarkGray
    Write-Host "  │ Language detection failed  │ Auto-detection missed    │ Specify languages explicitly │" -ForegroundColor White
    Write-Host "  │ Autobuild failed           │ Non-standard build       │ Use build-mode: manual       │" -ForegroundColor White
    Write-Host "  │ Timeout exceeded           │ Large codebase           │ Increase timeout-minutes     │" -ForegroundColor White
    Write-Host "  │ Permission denied (403)    │ Missing permission       │ Add security-events: write   │" -ForegroundColor White
    Write-Host "  │ No results returned        │ Extraction failed        │ Check logs, try extended     │" -ForegroundColor White
    Write-Host "  └───────────────────────────┴──────────────────────────┴──────────────────────────────┘" -ForegroundColor DarkGray

    Show-ExamTip @"
Default setup = interpreted languages.
Advanced setup with build-mode: manual = compiled languages
with complex builds. 90% of CodeQL failures come from not
being explicit enough in configuration.
"@

    Pause-Demo
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 16: Full Semgrep Scan (entire repo)
# ─────────────────────────────────────────────────────────────────────────────
# Runs Semgrep against the ENTIRE repository (not just the Rust directory).
# Uses both the security-audit and Rust rule packs for comprehensive coverage.
#
# This is a "bonus" section — useful if the presenter has extra time or if
# learners want to see the full finding landscape. The scan can take 1-3
# minutes depending on repo size and network speed (rules are downloaded
# from the Semgrep registry on each run).
#
# The results are saved to results.sarif (separate from rust-scan.sarif)
# and could be uploaded with a different --sarif-category if desired.
# ─────────────────────────────────────────────────────────────────────────────
function Invoke-FullSemgrepScan {
    Show-SectionHeader "Full Semgrep Scan (entire repo)" "🔍"

    Write-Host "  This runs Semgrep against the entire repository with both" -ForegroundColor White
    Write-Host "  security-audit and Rust rule packs for a comprehensive scan." -ForegroundColor White

    if (Confirm-Action "Run full Semgrep scan on the entire repository?") {
        Push-Location $repoDir

        # Two rule packs combined:
        #   p/security-audit → broad security rules for JS, Python, and more
        #   p/rust           → Rust-specific security rules
        Show-Command "semgrep scan --config p/security-audit --config p/rust --sarif --output results.sarif ."
        Write-Host ""

        semgrep scan `
            --config p/security-audit `
            --config p/rust `
            --sarif `
            --output results.sarif `
            .

        if (Test-Path results.sarif) {
            Show-Success "Full scan complete"
            Write-Host ""

            Write-Host "  📊 SARIF file details:" -ForegroundColor White
            $item = Get-Item results.sarif
            Show-Result "Name    :" $item.Name
            Show-Result "Size    :" "$($item.Length) bytes"
            Show-Result "Modified:" $item.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")

            Write-Host ""

            # Parse and display the same summary table as section 5
            $sarif = Get-Content results.sarif | ConvertFrom-Json
            Write-Host "  📊 Results summary:" -ForegroundColor White
            Write-Host ""
            Write-Host "     ┌──────────────┬──────────┬───────────┐" -ForegroundColor DarkGray
            Write-Host "     │ Tool         │ Rules    │ Results   │" -ForegroundColor White
            Write-Host "     ├──────────────┼──────────┼───────────┤" -ForegroundColor DarkGray

            foreach ($run in $sarif.runs) {
                $toolName    = ($run.tool.driver.name ?? "Unknown").PadRight(12)
                $ruleCount   = ("$($run.tool.driver.rules.Count)").PadRight(8)
                $resultCount = ("$($run.results.Count)").PadRight(9)
                Write-Host "     │ $toolName │ $ruleCount │ $resultCount │" -ForegroundColor Green
            }

            Write-Host "     └──────────────┴──────────┴───────────┘" -ForegroundColor DarkGray
        } else {
            Show-Failure "SARIF file was not created. Check Semgrep output above."
        }

        Pop-Location
    } else {
        Write-Host "     Skipped full scan." -ForegroundColor DarkGray
    }

    Pause-Demo
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 17: Run All Sections Sequentially
# ─────────────────────────────────────────────────────────────────────────────
# Runs every section in order with pauses between each. Useful for:
#   - Full dry-run before a live presentation
#   - Recording a complete walkthrough video
#   - Self-paced learner practice (run everything, then review)
#
# Ends with a recap of both modules' key takeaways — the same points that
# appear in the DEMO-PUNCHLIST.md wrap-up sections.
# ─────────────────────────────────────────────────────────────────────────────
function Invoke-RunAll {
    Show-SectionHeader "Run All Sections Sequentially" "🚀"

    Write-Host "  This will run through every section with pauses between each." -ForegroundColor White
    Write-Host ""

    if (Confirm-Action "Run all demo sections sequentially?") {
        Invoke-PreflightChecks
        Invoke-SemgrepWorkflowRef
        Invoke-SemgrepLocalScan
        Invoke-UploadSarif
        Invoke-ExamineSarif
        Invoke-ListFilterAlerts
        Invoke-CopilotAutofixRef
        Invoke-QuerySuitesRef
        Invoke-ListAllAlerts
        Invoke-FilterBySeverity
        Invoke-DismissAlert
        Invoke-ReopenAlert
        Invoke-WorkflowStatus
        Invoke-WorkflowLogs
        Invoke-FailureScenariosRef
        Invoke-FullSemgrepScan

        # Final recap — summarizes both modules for learner retention
        Show-SectionHeader "Demo Complete" "✅"

        Write-Host "  📊 Module 5 Recap:" -ForegroundColor Green
        Write-Host "     • Third-party scanners (Semgrep) output SARIF 2.1.0 and use upload-sarif" -ForegroundColor White
        Write-Host "     • Categories prevent result overwrites across multiple scanners" -ForegroundColor White
        Write-Host "     • CLI and REST API bridge non-GitHub CI systems" -ForegroundColor White
        Write-Host "     • Copilot Autofix generates fixes for CodeQL alerts (ships with GHAS)" -ForegroundColor White
        Write-Host ""
        Write-Host "  📊 Module 6 Recap:" -ForegroundColor Green
        Write-Host "     • Query suites: default (minimal), security-extended (comprehensive)" -ForegroundColor White
        Write-Host "     • Build modes: none, autobuild, manual — know when to switch" -ForegroundColor White
        Write-Host "     • Show paths traces source to sink for true positive validation" -ForegroundColor White
        Write-Host "     • Copilot Chat explains vulns in plain English (requires Copilot Enterprise)" -ForegroundColor White
        Write-Host "     • Dismissals require documentation with defensible reasoning" -ForegroundColor White
        Write-Host "     • Troubleshooting: be more explicit in configuration" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host "     Cancelled." -ForegroundColor DarkGray
    }

    Pause-Demo
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN LOOP
# ─────────────────────────────────────────────────────────────────────────────
# Simple menu-driven loop. The presenter selects a number, the corresponding
# function runs, and control returns to the menu. Enter 0 to exit.
#
# TIP FOR LEARNERS: You can run this script yourself to practice! Just update
# the $repoDir variable at the top to point to your local clone, and make sure
# gh, semgrep, and codeql CLIs are installed and authenticated.
# ═══════════════════════════════════════════════════════════════════════════════

$running = $true

while ($running) {
    Show-Banner
    Show-Menu

    $choice = Read-Host "  Enter selection"

    switch ($choice) {
        "1"  { Invoke-PreflightChecks }
        "2"  { Invoke-SemgrepWorkflowRef }
        "3"  { Invoke-SemgrepLocalScan }
        "4"  { Invoke-UploadSarif }
        "5"  { Invoke-ExamineSarif }
        "6"  { Invoke-ListFilterAlerts }
        "7"  { Invoke-CopilotAutofixRef }
        "8"  { Invoke-QuerySuitesRef }
        "9"  { Invoke-ListAllAlerts }
        "10" { Invoke-FilterBySeverity }
        "11" { Invoke-DismissAlert }
        "12" { Invoke-ReopenAlert }
        "13" { Invoke-WorkflowStatus }
        "14" { Invoke-WorkflowLogs }
        "15" { Invoke-FailureScenariosRef }
        "16" { Invoke-FullSemgrepScan }
        "17" { Invoke-RunAll }
        "0"  {
            Write-Host ""
            Write-Host "  👋 Thanks for using the GHAS Code Scanning Demo Console!" -ForegroundColor Cyan
            Write-Host ""
            $running = $false
        }
        default {
            Show-Warning "Invalid selection. Please enter a number from 0-17."
            Start-Sleep -Seconds 1
        }
    }
}
