#Requires -Version 7.0
<#
.SYNOPSIS
    Globomantics Robot Fleet - Semgrep SAST Scanner Demo Console

.DESCRIPTION
    Interactive presenter console for the GH-500 / GHAS course covering
    Semgrep local scanning, SARIF output inspection, GitHub upload, and
    code scanning alert management.

    Provides a numbered menu with pre-flight checks, scan options, SARIF
    analysis, and GitHub API integration.

.NOTES
    Repository : timothywarner-org/globomantics-robot-fleet
    PowerShell : 7.x required
    Prerequisites:
      - Semgrep CLI installed (pip install semgrep)
      - CodeQL CLI installed (for SARIF upload)
      - gh CLI authenticated (gh auth status)
      - Repo cloned locally
#>

# ============================================================================
# CONFIGURATION
# ============================================================================

$repo    = "timothywarner-org/globomantics-robot-fleet"
$repoDir = "C:\github\globomantics-robot-fleet"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Show-Banner {
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║  🐍 Semgrep SAST Scanner Demo Console           ║" -ForegroundColor Cyan
    Write-Host "  ║  Globomantics Robot Fleet Manager                ║" -ForegroundColor Cyan
    Write-Host "  ╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Section {
    param([string]$Title, [string]$Emoji = "🛡️")
    Write-Host ""
    Write-Host ("  ═" * 35) -ForegroundColor Cyan
    Write-Host "  $Emoji $Title" -ForegroundColor Cyan
    Write-Host ("  ═" * 35) -ForegroundColor Cyan
    Write-Host ""
}

function Show-Command {
    param([string]$Command)
    Write-Host ""
    Write-Host "  ⚡ Running:" -ForegroundColor DarkGray
    Write-Host "  $Command" -ForegroundColor Yellow
    Write-Host ""
}

function Show-ExamTip {
    param([string]$Tip)
    Write-Host ""
    Write-Host "  🎯 GH-500 EXAM TIP:" -ForegroundColor Magenta
    Write-Host "  $Tip" -ForegroundColor Magenta
    Write-Host ""
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

function Show-Info {
    param([string]$Message)
    Write-Host "  $Message" -ForegroundColor DarkGray
}

function Pause-Demo {
    param([string]$Message = "Press Enter to return to the menu...")
    Write-Host ""
    Read-Host "  $Message"
}

function Show-Menu {
    Show-Banner
    Write-Host "  📋 Select a demo action:" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] 🔧 Pre-flight Checks (semgrep, codeql, gh)" -ForegroundColor White
    Write-Host "  [2] 🔍 Full Repo Scan (JS + Rust)" -ForegroundColor White
    Write-Host "  [3] 🦀 Rust-Only Scan" -ForegroundColor White
    Write-Host "  [4] 📊 Inspect SARIF Output" -ForegroundColor White
    Write-Host "  [5] 🚀 Upload SARIF to GitHub" -ForegroundColor White
    Write-Host "  [6] 📋 List All Code Scanning Alerts" -ForegroundColor White
    Write-Host "  [7] 🔍 Filter Semgrep Alerts Only" -ForegroundColor White
    Write-Host "  [8] 🎯 Run All (Sequential Demo)" -ForegroundColor White
    Write-Host "  [0] 🚪 Exit" -ForegroundColor White
    Write-Host ""
}

# ============================================================================
# OPTION 1: PRE-FLIGHT CHECKS
# ============================================================================

function Invoke-PreflightChecks {
    Show-Section "Pre-flight Checks" "🔧"

    $allGood = $true

    # Semgrep
    Write-Host "  ─── 🐍 Semgrep CLI ───" -ForegroundColor DarkGray
    try {
        $semgrepVersion = semgrep --version 2>&1
        Show-Success "Semgrep version: $semgrepVersion"
    } catch {
        Show-Failure "Semgrep CLI not found. Install with: pip install semgrep"
        $allGood = $false
    }

    # CodeQL
    Write-Host ""
    Write-Host "  ─── 🛡️ CodeQL CLI ───" -ForegroundColor DarkGray
    try {
        $codeqlVersion = codeql version 2>&1 | Select-Object -First 1
        Show-Success "CodeQL version: $codeqlVersion"
    } catch {
        Show-Warning "CodeQL CLI not found. SARIF upload (option 5) will not work."
        $allGood = $false
    }

    # GitHub CLI
    Write-Host ""
    Write-Host "  ─── 📋 GitHub CLI ───" -ForegroundColor DarkGray
    try {
        $ghStatus = gh auth status 2>&1
        Show-Success "GitHub CLI authenticated"
        $ghStatus | ForEach-Object { Show-Info "  $_" }
    } catch {
        Show-Failure "GitHub CLI not authenticated. Run: gh auth login"
        $allGood = $false
    }

    # Repo directory
    Write-Host ""
    Write-Host "  ─── 📁 Repository ───" -ForegroundColor DarkGray
    if (Test-Path $repoDir) {
        Show-Success "Repo directory exists: $repoDir"
        $rustDir = Join-Path $repoDir "rust-telemetry-cli"
        if (Test-Path $rustDir) {
            Show-Success "Rust telemetry CLI directory found"
        } else {
            Show-Warning "Rust telemetry CLI directory not found at $rustDir"
        }
    } else {
        Show-Failure "Repo directory not found at $repoDir"
        $allGood = $false
    }

    # Check CodeQL default setup configuration
    Write-Host ""
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

    Write-Host ""
    if ($allGood) {
        Show-Success "All pre-flight checks passed!"
    } else {
        Show-Warning "Some checks failed. Review warnings above."
    }

    Show-ExamTip "Third-party scanners like Semgrep use upload-sarif, NOT codeql-action/analyze."

    Pause-Demo
}

# ============================================================================
# OPTION 2: FULL REPO SCAN (JS + RUST)
# ============================================================================

function Invoke-FullRepoScan {
    Show-Section "Full Repo Scan (JS + Rust)" "🔍"

    Show-Info "Scanning the entire repository with security-audit and Rust rule packs."
    Show-Info "This produces a SARIF file covering both JavaScript and Rust findings."

    Push-Location $repoDir

    $cmd = "semgrep scan --config p/security-audit --config p/rust --sarif --output results.sarif ."
    Show-Command $cmd

    try {
        semgrep scan `
            --config p/security-audit `
            --config p/rust `
            --sarif `
            --output results.sarif `
            .

        if (Test-Path results.sarif) {
            Show-Success "SARIF output written to results.sarif"
            Write-Host ""
            Get-Item results.sarif | Format-Table Name, @{N='Size (KB)';E={[math]::Round($_.Length/1KB,1)}}, LastWriteTime -AutoSize
        } else {
            Show-Failure "SARIF file was not created."
        }
    } catch {
        Show-Failure "Semgrep scan failed: $_"
    }

    Pop-Location

    Show-ExamTip "SARIF categories prevent result overwrites. Always set --sarif-category when using multiple scanners."

    Pause-Demo
}

# ============================================================================
# OPTION 3: RUST-ONLY SCAN
# ============================================================================

function Invoke-RustOnlyScan {
    Show-Section "Rust-Only Scan" "🦀"

    Show-Info "Scanning only the Rust telemetry CLI directory with Rust-specific rules."
    Show-Info "CodeQL does not support Rust — Semgrep fills the gap."

    Push-Location $repoDir

    $cmd = "semgrep scan --config p/rust --sarif --output rust-scan.sarif ./rust-telemetry-cli"
    Show-Command $cmd

    try {
        semgrep scan `
            --config p/rust `
            --sarif `
            --output rust-scan.sarif `
            ./rust-telemetry-cli

        if (Test-Path rust-scan.sarif) {
            Show-Success "SARIF output written to rust-scan.sarif"
            Write-Host ""
            Get-Item rust-scan.sarif | Format-Table Name, @{N='Size (KB)';E={[math]::Round($_.Length/1KB,1)}}, LastWriteTime -AutoSize
        } else {
            Show-Failure "SARIF file was not created."
        }
    } catch {
        Show-Failure "Semgrep scan failed: $_"
    }

    Pop-Location

    Show-ExamTip "CodeQL supports JS, Python, Java, C++, C#, Go, Ruby, Swift, Kotlin. Rust requires a third-party scanner."

    Pause-Demo
}

# ============================================================================
# OPTION 4: INSPECT SARIF OUTPUT
# ============================================================================

function Invoke-InspectSarif {
    Show-Section "Inspect SARIF Output" "📊"

    Push-Location $repoDir

    # Determine which SARIF files exist
    $sarifFiles = @()
    if (Test-Path "results.sarif")   { $sarifFiles += "results.sarif" }
    if (Test-Path "rust-scan.sarif") { $sarifFiles += "rust-scan.sarif" }

    if ($sarifFiles.Count -eq 0) {
        Show-Failure "No SARIF files found. Run a scan first (options 2 or 3)."
        Pop-Location
        Pause-Demo
        return
    }

    Write-Host "  📁 Available SARIF files:" -ForegroundColor White
    for ($i = 0; $i -lt $sarifFiles.Count; $i++) {
        Write-Host "    [$($i + 1)] $($sarifFiles[$i])" -ForegroundColor White
    }
    Write-Host ""

    $fileChoice = Read-Host "  Select a file number (default: 1)"
    if (-not $fileChoice) { $fileChoice = "1" }
    $selectedIndex = [int]$fileChoice - 1

    if ($selectedIndex -lt 0 -or $selectedIndex -ge $sarifFiles.Count) {
        Show-Warning "Invalid selection. Using first file."
        $selectedIndex = 0
    }

    $sarifPath = $sarifFiles[$selectedIndex]
    Show-Info "Parsing $sarifPath ..."

    try {
        $sarif = Get-Content $sarifPath -Raw | ConvertFrom-Json

        # Summary table
        Write-Host ""
        Write-Host "  ╔═══════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "  ║  📊 SARIF Summary                         ║" -ForegroundColor Cyan
        Write-Host "  ╚═══════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""

        Write-Host "  SARIF Version : $($sarif.'$schema' ?? $sarif.version)" -ForegroundColor White

        foreach ($run in $sarif.runs) {
            $toolName   = $run.tool.driver.name
            $toolVersion = $run.tool.driver.semanticVersion ?? $run.tool.driver.version ?? "N/A"
            $ruleCount  = ($run.tool.driver.rules | Measure-Object).Count
            $resultCount = ($run.results | Measure-Object).Count

            Write-Host ""
            Write-Host "  ─── Tool: $toolName ($toolVersion) ───" -ForegroundColor Green
            Write-Host "  Rules loaded : $ruleCount" -ForegroundColor White
            Write-Host "  Results found: $resultCount" -ForegroundColor White

            if ($resultCount -gt 0) {
                Write-Host ""
                Write-Host "  First results (up to 10):" -ForegroundColor Yellow

                $run.results | Select-Object -First 10 | ForEach-Object {
                    $ruleId  = $_.ruleId
                    $message = $_.message.text
                    $loc     = $_.locations[0].physicalLocation
                    $file    = $loc.artifactLocation.uri
                    $line    = $loc.region.startLine

                    if ($message.Length -gt 80) {
                        $message = $message.Substring(0, 77) + "..."
                    }

                    Write-Host "    🔹 [$ruleId] $file`:$line" -ForegroundColor White
                    Write-Host "       $message" -ForegroundColor DarkGray
                }

                if ($resultCount -gt 10) {
                    Write-Host ""
                    Show-Info "  ... and $($resultCount - 10) more results."
                }
            }
        }
    } catch {
        Show-Failure "Failed to parse SARIF: $_"
    }

    Pop-Location

    Show-ExamTip "SARIF 2.1.0 uses partialFingerprints to track alerts across commits, even through file renames."

    Pause-Demo
}

# ============================================================================
# OPTION 5: UPLOAD SARIF TO GITHUB
# ============================================================================

function Invoke-UploadSarif {
    Show-Section "Upload SARIF to GitHub" "🚀"

    Push-Location $repoDir

    # Check which SARIF files exist
    $sarifFiles = @()
    if (Test-Path "results.sarif")   { $sarifFiles += @{File="results.sarif";   Category="semgrep-local"} }
    if (Test-Path "rust-scan.sarif") { $sarifFiles += @{File="rust-scan.sarif"; Category="semgrep-rust-local"} }

    if ($sarifFiles.Count -eq 0) {
        Show-Failure "No SARIF files found. Run a scan first (options 2 or 3)."
        Pop-Location
        Pause-Demo
        return
    }

    Write-Host "  📁 Available SARIF files:" -ForegroundColor White
    for ($i = 0; $i -lt $sarifFiles.Count; $i++) {
        Write-Host "    [$($i + 1)] $($sarifFiles[$i].File) (category: $($sarifFiles[$i].Category))" -ForegroundColor White
    }
    Write-Host ""

    $fileChoice = Read-Host "  Select a file number (default: 1)"
    if (-not $fileChoice) { $fileChoice = "1" }
    $selectedIndex = [int]$fileChoice - 1

    if ($selectedIndex -lt 0 -or $selectedIndex -ge $sarifFiles.Count) {
        Show-Warning "Invalid selection. Using first file."
        $selectedIndex = 0
    }

    $selected     = $sarifFiles[$selectedIndex]
    $sarifFile    = $selected.File
    $sarifCategory = $selected.Category
    $commitSha    = git rev-parse HEAD

    Write-Host ""
    Write-Host "  Upload details:" -ForegroundColor White
    Write-Host "    Repository : $repo" -ForegroundColor DarkGray
    Write-Host "    Ref        : refs/heads/main" -ForegroundColor DarkGray
    Write-Host "    Commit     : $commitSha" -ForegroundColor DarkGray
    Write-Host "    SARIF file : $sarifFile" -ForegroundColor DarkGray
    Write-Host "    Category   : $sarifCategory" -ForegroundColor DarkGray
    Write-Host ""

    $cmd = "codeql github upload-results --repository=$repo --ref=refs/heads/main --commit=$commitSha --sarif=$sarifFile --sarif-category=$sarifCategory"
    Show-Command $cmd

    try {
        codeql github upload-results `
            --repository=$repo `
            --ref=refs/heads/main `
            --commit=$commitSha `
            --sarif=$sarifFile `
            --sarif-category=$sarifCategory

        Show-Success "SARIF uploaded successfully!"
        Write-Host ""
        Write-Host "  🔗 View results at:" -ForegroundColor Green
        Write-Host "  https://github.com/$repo/security/code-scanning" -ForegroundColor Cyan
    } catch {
        Show-Failure "Upload failed: $_"
        Show-Info "Ensure codeql CLI is installed and you have write access to the repository."
    }

    Pop-Location

    Show-ExamTip "SARIF categories prevent result overwrites. 'semgrep-local' and 'semgrep-rust-local' are separate categories."

    Pause-Demo
}

# ============================================================================
# OPTION 6: LIST ALL CODE SCANNING ALERTS
# ============================================================================

function Invoke-ListAlerts {
    Show-Section "List All Code Scanning Alerts" "📋"

    Show-Info "Fetching all open code scanning alerts from the GitHub API."

    # All alert rule IDs
    $cmd = "gh api repos/$repo/code-scanning/alerts --jq '.[].rule.id'"
    Show-Command $cmd

    Write-Host "  ─── All alert rule IDs ───" -ForegroundColor Yellow
    try {
        gh api "repos/$repo/code-scanning/alerts" `
            --jq '.[].rule.id'
    } catch {
        Show-Failure "Failed to fetch alerts: $_"
    }

    Write-Host ""
    Write-Host "  ─── Alerts with details ───" -ForegroundColor Yellow

    $cmd2 = "gh api repos/$repo/code-scanning/alerts --jq '.[] | {number, rule: .rule.id, tool: .tool.name, severity: .rule.severity}'"
    Show-Command $cmd2

    try {
        gh api "repos/$repo/code-scanning/alerts" `
            --jq '.[] | {number, rule: .rule.id, tool: .tool.name, severity: .rule.severity}'
    } catch {
        Show-Failure "Failed to fetch alert details: $_"
    }

    Show-ExamTip "The code scanning REST API lets you automate triage across repos at scale."

    Pause-Demo
}

# ============================================================================
# OPTION 7: FILTER SEMGREP ALERTS ONLY
# ============================================================================

function Invoke-FilterSemgrepAlerts {
    Show-Section "Filter Semgrep Alerts Only" "🔍"

    Show-Info "Filtering code scanning alerts to show only those from Semgrep."

    $cmd = "gh api repos/$repo/code-scanning/alerts --jq '.[] | select(.tool.name == ""Semgrep"") | {number, rule: .rule.id}'"
    Show-Command $cmd

    Write-Host "  ─── Semgrep alerts ───" -ForegroundColor Yellow
    try {
        gh api "repos/$repo/code-scanning/alerts" `
            --jq '.[] | select(.tool.name == "Semgrep") | {number, rule: .rule.id}'
    } catch {
        Show-Failure "Failed to fetch Semgrep alerts: $_"
    }

    Write-Host ""
    Write-Host "  ─── For comparison: CodeQL alerts ───" -ForegroundColor Yellow
    try {
        gh api "repos/$repo/code-scanning/alerts" `
            --jq '.[] | select(.tool.name == "CodeQL") | {number, rule: .rule.id}'
    } catch {
        Show-Failure "Failed to fetch CodeQL alerts: $_"
    }

    Show-ExamTip "Multiple scanners coexist in the Security tab. Use tool.name to distinguish results."

    Pause-Demo
}

# ============================================================================
# OPTION 8: RUN ALL (SEQUENTIAL DEMO)
# ============================================================================

function Invoke-RunAll {
    Show-Section "Sequential Demo — All Steps" "🎯"

    Show-Info "This runs all demo steps in sequence. Each step pauses for narration."
    Write-Host ""

    $confirm = Read-Host "  Proceed with full sequential demo? (y/N)"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Show-Info "Cancelled."
        Pause-Demo
        return
    }

    Invoke-PreflightChecks
    Invoke-FullRepoScan
    Invoke-RustOnlyScan
    Invoke-InspectSarif
    Invoke-UploadSarif
    Invoke-ListAlerts
    Invoke-FilterSemgrepAlerts

    Show-Section "Demo Complete" "✅"

    Write-Host @"
  Recap:
    🔍 Scanned JS + Rust with Semgrep (security-audit + Rust rules)
    🦀 Scanned Rust directory independently
    📊 Inspected SARIF 2.1.0 structure (tool, rules, results, locations)
    🚀 Uploaded SARIF to GitHub via CodeQL CLI
    📋 Listed all code scanning alerts via gh CLI
    🔍 Filtered alerts by scanner tool (Semgrep vs CodeQL)

  Key takeaways:
    - Third-party scanners produce SARIF and use upload-sarif (not codeql-action/analyze)
    - SARIF categories prevent result overwrites across scanners
    - The gh CLI and REST API enable programmatic alert management
    - CodeQL does not support Rust — Semgrep fills the gap
"@ -ForegroundColor Green

    Pause-Demo
}

# ============================================================================
# MAIN LOOP
# ============================================================================

Clear-Host

while ($true) {
    Show-Menu

    $choice = Read-Host "  Enter your choice"

    switch ($choice) {
        '1' { Invoke-PreflightChecks }
        '2' { Invoke-FullRepoScan }
        '3' { Invoke-RustOnlyScan }
        '4' { Invoke-InspectSarif }
        '5' { Invoke-UploadSarif }
        '6' { Invoke-ListAlerts }
        '7' { Invoke-FilterSemgrepAlerts }
        '8' { Invoke-RunAll }
        '0' {
            Write-Host ""
            Write-Host "  🚪 Exiting Semgrep Demo Console. Happy scanning!" -ForegroundColor Cyan
            Write-Host ""
            return
        }
        default {
            Show-Warning "Invalid selection. Enter a number 0-8."
            Start-Sleep -Seconds 1
        }
    }

    Clear-Host
}
