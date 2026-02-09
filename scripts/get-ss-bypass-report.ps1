<#
.SYNOPSIS
    Reports on secret scanning push protection bypass events.
.DESCRIPTION
    Uses gh api to retrieve secret scanning alerts where push protection
    was bypassed, helping security teams audit bypass decisions.
.PARAMETER Repo
    Repository in owner/repo format. Defaults to timothywarner-org/globomantics-robot-fleet.
.EXAMPLE
    .\get-ss-bypass-report.ps1
    .\get-ss-bypass-report.ps1 -Repo "myorg/myrepo"
#>
[CmdletBinding()]
param(
    [string]$Repo = "timothywarner-org/globomantics-robot-fleet"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --- Preflight checks -------------------------------------------------------
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: gh CLI is not installed. Install from https://cli.github.com" -ForegroundColor Red
    exit 1
}

$authStatus = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: gh CLI is not authenticated. Run 'gh auth login' first." -ForegroundColor Red
    exit 1
}

# --- Fetch secret scanning alerts -------------------------------------------
Write-Host "`nFetching secret scanning alerts for $Repo ...`n" -ForegroundColor Cyan

try {
    $raw = gh api "/repos/$Repo/secret-scanning/alerts" --paginate 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to fetch alerts. Verify the repo name and that secret scanning is enabled." -ForegroundColor Red
        Write-Host $raw -ForegroundColor Yellow
        exit 1
    }
    $alerts = $raw | ConvertFrom-Json
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

if (-not $alerts -or $alerts.Count -eq 0) {
    Write-Host "No secret scanning alerts found for $Repo." -ForegroundColor Green
    exit 0
}

# --- Filter for push protection bypasses ------------------------------------
$bypassed = @($alerts | Where-Object { $_.push_protection_bypassed -eq $true })

Write-Host ("=" * 70) -ForegroundColor DarkGray
Write-Host " SECRET SCANNING PUSH PROTECTION BYPASS REPORT" -ForegroundColor White
Write-Host " Repository: $Repo" -ForegroundColor White
Write-Host ("=" * 70) -ForegroundColor DarkGray

if ($bypassed.Count -eq 0) {
    Write-Host "`nNo push protection bypasses found. All clear!" -ForegroundColor Green
    Write-Host "Total alerts: $($alerts.Count)`n" -ForegroundColor Cyan
    exit 0
}

# --- Detail each bypass -----------------------------------------------------
Write-Host ""
foreach ($alert in $bypassed) {
    $bypassUser = if ($alert.push_protection_bypassed_by) { $alert.push_protection_bypassed_by.login } else { "unknown" }
    $bypassDate = if ($alert.push_protection_bypassed_at) { $alert.push_protection_bypassed_at } else { "N/A" }
    $reason     = if ($alert.resolution) { $alert.resolution } else { "none provided" }

    Write-Host "  Alert #$($alert.number)" -ForegroundColor Yellow
    Write-Host "    Secret type : $($alert.secret_type_display_name)"
    Write-Host "    State       : $($alert.state)"
    Write-Host "    Bypassed by : $bypassUser" -ForegroundColor Red
    Write-Host "    Bypassed at : $bypassDate"
    Write-Host "    Reason      : $reason"
    Write-Host ("    " + ("-" * 50)) -ForegroundColor DarkGray
}

# --- Summary -----------------------------------------------------------------
$typeBreakdown = $bypassed | Group-Object -Property secret_type_display_name | Sort-Object Count -Descending

Write-Host "`n  SUMMARY" -ForegroundColor White
Write-Host ("  " + ("-" * 40)) -ForegroundColor DarkGray
Write-Host "  Total alerts           : $($alerts.Count)" -ForegroundColor Cyan
Write-Host "  Push protection bypassed: $($bypassed.Count)" -ForegroundColor Red
Write-Host ""
Write-Host "  Bypasses by secret type:" -ForegroundColor Yellow
foreach ($group in $typeBreakdown) {
    Write-Host "    $($group.Name): $($group.Count)" -ForegroundColor Yellow
}
Write-Host ""
