#!/usr/bin/env pwsh
# ============================================================================
# Dependabot gh CLI Runbook - Globomantics Robot Fleet Manager
# Pluralsight GHAS Course | Module 6
# ============================================================================
# Prerequisites: gh cli authenticated (gh auth status), PowerShell 7+
# Usage: ./get-dependabot-dismissals.ps1
# ============================================================================

$ErrorActionPreference = 'Stop'

# --- Config -----------------------------------------------------------------
$owner = 'timothywarner-org'
$repo  = 'globomantics-robot-fleet'
$slug  = "$owner/$repo"

Write-Host "`n===== Dependabot CLI Runbook for $slug =====" -ForegroundColor Cyan

# --- 1. Verify gh CLI auth -------------------------------------------------
Write-Host "`n[1/7] Checking gh CLI authentication..." -ForegroundColor Yellow
gh auth status
if ($LASTEXITCODE -ne 0) {
    Write-Error "gh CLI not authenticated. Run 'gh auth login' first."
    return
}

# --- 2. List all open Dependabot alerts (security vulnerabilities) ----------
Write-Host "`n[2/7] Fetching open Dependabot alerts..." -ForegroundColor Yellow
$alerts = gh api "repos/$slug/dependabot/alerts?state=open&per_page=100" | ConvertFrom-Json

if ($alerts.Count -eq 0) {
    Write-Host "  No open Dependabot alerts found." -ForegroundColor Green
} else {
    Write-Host "  Found $($alerts.Count) open alert(s):" -ForegroundColor Red
    $alerts | ForEach-Object {
        $sev = $_.security_advisory.severity.ToUpper()
        $color = switch ($sev) {
            'CRITICAL' { 'Red' }
            'HIGH'     { 'DarkYellow' }
            'MEDIUM'   { 'Yellow' }
            default    { 'Gray' }
        }
        Write-Host "    #$($_.number) [$sev] $($_.security_advisory.summary) -- $($_.dependency.package.name)@$($_.dependency.manifest_path)" -ForegroundColor $color
    }
}

# --- 3. List dismissed alerts (audit trail) ---------------------------------
Write-Host "`n[3/7] Fetching dismissed Dependabot alerts..." -ForegroundColor Yellow
$dismissed = gh api "repos/$slug/dependabot/alerts?state=dismissed&per_page=100" | ConvertFrom-Json

if ($dismissed.Count -eq 0) {
    Write-Host "  No dismissed alerts." -ForegroundColor Green
} else {
    Write-Host "  Found $($dismissed.Count) dismissed alert(s):" -ForegroundColor Magenta
    $dismissed | ForEach-Object {
        Write-Host "    #$($_.number) [$($_.dismissed_reason)] $($_.security_advisory.summary) -- dismissed by $($_.dismissed_by.login) on $($_.dismissed_at)" -ForegroundColor Magenta
    }
}

# --- 4. List open Dependabot PRs (version + security updates) ---------------
Write-Host "`n[4/7] Fetching open Dependabot pull requests..." -ForegroundColor Yellow
$prs = gh pr list --repo $slug --author 'app/dependabot' --state open --json number,title,labels,createdAt | ConvertFrom-Json

if ($prs.Count -eq 0) {
    Write-Host "  No open Dependabot PRs." -ForegroundColor Green
} else {
    Write-Host "  Found $($prs.Count) open Dependabot PR(s):" -ForegroundColor Cyan
    $prs | ForEach-Object {
        $labelStr = ($_.labels | ForEach-Object { $_.name }) -join ', '
        Write-Host "    PR #$($_.number): $($_.title)  [$labelStr]" -ForegroundColor Cyan
    }
}

# --- 5. Enable Dependabot security updates (forces scan) --------------------
Write-Host "`n[5/7] Enabling Dependabot security updates (forces scan)..." -ForegroundColor Yellow
try {
    gh api -X PUT "repos/$slug/vulnerability-alerts" 2>$null
    Write-Host "  Dependabot alerts: ENABLED" -ForegroundColor Green
} catch {
    Write-Host "  Dependabot alerts already enabled or insufficient permissions." -ForegroundColor DarkYellow
}

try {
    gh api -X PUT "repos/$slug/automated-security-fixes" 2>$null
    Write-Host "  Dependabot security updates (auto-fix PRs): ENABLED" -ForegroundColor Green
} catch {
    Write-Host "  Security updates already enabled or insufficient permissions." -ForegroundColor DarkYellow
}

# --- 6. Trigger manual Dependabot re-check ---------------------------------
Write-Host "`n[6/7] Triggering manual Dependabot version update check..." -ForegroundColor Yellow
Write-Host "  Dispatching update events for npm and github-actions ecosystems..."

@('npm', 'github-actions') | ForEach-Object {
    $ecosystem = $_
    try {
        gh api -X POST "repos/$slug/dispatches" `
            -f event_type="dependabot-update-$ecosystem" 2>$null
        Write-Host "    Dispatched repository_dispatch for: $ecosystem" -ForegroundColor Green
    } catch {
        Write-Host "    Note: repository_dispatch sent for $ecosystem (Dependabot picks up on next scheduled run)" -ForegroundColor DarkYellow
    }
}

Write-Host "`n  TIP: To force an immediate re-scan, close and reopen a Dependabot PR," -ForegroundColor DarkYellow
Write-Host "  or use the Dependabot chat commands on any PR:" -ForegroundColor DarkYellow
Write-Host '    @dependabot rebase' -ForegroundColor White
Write-Host '    @dependabot recreate' -ForegroundColor White
Write-Host '    @dependabot merge' -ForegroundColor White

# --- 7. Show dependency review workflow runs --------------------------------
Write-Host "`n[7/7] Recent dependency-review workflow runs..." -ForegroundColor Yellow
gh run list --repo $slug --workflow=dependency-review.yml --limit 5

# --- Summary ----------------------------------------------------------------
Write-Host "`n===== Summary =====" -ForegroundColor Cyan
Write-Host "  Open alerts:        $($alerts.Count)" -ForegroundColor $(if ($alerts.Count -gt 0) { 'Red' } else { 'Green' })
Write-Host "  Dismissed alerts:   $($dismissed.Count)" -ForegroundColor Magenta
Write-Host "  Open Dependabot PRs: $($prs.Count)" -ForegroundColor Cyan
Write-Host "`n  Next steps:" -ForegroundColor Yellow
Write-Host "    1. Review open alerts:  gh api repos/$slug/dependabot/alerts?state=open | jq" -ForegroundColor White
Write-Host "    2. Merge safe PRs:      gh pr merge <number> --squash --repo $slug" -ForegroundColor White
Write-Host "    3. Monitor dep review:  gh run list --workflow=dependency-review.yml --repo $slug" -ForegroundColor White
Write-Host ""
