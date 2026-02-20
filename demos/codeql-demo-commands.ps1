#Requires -Version 7.0
<#
.SYNOPSIS
    Globomantics Robot Fleet — Code Scanning Demo Console (Modules 5 & 6)

.DESCRIPTION
    Interactive presenter console for the GH-500 / GHAS course covering:
      - Module 5: Third-party scanners (Semgrep), SARIF upload, CLI integration
      - Module 6: Alert triage, dismissal/reopen, workflow troubleshooting, Copilot Chat prompts

    Features a numbered menu so the presenter can jump to any section.

.NOTES
    Repository : timothywarner-org/globomantics-robot-fleet
    PowerShell : 7.x required
    Prerequisites:
      - gh CLI authenticated (gh auth status)
      - Semgrep CLI installed (pip install semgrep)
      - CodeQL CLI installed (for SARIF upload)
      - Repo cloned locally
#>

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

$repo       = "timothywarner-org/globomantics-robot-fleet"
$repoDir    = "C:\repos\globomantics-robot-fleet"
$mainBranch = "main"

# ═══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

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

function Show-SectionHeader {
    param([string]$Title, [string]$Emoji = "📌")
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║  $Emoji  $($Title.PadRight(53))║" -ForegroundColor Cyan
    Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Command {
    param([string]$Command)
    Write-Host "  ⚡ Running:" -ForegroundColor Yellow -NoNewline
    Write-Host " $Command" -ForegroundColor Yellow
    Write-Host "  ─────────────────────────────────────────────────────────" -ForegroundColor DarkGray
}

function Show-TalkTrack {
    param([string]$Text)
    Write-Host ""
    Write-Host "  🎙️  TALK TRACK:" -ForegroundColor DarkGray
    $Text -split "`n" | ForEach-Object {
        Write-Host "     $_" -ForegroundColor DarkGray
    }
    Write-Host ""
}

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

function Pause-Demo {
    param([string]$Message = "Press Enter to return to the menu...")
    Write-Host ""
    Write-Host "  ⏸️  $Message" -ForegroundColor DarkGray
    Read-Host
}

function Confirm-Action {
    param([string]$Message)
    Write-Host ""
    Write-Host "  ⚠️  $Message" -ForegroundColor Yellow
    $response = Read-Host "     Type 'y' to confirm (y/N)"
    return ($response -eq 'y' -or $response -eq 'Y')
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

function Invoke-PreflightChecks {
    Show-SectionHeader "Pre-flight Checks" "🔧"

    Show-TalkTrack "Before we begin, let's verify all our tools are ready."

    # GitHub CLI
    Write-Host "  🔍 Checking GitHub CLI..." -ForegroundColor White
    Show-Command "gh auth status"
    try {
        gh auth status 2>&1 | ForEach-Object { Write-Host "     $_" -ForegroundColor White }
        Show-Success "GitHub CLI authenticated"
    } catch {
        Show-Failure "GitHub CLI not authenticated. Run: gh auth login"
    }
    Write-Host ""

    # Semgrep CLI
    Write-Host "  🔍 Checking Semgrep CLI..." -ForegroundColor White
    Show-Command "semgrep --version"
    try {
        $semgrepVersion = semgrep --version 2>&1
        Show-Success "Semgrep version: $semgrepVersion"
    } catch {
        Show-Failure "Semgrep CLI not found. Install with: pip install semgrep"
    }
    Write-Host ""

    # CodeQL CLI
    Write-Host "  🔍 Checking CodeQL CLI..." -ForegroundColor White
    Show-Command "codeql version"
    try {
        $codeqlVersion = codeql version 2>&1 | Select-Object -First 1
        Show-Success "CodeQL version: $codeqlVersion"
    } catch {
        Show-Failure "CodeQL CLI not found. SARIF upload section will not work."
    }
    Write-Host ""

    # Repo directory
    Write-Host "  🔍 Checking repository directory..." -ForegroundColor White
    if (Test-Path $repoDir) {
        Show-Success "Repo directory exists: $repoDir"
    } else {
        Show-Failure "Repo directory not found at $repoDir — update `$repoDir variable."
    }
    Write-Host ""

    # Check CodeQL default setup configuration
    Write-Host "`n🔧 CodeQL Repository Configuration:" -ForegroundColor Cyan
    $setupJson = gh api repos/timothywarner-org/globomantics-robot-fleet/code-scanning/default-setup 2>&1
    if ($LASTEXITCODE -eq 0) {
        $setup = $setupJson | ConvertFrom-Json
        Write-Host "   ✅ State:      $($setup.state)" -ForegroundColor Green
        Write-Host "   📋 Languages:  $($setup.languages -join ', ')" -ForegroundColor White
        Write-Host "   🔍 Query Suite: $($setup.query_suite)" -ForegroundColor White
        Write-Host "   📅 Updated:    $($setup.updated_at)" -ForegroundColor DarkGray

        # Highlight the setup type
        if ($setup.state -eq 'configured') {
            Write-Host "   💡 Using DEFAULT SETUP (zero-config)" -ForegroundColor Magenta
            Write-Host "      GH-500 TIP: 'default setup' ≠ 'default suite'" -ForegroundColor Magenta
        }
    } else {
        Write-Host "   ⚠️  CodeQL default setup not configured" -ForegroundColor Yellow
        Write-Host "   Checking for advanced setup (custom workflow)..." -ForegroundColor DarkGray
        gh run list --repo timothywarner-org/globomantics-robot-fleet --workflow=codeql.yml --limit=3
    }

    # Configuration summary
    Write-Host ""
    Write-Host "  ╭─────────────────────────────────────────────────────────╮" -ForegroundColor Cyan
    Write-Host "  │ 🔧 Configuration                                        │" -ForegroundColor Cyan
    Write-Host "  │   Repo     : $($repo.PadRight(42))│" -ForegroundColor Cyan
    Write-Host "  │   RepoDir  : $($repoDir.PadRight(42))│" -ForegroundColor Cyan
    Write-Host "  │   Branch   : $($mainBranch.PadRight(42))│" -ForegroundColor Cyan
    Write-Host "  ╰─────────────────────────────────────────────────────────╯" -ForegroundColor Cyan

    Pause-Demo
}

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

    Show-Command "semgrep scan --config p/rust --sarif --output rust-scan.sarif ./rust-telemetry-cli"
    Write-Host ""
    semgrep scan `
        --config p/rust `
        --sarif `
        --output rust-scan.sarif `
        ./rust-telemetry-cli

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

function Invoke-UploadSarif {
    Show-SectionHeader "Upload SARIF via CodeQL CLI" "🚀"

    Show-TalkTrack @"
Same SARIF, different transport. The --sarif-category distinguishes
this CLI upload from the Actions workflow upload. Two Semgrep runs,
two categories, zero overwrites. You can also use the REST API with gh api.
"@

    Push-Location $repoDir

    $commitSha = git rev-parse HEAD

    Write-Host "  🎯 Upload target:" -ForegroundColor White
    Show-Result "Repository :" $repo
    Show-Result "Ref        :" "refs/heads/$mainBranch"
    Show-Result "Commit     :" $commitSha
    Show-Result "Category   :" "semgrep-rust-local"
    Write-Host ""

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

function Invoke-ListFilterAlerts {
    Show-SectionHeader "List & Filter Code Scanning Alerts" "📋"

    Show-TalkTrack @"
The gh CLI gives you programmatic access to everything in the
Security tab. Let us list all alerts and then filter by scanner tool.
"@

    # All alert rule IDs
    Write-Host "  📋 All alert rule IDs:" -ForegroundColor White
    Show-Command "gh api repos/$repo/code-scanning/alerts --jq '.[].rule.id'"
    Write-Host ""
    gh api "repos/$repo/code-scanning/alerts" `
        --jq '.[].rule.id' 2>&1 | ForEach-Object { Write-Host "     $_" -ForegroundColor White }

    Write-Host ""

    # Alerts with details
    Write-Host "  📊 Alerts with details (number, rule, tool, severity):" -ForegroundColor White
    Show-Command "gh api repos/$repo/code-scanning/alerts --jq '.[] | {number, rule, tool, severity}'"
    Write-Host ""
    gh api "repos/$repo/code-scanning/alerts" `
        --jq '.[] | {number, rule: .rule.id, tool: .tool.name, severity: .rule.severity}' 2>&1 | ForEach-Object { Write-Host "     $_" -ForegroundColor White }

    Write-Host ""

    # Semgrep-only alerts
    Write-Host "  🔍 Semgrep alerts only:" -ForegroundColor White
    Show-Command "gh api ... --jq '.[] | select(.tool.name == \"Semgrep\") | {number, rule}'"
    Write-Host ""
    gh api "repos/$repo/code-scanning/alerts" `
        --jq '.[] | select(.tool.name == "Semgrep") | {number, rule: .rule.id}' 2>&1 | ForEach-Object { Write-Host "     $_" -ForegroundColor Green }

    Write-Host ""

    # CodeQL-only alerts
    Write-Host "  🔍 CodeQL alerts only:" -ForegroundColor White
    Show-Command "gh api ... --jq '.[] | select(.tool.name == \"CodeQL\") | {number, rule}'"
    Write-Host ""
    gh api "repos/$repo/code-scanning/alerts" `
        --jq '.[] | select(.tool.name == "CodeQL") | {number, rule: .rule.id}' 2>&1 | ForEach-Object { Write-Host "     $_" -ForegroundColor Green }

    Pause-Demo
}

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

function Invoke-FilterBySeverity {
    Show-SectionHeader "Filter Alerts by Severity" "🔍"

    Show-TalkTrack @"
Severity 'error' maps to high/critical findings. This is what the
security team should prioritize. Warnings and notes can wait.
"@

    Write-Host "  🔴 High/Critical alerts (severity = error):" -ForegroundColor White
    Show-Command "gh api ... --jq '.[] | select(.rule.severity == \"error\") | {number, rule}'"
    Write-Host ""
    gh api "repos/$repo/code-scanning/alerts" `
        --jq '.[] | select(.rule.severity == "error") | {number, rule: .rule.id}' 2>&1 | ForEach-Object { Write-Host "     $_" -ForegroundColor Red }

    Write-Host ""

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

    # Show open alerts
    Write-Host "  📋 Current open alerts:" -ForegroundColor White
    Show-Command "gh api repos/$repo/code-scanning/alerts --jq '.[] | select(.state == \"open\")'"
    Write-Host ""
    gh api "repos/$repo/code-scanning/alerts" `
        --jq '.[] | select(.state == "open") | {number, rule: .rule.id, tool: .tool.name}' 2>&1 | ForEach-Object { Write-Host "     $_" -ForegroundColor White }

    Write-Host ""
    $alertNumber = Read-Host "  🎯 Enter alert number to dismiss (or press Enter to skip)"

    if ($alertNumber -and $alertNumber -match '^\d+$') {
        if (Confirm-Action "Dismiss alert #$alertNumber with reason 'used in tests'?") {
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

            # Verify
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

function Invoke-ReopenAlert {
    Show-SectionHeader "Re-open a Dismissed Alert" "⚡"

    Show-TalkTrack @"
Dismissals are not permanent. If circumstances change — say a demo
repo becomes production code — you can re-open alerts.
"@

    # Show dismissed alerts
    Write-Host "  📋 Dismissed alerts:" -ForegroundColor White
    Show-Command "gh api repos/$repo/code-scanning/alerts?state=dismissed"
    Write-Host ""
    gh api "repos/$repo/code-scanning/alerts?state=dismissed" `
        --jq '.[] | {number, rule: .rule.id, dismissed_reason}' 2>&1 | ForEach-Object { Write-Host "     $_" -ForegroundColor White }

    Write-Host ""
    $reopenNumber = Read-Host "  🎯 Enter alert number to re-open (or press Enter to skip)"

    if ($reopenNumber -and $reopenNumber -match '^\d+$') {
        if (Confirm-Action "Re-open alert #${reopenNumber}?") {
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

            # Verify
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

function Invoke-FullSemgrepScan {
    Show-SectionHeader "Full Semgrep Scan (entire repo)" "🔍"

    Write-Host "  This runs Semgrep against the entire repository with both" -ForegroundColor White
    Write-Host "  security-audit and Rust rule packs for a comprehensive scan." -ForegroundColor White

    if (Confirm-Action "Run full Semgrep scan on the entire repository?") {
        Push-Location $repoDir

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

        # Wrap-up
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
