#Requires -Version 7.0
<#
.SYNOPSIS
    Dependabot & Dependency Review runbook for gh CLI.
    Module 6: Dependabot Config, Rules and Dependency Review Action.

.DESCRIPTION
    On-demand commands to manage Dependabot version updates, security updates,
    dependency review, and related PR workflows using the GitHub CLI.

.NOTES
    Repository : timothywarner-org/globomantics-robot-fleet
    Prereqs    : gh auth login, PowerShell 7+
#>

$Owner = 'timothywarner-org'
$Repo  = 'globomantics-robot-fleet'
$Nwo   = "$Owner/$Repo"

# ─────────────────────────────────────────────
# 1. VERIFY PREREQUISITES
# ─────────────────────────────────────────────

Write-Host '=== 1. Checking prerequisites ===' -ForegroundColor Cyan
gh auth status
gh repo view $Nwo --json name,owner -q '"\(.owner.login)/\(.name)"'

# ─────────────────────────────────────────────
# 2. ENABLE DEPENDABOT FEATURES
#    (a) Vulnerability alerts  -> security updates depend on this
#    (b) Dependabot security updates
# ─────────────────────────────────────────────

Write-Host '=== 2. Enabling Dependabot features ===' -ForegroundColor Cyan

# Enable vulnerability alerts (required for security update PRs)
gh api -X PUT "repos/$Nwo/vulnerability-alerts" --silent
Write-Host '  Vulnerability alerts enabled.' -ForegroundColor Green

# Enable Dependabot security updates (auto-fix PRs for CVEs)
gh api -X PUT "repos/$Nwo/automated-security-fixes" --silent
Write-Host '  Dependabot security updates enabled.' -ForegroundColor Green

# ─────────────────────────────────────────────
# 3. TRIGGER DEPENDABOT ON-DEMAND
#    Pushing any change to dependabot.yml forces an immediate rescan.
#    This adds a timestamp comment so the push is non-destructive.
# ─────────────────────────────────────────────

Write-Host '=== 3. Triggering Dependabot rescan ===' -ForegroundColor Cyan

$ConfigPath = '.github/dependabot.yml'
$Timestamp  = Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz'

# Read current file, append/update the last-triggered comment
$Content = Get-Content $ConfigPath -Raw
$MarkerPattern = '(?m)^# Last triggered:.*$'
$MarkerLine    = "# Last triggered: $Timestamp"

if ($Content -match $MarkerPattern) {
    $Content = $Content -replace $MarkerPattern, $MarkerLine
}
else {
    $Content = $Content.TrimEnd() + "`n`n$MarkerLine`n"
}

Set-Content -Path $ConfigPath -Value $Content -NoNewline

git add $ConfigPath
git commit -m "deps: trigger Dependabot rescan $Timestamp"
git push

Write-Host "  Pushed dependabot.yml update. Dependabot will rescan shortly." -ForegroundColor Green

# ─────────────────────────────────────────────
# 4. LIST DEPENDABOT ALERTS (security vulnerabilities)
# ─────────────────────────────────────────────

Write-Host '=== 4. Current Dependabot alerts ===' -ForegroundColor Cyan
gh api "repos/$Nwo/dependabot/alerts" --jq '.[] | "\(.state) | \(.security_advisory.severity) | \(.dependency.package.name) | \(.security_advisory.summary)"' | Format-Table

# ─────────────────────────────────────────────
# 5. LIST OPEN DEPENDABOT PRS (version + security)
# ─────────────────────────────────────────────

Write-Host '=== 5. Open Dependabot PRs ===' -ForegroundColor Cyan
gh pr list --repo $Nwo --author 'app/dependabot' --state open --json number,title,labels --template '{{range .}}#{{.number}} {{.title}} {{range .labels}}[{{.name}}] {{end}}{{"\n"}}{{end}}'

# ─────────────────────────────────────────────
# 6. CHECK DEPENDENCY REVIEW WORKFLOW RUNS
# ─────────────────────────────────────────────

Write-Host '=== 6. Recent dependency-review workflow runs ===' -ForegroundColor Cyan
gh run list --repo $Nwo --workflow 'Dependency Review' --limit 5

# ─────────────────────────────────────────────
# 7. LIVE DEMO: TEST VULNERABLE DEPENDENCY
#    Creates a branch, adds a vulnerable package,
#    opens a PR, and lets the dependency review action block it.
# ─────────────────────────────────────────────

function Start-VulnerableDepDemo {
    Write-Host '=== 7. Live demo: vulnerable dependency PR ===' -ForegroundColor Cyan

    $Branch = 'test-vulnerable-dep'

    git checkout main
    git pull origin main
    git checkout -b $Branch

    # Add serialize-javascript 3.0.0 (CVE-2020-7660, Critical)
    $Pkg = Get-Content 'package.json' -Raw | ConvertFrom-Json
    $Pkg.dependencies | Add-Member -NotePropertyName 'serialize-javascript' -NotePropertyValue '3.0.0' -Force
    $Pkg | ConvertTo-Json -Depth 10 | Set-Content 'package.json'

    git add package.json
    git commit -m 'deps: add serialize-javascript for data serialization'
    git push -u origin $Branch

    gh pr create --title 'Add data serialization support' --body 'Adding serialize-javascript for robot telemetry data serialization.'

    Write-Host '  PR created. Watch the Checks tab for the dependency review result.' -ForegroundColor Yellow
    gh pr checks
}

# ─────────────────────────────────────────────
# 8. CLEAN UP DEMO BRANCH
# ─────────────────────────────────────────────

function Remove-VulnerableDepDemo {
    Write-Host '=== 8. Cleaning up demo ===' -ForegroundColor Cyan

    $Branch = 'test-vulnerable-dep'
    gh pr close $Branch --delete-branch
    git checkout main
    git branch -D $Branch 2>$null

    Write-Host '  Demo branch and PR cleaned up.' -ForegroundColor Green
}

# ─────────────────────────────────────────────
# MENU
# ─────────────────────────────────────────────

Write-Host ''
Write-Host 'Interactive commands available:' -ForegroundColor Magenta
Write-Host '  Start-VulnerableDepDemo   - Run the live demo (Section 7)'
Write-Host '  Remove-VulnerableDepDemo  - Clean up demo artifacts (Section 8)'
Write-Host ''
Write-Host 'Sections 1-6 ran automatically above.' -ForegroundColor DarkGray
