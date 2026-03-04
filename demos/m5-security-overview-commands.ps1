#Requires -Version 7.0
<#
.SYNOPSIS
    Globomantics Robot Fleet -- Security Overview Demo Console (Module 5)

.DESCRIPTION
    Interactive presenter console for the GH-500 / GHAS course covering:
      - Module 5: Security Overview dashboard, role-based alert visibility,
        licensing matrix, Coverage tab, CSV export, and SDLC integration

    Features a numbered menu so the presenter can jump to any section.

    HOW THIS CONSOLE WORKS FOR LEARNERS:
    -------------------------------------
    This script is a "live demo safety net." Each menu option runs real GitHub CLI
    commands against the org and repo, with talk tracks and exam tips displayed
    inline. If a live command fails during a presentation, the companion punchlist
    (m5-demo-punchlist.md) has the expected outputs and fallback guidance.

    KEY GHAS CONCEPTS DEMONSTRATED:
    --------------------------------
    1. Security Overview = org-level dashboard (NOT repo-level)
    2. Three tabs: Detection, Remediation, Prevention
    3. Coverage tab shows enablement gaps across repos
    4. Role-based visibility: devs see code scanning + Dependabot, NOT secret scanning
    5. Custom security roles delegate access without over-provisioning
    6. Since April 2025: GHAS unbundled into Secret Protection + Code Security
    7. Dependabot is always free, even on private repos
    8. CSV export and shareable filtered URLs for compliance

.NOTES
    Repository   : timothywarner-org/globomantics-robot-fleet
    Organization : timothywarner-org
    PowerShell   : 7.x required (PowerShell 5.1 will NOT work -- missing features)
    Prerequisites:
      - gh CLI authenticated with admin:org scope (gh auth status)
      - Org owner or security manager role in timothywarner-org
    Companion files:
      - foundations-update-m5/m5-demo-punchlist.md -- full demo timing and talk tracks
#>

# ===============================================================================
# CONFIGURATION
# -------------------------------------------------------------------------------
# Update these variables if targeting a different org or repo.
# The $ORG variable is used for org-level API endpoints.
# The $REPO variable is the specific repo for repo-level queries.
# ===============================================================================

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$ORG  = "timothywarner-org"
$REPO = "globomantics-robot-fleet"

# ===============================================================================
# HELPER FUNCTIONS
# -------------------------------------------------------------------------------
# These utility functions handle the console UI: banners, menus, color-coded
# output, talk track prompts, and exam tips. They keep the demo section
# functions focused on the actual GHAS commands rather than formatting.
# ===============================================================================

# Clears screen and displays the demo console header
function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  ======================================================================" -ForegroundColor Cyan
    Write-Host "  ||                                                                  ||" -ForegroundColor Cyan
    Write-Host "  ||   GHAS Security Overview Demo Console                            ||" -ForegroundColor Cyan
    Write-Host "  ||   Module 5: Security Overview and Role-based Alert Visibility    ||" -ForegroundColor Cyan
    Write-Host "  ||   Globomantics Robot Fleet Manager                               ||" -ForegroundColor Cyan
    Write-Host "  ||                                                                  ||" -ForegroundColor Cyan
    Write-Host "  ======================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Org  : $ORG" -ForegroundColor DarkGray
    Write-Host "  Repo : $ORG/$REPO" -ForegroundColor DarkGray
    Write-Host ""
}

# Displays the numbered menu. Each option maps to a Module 5 topic.
function Show-Menu {
    Write-Host "  Select a demo section:" -ForegroundColor White
    Write-Host ""
    Write-Host "  -- Security Overview Foundation -----------------------------------" -ForegroundColor DarkGray
    Write-Host "   [1]  Check Prerequisites" -ForegroundColor White
    Write-Host "   [2]  View Security Overview Summary (Org-level Alert Counts)" -ForegroundColor White
    Write-Host "   [3]  Query Code Scanning Alerts (Org-wide)" -ForegroundColor White
    Write-Host "   [4]  Query Secret Scanning Alerts (Org-wide)" -ForegroundColor White
    Write-Host "   [5]  Query Dependabot Alerts (Repo-level)" -ForegroundColor White
    Write-Host ""
    Write-Host "  -- Licensing and Visibility ---------------------------------------" -ForegroundColor DarkGray
    Write-Host "   [6]  Show Licensing Matrix (Free vs Licensed)" -ForegroundColor White
    Write-Host "   [7]  Show Role-based Visibility Matrix" -ForegroundColor White
    Write-Host ""
    Write-Host "  -- Coverage, Export, and Exam Prep --------------------------------" -ForegroundColor DarkGray
    Write-Host "   [8]  Check Repository Security Coverage" -ForegroundColor White
    Write-Host "   [9]  Export Alert Summary to CSV" -ForegroundColor White
    Write-Host "  [10]  Show GH-500 Exam Tips for Module 5" -ForegroundColor White
    Write-Host "  [11]  Open Security Overview in Browser" -ForegroundColor White
    Write-Host ""
    Write-Host "  -- Run All --------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  [12]  Run All Demos (Sequential)" -ForegroundColor White
    Write-Host ""
    Write-Host "   [0]  Exit" -ForegroundColor White
    Write-Host ""
}

# Renders a cyan box around a section title -- visual separator for the presenter
function Show-SectionHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host "  ======================================================================" -ForegroundColor Cyan
    Write-Host "    $Title" -ForegroundColor Cyan
    Write-Host "  ======================================================================" -ForegroundColor Cyan
    Write-Host ""
}

# Shows the exact command about to run -- helps learners follow along and
# copy commands for their own practice
function Show-Command {
    param([string]$Command)
    Write-Host "  > Running:" -ForegroundColor Yellow -NoNewline
    Write-Host " $Command" -ForegroundColor Yellow
    Write-Host "  ----------------------------------------------------------------------" -ForegroundColor DarkGray
}

# Displays presenter talk track text -- what the instructor should SAY while
# the command output is on screen. Greyed out so it doesn't distract from output.
function Show-TalkTrack {
    param([string]$Text)
    Write-Host ""
    Write-Host "  TALK TRACK:" -ForegroundColor DarkGray
    $Text -split "`n" | ForEach-Object {
        Write-Host "     $_" -ForegroundColor DarkGray
    }
    Write-Host ""
}

# Renders exam tips in a magenta box -- these are the specific facts learners
# should memorize for the GH-500 certification exam
function Show-ExamTip {
    param([string]$Text)
    Write-Host ""
    Write-Host "  +------------------------------------------------------------------+" -ForegroundColor Magenta
    Write-Host "  | [GH-500] EXAM TIP                                                |" -ForegroundColor Magenta
    $Text -split "`n" | ForEach-Object {
        $line = "  |   $($_.TrimStart())"
        Write-Host "$($line.PadRight(69))|" -ForegroundColor Magenta
    }
    Write-Host "  +------------------------------------------------------------------+" -ForegroundColor Magenta
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
    Write-Host "  [OK] $Message" -ForegroundColor Green
}

function Show-Failure {
    param([string]$Message)
    Write-Host "  [FAIL] $Message" -ForegroundColor Red
}

function Show-Warning {
    param([string]$Message)
    Write-Host "  [WARN] $Message" -ForegroundColor Yellow
}

# Pauses execution so the presenter can discuss what just happened on screen
function Pause-Demo {
    param([string]$Message = "Press Enter to return to the menu...")
    Write-Host ""
    Write-Host "  $Message" -ForegroundColor DarkGray
    Read-Host
}

# Safety gate for destructive or long-running actions.
# Returns $true only if the presenter explicitly types 'y'.
function Confirm-Action {
    param([string]$Message)
    Write-Host ""
    Write-Host "  [CONFIRM] $Message" -ForegroundColor Yellow
    $response = Read-Host "     Type 'y' to confirm (y/N)"
    return ($response -eq 'y' -or $response -eq 'Y')
}

# ===============================================================================
# SECTION FUNCTIONS
# -------------------------------------------------------------------------------
# Each function below corresponds to one menu option. They follow a consistent
# pattern: header -> talk track -> live commands -> exam tips -> pause.
#
# LEARNER NOTE: The gh CLI commands here use the REST API via `gh api`. Org-level
# endpoints use /orgs/{org}/... and repo-level endpoints use /repos/{owner}/{repo}/...
# Mastering the distinction is a GH-500 exam requirement.
# ===============================================================================

# -------------------------------------------------------------------------------
# SECTION 1: Check Prerequisites
# -------------------------------------------------------------------------------
# Validates gh CLI auth, org membership, and PowerShell version before demo begins.
# Nothing worse than discovering a missing auth scope mid-presentation.
#
# [GH-500] The admin:org scope is required for org-level Security Overview access.
# Without it, org-level API calls will return 404 (not 403) for security reasons.
# -------------------------------------------------------------------------------
function Invoke-CheckPrerequisites {
    Show-SectionHeader "Section 1: Check Prerequisites"

    Show-TalkTrack @"
Before we begin, let's verify our environment is ready. We need the gh CLI
authenticated with the admin:org scope, org owner status, and PowerShell 7.
"@

    # --- PowerShell version check ---
    # PowerShell 7+ is required for features like null-coalescing (??) and ternary operators
    Write-Host "  Checking PowerShell version..." -ForegroundColor White
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -ge 7) {
        Show-Success "PowerShell $psVersion detected"
    } else {
        Show-Failure "PowerShell $psVersion detected -- version 7+ is required"
        Show-Warning "Install PowerShell 7: https://aka.ms/powershell"
    }
    Write-Host ""

    # --- GitHub CLI authentication ---
    # gh auth status confirms the token is valid and shows scopes.
    # The admin:org scope is specifically required for org-level API calls.
    Write-Host "  Checking GitHub CLI authentication..." -ForegroundColor White
    Show-Command "gh auth status"
    try {
        $authOutput = gh auth status 2>&1
        # Filter out lines containing token details to avoid leaking credentials in recordings
        $authOutput | Where-Object { $_ -notmatch 'Token:|token:' } | ForEach-Object {
            Write-Host "     $_" -ForegroundColor White
        }
        Show-Success "GitHub CLI authenticated"
    } catch {
        Show-Failure "GitHub CLI not authenticated. Run: gh auth login"
        Show-Warning "For org-level access, ensure admin:org scope: gh auth refresh -s admin:org"
    }
    Write-Host ""

    # --- Org membership verification ---
    # Checks that the authenticated user is a member of the target org.
    # Org owners see all alerts; non-members see nothing.
    Write-Host "  Checking org membership in $ORG..." -ForegroundColor White
    Show-Command "gh api orgs/$ORG/memberships/{username}"
    try {
        $membershipJson = gh api "user/memberships/orgs/$ORG" 2>&1
        $membership = $membershipJson | ConvertFrom-Json
        $role = $membership.role
        $state = $membership.state
        Show-Success "Org membership confirmed -- role: $role, state: $state"

        if ($role -eq "admin") {
            Write-Host "     You are an org OWNER -- full Security Overview access" -ForegroundColor Green
        } else {
            Show-Warning "You are a MEMBER, not an owner. Some Security Overview data may be restricted."
        }
    } catch {
        Show-Failure "Could not verify org membership. You may need admin:org scope."
        Show-Warning "Run: gh auth refresh -s admin:org"
    }
    Write-Host ""

    # --- Repo accessibility check ---
    # Verifies the target repo exists and is accessible to the authenticated user
    Write-Host "  Checking repository access..." -ForegroundColor White
    Show-Command "gh api repos/$ORG/$REPO --jq '.full_name'"
    try {
        $repoName = gh api "repos/$ORG/$REPO" --jq '.full_name' 2>&1
        Show-Success "Repository accessible: $repoName"
    } catch {
        Show-Failure "Repository $ORG/$REPO not accessible. Check permissions."
    }

    # --- Configuration summary ---
    Write-Host ""
    Write-Host "  +------------------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  | Configuration                                                     |" -ForegroundColor Cyan
    Write-Host "  |   Org  : $($ORG.PadRight(56))|" -ForegroundColor Cyan
    Write-Host "  |   Repo : $("$ORG/$REPO".PadRight(56))|" -ForegroundColor Cyan
    Write-Host "  |   PS   : $("$psVersion".PadRight(56))|" -ForegroundColor Cyan
    Write-Host "  +------------------------------------------------------------------+" -ForegroundColor Cyan

    Show-ExamTip @"
Security Overview is an ORGANIZATION-level feature. It does NOT exist
at the repo level. You access it at: github.com/orgs/{org}/security.
The admin:org scope is required for full API access.
"@

    Pause-Demo
}

# -------------------------------------------------------------------------------
# SECTION 2: View Security Overview Summary
# -------------------------------------------------------------------------------
# Pulls org-level alert counts for all three security tools: code scanning,
# secret scanning, and Dependabot. This mirrors the Detection tab in the UI.
#
# [GH-500] The org-level API endpoints aggregate alerts across ALL repos in
# the org. This is the programmatic equivalent of the Security Overview dashboard.
# -------------------------------------------------------------------------------
function Invoke-SecurityOverviewSummary {
    Show-SectionHeader "Section 2: View Security Overview Summary"

    Show-TalkTrack @"
Security Overview gives org owners a single pane of glass across all repos.
The Detection tab shows what's been found. Let's query the same data via API.
We'll pull alert counts for code scanning, secret scanning, and Dependabot.
"@

    # --- Code scanning alert count ---
    # Org-level endpoint: /orgs/{org}/code-scanning/alerts
    # Returns alerts from ALL repos the authenticated user can access
    Write-Host "  Code Scanning Alerts (org-wide):" -ForegroundColor White
    Show-Command "gh api orgs/$ORG/code-scanning/alerts --jq 'length'"
    try {
        $codeAlertCount = gh api "orgs/$ORG/code-scanning/alerts" --jq 'length' 2>&1
        Show-Result "Total open alerts:" $codeAlertCount "Green"

        # Break down by severity using jq group_by
        Write-Host ""
        Write-Host "     Severity breakdown:" -ForegroundColor DarkGray
        $codeAlerts = gh api "orgs/$ORG/code-scanning/alerts" 2>&1 | ConvertFrom-Json
        $severities = $codeAlerts | Group-Object { $_.rule.severity }
        foreach ($group in $severities) {
            $color = switch ($group.Name) {
                "error"   { "Red" }
                "warning" { "Yellow" }
                "note"    { "White" }
                default   { "White" }
            }
            Show-Result "$($group.Name):" "$($group.Count)" $color
        }
    } catch {
        Show-Failure "Could not retrieve code scanning alerts. Check permissions and connectivity."
        Show-Warning "Ensure you have admin:org scope and org owner/security manager role."
    }
    Write-Host ""

    # --- Secret scanning alert count ---
    # Same pattern but for secret scanning. If the user lacks permissions,
    # the API returns 404 (not 403) to prevent information disclosure.
    Write-Host "  Secret Scanning Alerts (org-wide):" -ForegroundColor White
    Show-Command "gh api orgs/$ORG/secret-scanning/alerts --jq 'length'"
    try {
        $secretAlertCount = gh api "orgs/$ORG/secret-scanning/alerts" --jq 'length' 2>&1
        Show-Result "Total open alerts:" $secretAlertCount "Green"
    } catch {
        Show-Failure "Could not retrieve secret scanning alerts."
        Show-Warning "A 404 response means insufficient permissions (not that the endpoint doesn't exist)."
    }
    Write-Host ""

    # --- Dependabot alert count (repo-level) ---
    # Dependabot alerts are available at both org and repo level.
    # Org-level: /orgs/{org}/dependabot/alerts
    Write-Host "  Dependabot Alerts (org-wide):" -ForegroundColor White
    Show-Command "gh api orgs/$ORG/dependabot/alerts --jq 'length'"
    try {
        $depAlertCount = gh api "orgs/$ORG/dependabot/alerts" --jq 'length' 2>&1
        Show-Result "Total open alerts:" $depAlertCount "Green"
    } catch {
        Show-Failure "Could not retrieve Dependabot alerts. Check permissions and connectivity."
    }

    Show-ExamTip @"
Three tabs in Security Overview: Detection (what's found),
Remediation (how fast you fix), Prevention (what you block).
The API endpoints mirror these views programmatically.
"@

    Pause-Demo
}

# -------------------------------------------------------------------------------
# SECTION 3: Query Code Scanning Alerts (Org-wide)
# -------------------------------------------------------------------------------
# Queries the org-level code scanning alerts endpoint and displays the top
# alerts by severity. Uses jq to extract repo name, rule ID, and severity.
#
# [GH-500] Org-level endpoint: /orgs/{org}/code-scanning/alerts
# Repo-level endpoint: /repos/{owner}/{repo}/code-scanning/alerts
# Know the difference -- the exam tests this.
# -------------------------------------------------------------------------------
function Invoke-CodeScanningAlerts {
    Show-SectionHeader "Section 3: Query Code Scanning Alerts (Org-wide)"

    Show-TalkTrack @"
The org-level code scanning endpoint returns alerts from every repo you
have access to. As an org owner, that means everything. Let's see the
top alerts broken out by repository, rule, and severity.
"@

    # Fetch the first 10 org-level code scanning alerts with key metadata.
    # The jq expression extracts: repo name, rule ID, severity, and tool name.
    Show-Command "gh api orgs/$ORG/code-scanning/alerts --jq '.[0:10] | .[] | {repo, rule, severity, tool}'"
    Write-Host ""
    try {
        $alerts = gh api "orgs/$ORG/code-scanning/alerts" 2>&1 | ConvertFrom-Json

        if ($alerts.Count -eq 0) {
            Show-Warning "No code scanning alerts found. CodeQL may not be enabled on any repo."
        } else {
            Write-Host "  Top code scanning alerts (up to 10):" -ForegroundColor White
            Write-Host ""
            Write-Host "  +------+----------------------------------+----------------+----------+" -ForegroundColor DarkGray
            Write-Host "  | Repo | Rule                             | Tool           | Severity |" -ForegroundColor White
            Write-Host "  +------+----------------------------------+----------------+----------+" -ForegroundColor DarkGray

            $displayAlerts = $alerts | Select-Object -First 10
            foreach ($alert in $displayAlerts) {
                $repoName = ($alert.repository.name ?? "unknown").PadRight(4).Substring(0, 4)
                $ruleId   = ($alert.rule.id ?? "unknown").PadRight(32).Substring(0, 32)
                $tool     = ($alert.tool.name ?? "unknown").PadRight(14).Substring(0, 14)
                $severity = ($alert.rule.severity ?? "unknown").PadRight(8).Substring(0, 8)

                $color = switch ($alert.rule.severity) {
                    "error"   { "Red" }
                    "warning" { "Yellow" }
                    "note"    { "White" }
                    default   { "White" }
                }
                Write-Host "  | $repoName | $ruleId | $tool | $severity |" -ForegroundColor $color
            }

            Write-Host "  +------+----------------------------------+----------------+----------+" -ForegroundColor DarkGray
            Write-Host ""
            Show-Result "Total alerts shown:" "$($displayAlerts.Count) of $($alerts.Count)"
        }
    } catch {
        Show-Failure "Failed to query code scanning alerts. Check permissions and connectivity."
        Show-Warning "Verify: gh auth refresh -s admin:org"
    }

    Show-ExamTip @"
Org-level endpoint: /orgs/{org}/code-scanning/alerts
Repo-level endpoint: /repos/{owner}/{repo}/code-scanning/alerts
The org-level endpoint aggregates across ALL repos you can access.
"@

    Pause-Demo
}

# -------------------------------------------------------------------------------
# SECTION 4: Query Secret Scanning Alerts (Org-wide)
# -------------------------------------------------------------------------------
# Queries org-level secret scanning alerts. This is the endpoint that returns
# 404 (not 403) when the caller lacks sufficient permissions.
#
# [GH-500] HIGH-FREQUENCY EXAM TOPIC: The 404 response is deliberate. GitHub
# returns 404 instead of 403 to prevent confirming the endpoint even exists.
# This is an information disclosure prevention measure.
# -------------------------------------------------------------------------------
function Invoke-SecretScanningAlerts {
    Show-SectionHeader "Section 4: Query Secret Scanning Alerts (Org-wide)"

    Show-TalkTrack @"
Secret scanning alerts are the most restricted. Developers do NOT see these
by default -- only org owners, security managers, and repo admins. If a
regular developer hits this API, they get a 404. Not a 403 -- a 404.
GitHub deliberately hides the endpoint's existence from unauthorized users.
"@

    # Fetch org-level secret scanning alerts.
    # If the caller lacks permissions, the API returns 404 (not 403).
    Show-Command "gh api orgs/$ORG/secret-scanning/alerts --jq '.[0:10] | .[] | {repo, secret_type, state}'"
    Write-Host ""
    try {
        $alerts = gh api "orgs/$ORG/secret-scanning/alerts" 2>&1 | ConvertFrom-Json

        if ($alerts.Count -eq 0) {
            Show-Warning "No secret scanning alerts found."
        } else {
            Write-Host "  Secret scanning alerts (up to 10):" -ForegroundColor White
            Write-Host ""
            Write-Host "  +----+-------------------------------+---------------------+----------+" -ForegroundColor DarkGray
            Write-Host "  | #  | Secret Type                   | Repository          | State    |" -ForegroundColor White
            Write-Host "  +----+-------------------------------+---------------------+----------+" -ForegroundColor DarkGray

            $displayAlerts = $alerts | Select-Object -First 10
            foreach ($alert in $displayAlerts) {
                $num        = ("$($alert.number)").PadRight(2).Substring(0, 2)
                $secretType = ($alert.secret_type_display_name ?? $alert.secret_type ?? "unknown").PadRight(29).Substring(0, 29)
                $repoName   = ($alert.repository.name ?? "unknown").PadRight(19).Substring(0, 19)
                $state      = ($alert.state ?? "unknown").PadRight(8).Substring(0, 8)

                $color = switch ($alert.state) {
                    "open"     { "Red" }
                    "resolved" { "Green" }
                    default    { "Yellow" }
                }
                Write-Host "  | $num | $secretType | $repoName | $state |" -ForegroundColor $color
            }

            Write-Host "  +----+-------------------------------+---------------------+----------+" -ForegroundColor DarkGray
            Write-Host ""
            Show-Result "Total alerts shown:" "$($displayAlerts.Count) of $($alerts.Count)"
        }
    } catch {
        Show-Failure "Failed to query secret scanning alerts."
        Write-Host ""
        Write-Host "  If you received a 404, this is EXPECTED for non-admin users." -ForegroundColor Yellow
        Write-Host "  GitHub returns 404 (not 403) to prevent information disclosure." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  To fix: ensure you are an org owner or security manager." -ForegroundColor White
        Write-Host "  Run: gh auth refresh -s admin:org" -ForegroundColor White
    }

    Show-ExamTip @"
The org-level secret scanning API returns 404 (not 403) for
unauthorized users. This prevents confirming the endpoint exists.
This is an information disclosure prevention measure.
Why hide secrets from devs? The alert contains the actual secret value.
"@

    Pause-Demo
}

# -------------------------------------------------------------------------------
# SECTION 5: Query Dependabot Alerts (Repo-level)
# -------------------------------------------------------------------------------
# Queries Dependabot alerts for the specific repo. Dependabot is always free,
# even on private repos -- this is a key licensing distinction.
#
# [GH-500] Dependabot alerts are available to any user with read access to the
# repo. They are NOT gated behind GHAS licensing. This is the most permissive
# alert type in terms of visibility.
# -------------------------------------------------------------------------------
function Invoke-DependabotAlerts {
    Show-SectionHeader "Section 5: Query Dependabot Alerts (Repo-level)"

    Show-TalkTrack @"
Dependabot is the one tool that's always free -- even on private repos.
No GHAS license required. Let's look at the dependency vulnerabilities
in our specific repo, broken down by severity and ecosystem.
"@

    # Fetch repo-level Dependabot alerts. The repo-level endpoint is used here
    # because Dependabot alerts are most meaningful in the context of a specific
    # project's dependency tree.
    Show-Command "gh api repos/$ORG/$REPO/dependabot/alerts --jq '.[] | {package, severity, ecosystem}'"
    Write-Host ""
    try {
        $alerts = gh api "repos/$ORG/$REPO/dependabot/alerts" 2>&1 | ConvertFrom-Json

        if ($alerts.Count -eq 0) {
            Show-Warning "No Dependabot alerts found. Dependencies may be fully patched."
        } else {
            Write-Host "  Dependabot alerts for $ORG/${REPO}:" -ForegroundColor White
            Write-Host ""
            Write-Host "  +----+-------------------------------+--------------+----------+" -ForegroundColor DarkGray
            Write-Host "  | #  | Package                       | Ecosystem    | Severity |" -ForegroundColor White
            Write-Host "  +----+-------------------------------+--------------+----------+" -ForegroundColor DarkGray

            foreach ($alert in $alerts | Select-Object -First 15) {
                $num       = ("$($alert.number)").PadRight(2).Substring(0, 2)
                $package   = ($alert.dependency.package.name ?? "unknown").PadRight(29).Substring(0, 29)
                $ecosystem = ($alert.dependency.package.ecosystem ?? "unknown").PadRight(12).Substring(0, 12)
                $severity  = ($alert.security_advisory.severity ?? "unknown").PadRight(8).Substring(0, 8)

                $color = switch ($alert.security_advisory.severity) {
                    "critical" { "Red" }
                    "high"     { "Red" }
                    "medium"   { "Yellow" }
                    "low"      { "White" }
                    default    { "White" }
                }
                Write-Host "  | $num | $package | $ecosystem | $severity |" -ForegroundColor $color
            }

            Write-Host "  +----+-------------------------------+--------------+----------+" -ForegroundColor DarkGray

            # Severity summary
            Write-Host ""
            Write-Host "  Severity summary:" -ForegroundColor White
            $severityGroups = $alerts | Group-Object { $_.security_advisory.severity }
            foreach ($group in $severityGroups) {
                $color = switch ($group.Name) {
                    "critical" { "Red" }
                    "high"     { "Red" }
                    "medium"   { "Yellow" }
                    "low"      { "White" }
                    default    { "White" }
                }
                Show-Result "$($group.Name):" "$($group.Count)" $color
            }
            Write-Host ""
            Show-Result "Total:" "$($alerts.Count)" "Cyan"
        }
    } catch {
        Show-Failure "Failed to query Dependabot alerts. Check permissions and connectivity."
    }

    Show-ExamTip @"
Dependabot is ALWAYS free, even on private repos. No GHAS license needed.
Dependabot alerts are visible to anyone with read access to the repo.
This is the most accessible security feature in GitHub.
"@

    Pause-Demo
}

# -------------------------------------------------------------------------------
# SECTION 6: Show Licensing Matrix
# -------------------------------------------------------------------------------
# Displays the free vs. licensed feature matrix. Since April 2025, GHAS was
# unbundled into two separate products: Secret Protection and Code Security.
#
# [GH-500] This is a HIGH-FREQUENCY exam topic. Know which features require
# which product and the approximate per-committer pricing.
# -------------------------------------------------------------------------------
function Invoke-LicensingMatrix {
    Show-SectionHeader "Section 6: Licensing Matrix (Free vs Licensed)"

    Show-TalkTrack @"
Since April 2025, GitHub unbundled GHAS into two separate products. Before
that, GHAS was a single SKU. The exam references the current two-product
model. Let's break down what's free and what costs money.
"@

    Write-Host "  GHAS Licensing Matrix (as of April 2025 unbundling):" -ForegroundColor White
    Write-Host ""
    Write-Host "  +----------------------------+------------+-----------------------------+" -ForegroundColor DarkGray
    Write-Host "  | Feature                    | Product    | Cost                        |" -ForegroundColor White
    Write-Host "  +----------------------------+------------+-----------------------------+" -ForegroundColor DarkGray
    Write-Host "  | Dependabot alerts          | Free       | Always free (all repos)     |" -ForegroundColor Green
    Write-Host "  | Dependabot security updates| Free       | Always free (all repos)     |" -ForegroundColor Green
    Write-Host "  | Dependency graph           | Free       | Always free (all repos)     |" -ForegroundColor Green
    Write-Host "  | Dependency review          | Free       | Always free (all repos)     |" -ForegroundColor Green
    Write-Host "  +----------------------------+------------+-----------------------------+" -ForegroundColor DarkGray
    Write-Host "  | Secret scanning            | Secret     | ~`$19/committer/month       |" -ForegroundColor Yellow
    Write-Host "  | Push protection            | Protection | (private repos)             |" -ForegroundColor Yellow
    Write-Host "  | Custom patterns            |            |                             |" -ForegroundColor Yellow
    Write-Host "  +----------------------------+------------+-----------------------------+" -ForegroundColor DarkGray
    Write-Host "  | Code scanning (CodeQL)     | Code       | ~`$30/committer/month       |" -ForegroundColor Cyan
    Write-Host "  | Third-party SARIF upload   | Security   | (private repos)             |" -ForegroundColor Cyan
    Write-Host "  | Copilot Autofix            |            |                             |" -ForegroundColor Cyan
    Write-Host "  | Security Overview          |            |                             |" -ForegroundColor Cyan
    Write-Host "  +----------------------------+------------+-----------------------------+" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  IMPORTANT: All GHAS features are FREE on public repositories." -ForegroundColor Green
    Write-Host ""

    # SDLC integration timeline showing where each tool acts
    Write-Host "  SDLC Integration Points:" -ForegroundColor White
    Write-Host ""
    Write-Host "  Commit --> PR --------> Merge --> Ongoing" -ForegroundColor DarkGray
    Write-Host "    |         |             |          |" -ForegroundColor DarkGray
    Write-Host "    |         |             |          +-- Dependabot (always running)" -ForegroundColor Green
    Write-Host "    |         |             +------------- Coverage tab (org-level)" -ForegroundColor Cyan
    Write-Host "    |         +--------------------------- CodeQL scan (PR check)" -ForegroundColor Cyan
    Write-Host "    +------------------------------------- Push protection (commit)" -ForegroundColor Yellow
    Write-Host ""

    Show-ExamTip @"
Since April 2025, GHAS is TWO products:
  - Secret Protection: ~`$19/committer/month (secret scanning, push protection)
  - Code Security: ~`$30/committer/month (CodeQL, Autofix, Security Overview)
  - Dependabot: ALWAYS FREE on all repos including private
  - Public repos: ALL features free
The unbundling happened in April 2025. Know the current two-product model.
"@

    Pause-Demo
}

# -------------------------------------------------------------------------------
# SECTION 7: Show Role-based Visibility Matrix
# -------------------------------------------------------------------------------
# Displays who sees what alerts. This is a critical access control concept
# and a high-frequency GH-500 exam topic.
#
# KEY INSIGHT: Developers do NOT see secret scanning alerts because the alert
# itself contains the actual secret value. GitHub limits exposure by restricting
# who can see it. Custom security roles bridge the gap.
# -------------------------------------------------------------------------------
function Invoke-RoleVisibilityMatrix {
    Show-SectionHeader "Section 7: Role-based Alert Visibility"

    Show-TalkTrack @"
Not everyone sees the same alerts. GitHub uses role-based visibility to
control who sees what in Security Overview. The key restriction is that
developers cannot see secret scanning alerts by default. Why? Because
the alert contains the actual secret value. Exposing it to everyone
would defeat the purpose of secret scanning.
"@

    Write-Host "  Who Sees What:" -ForegroundColor White
    Write-Host ""
    Write-Host "  +-------------------------------+----------+----------+----------+-----------+" -ForegroundColor DarkGray
    Write-Host "  | Role                          | Code     | Depend-  | Secret   | Security  |" -ForegroundColor White
    Write-Host "  |                               | Scanning | abot     | Scanning | Overview  |" -ForegroundColor White
    Write-Host "  +-------------------------------+----------+----------+----------+-----------+" -ForegroundColor DarkGray
    Write-Host "  | Org owner / Security manager  |" -ForegroundColor White -NoNewline
    Write-Host " ALL     " -ForegroundColor Green -NoNewline
    Write-Host "|" -ForegroundColor DarkGray -NoNewline
    Write-Host " ALL     " -ForegroundColor Green -NoNewline
    Write-Host "|" -ForegroundColor DarkGray -NoNewline
    Write-Host " ALL     " -ForegroundColor Green -NoNewline
    Write-Host "|" -ForegroundColor DarkGray -NoNewline
    Write-Host " FULL      " -ForegroundColor Green -NoNewline
    Write-Host "|" -ForegroundColor DarkGray
    Write-Host "  | Repo admin                    |" -ForegroundColor White -NoNewline
    Write-Host " Theirs  " -ForegroundColor Yellow -NoNewline
    Write-Host "|" -ForegroundColor DarkGray -NoNewline
    Write-Host " Theirs  " -ForegroundColor Yellow -NoNewline
    Write-Host "|" -ForegroundColor DarkGray -NoNewline
    Write-Host " Theirs  " -ForegroundColor Yellow -NoNewline
    Write-Host "|" -ForegroundColor DarkGray -NoNewline
    Write-Host " Theirs    " -ForegroundColor Yellow -NoNewline
    Write-Host "|" -ForegroundColor DarkGray
    Write-Host "  | Developer (write access)      |" -ForegroundColor White -NoNewline
    Write-Host " Theirs  " -ForegroundColor Yellow -NoNewline
    Write-Host "|" -ForegroundColor DarkGray -NoNewline
    Write-Host " Theirs  " -ForegroundColor Yellow -NoNewline
    Write-Host "|" -ForegroundColor DarkGray -NoNewline
    Write-Host " NO      " -ForegroundColor Red -NoNewline
    Write-Host "|" -ForegroundColor DarkGray -NoNewline
    Write-Host " NO        " -ForegroundColor Red -NoNewline
    Write-Host "|" -ForegroundColor DarkGray
    Write-Host "  +-------------------------------+----------+----------+----------+-----------+" -ForegroundColor DarkGray
    Write-Host ""

    # Custom security roles explanation
    Write-Host "  Bridging the Gap: Custom Security Roles" -ForegroundColor White
    Write-Host "  ----------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Problem: A security champion needs to see secret scanning alerts" -ForegroundColor White
    Write-Host "           but should NOT be a repo admin (too much power)." -ForegroundColor White
    Write-Host ""
    Write-Host "  Solution: Create a CUSTOM SECURITY ROLE at the org level." -ForegroundColor Green
    Write-Host ""
    Write-Host "  Steps:" -ForegroundColor White
    Write-Host "    1. Navigate to: Organization settings > Roles" -ForegroundColor White
    Write-Host "    2. Create a new custom role" -ForegroundColor White
    Write-Host "    3. Add permission: 'View secret scanning alerts'" -ForegroundColor White
    Write-Host "    4. Assign the role to specific users or teams" -ForegroundColor White
    Write-Host ""
    Write-Host "  URL: github.com/organizations/$ORG/settings/roles" -ForegroundColor DarkGray
    Write-Host ""
    Show-Warning "Custom security roles require GitHub Enterprise Cloud."

    Show-ExamTip @"
Developers see code scanning + Dependabot but NOT secret scanning.
Reason: alert contains the actual secret value.
Custom security roles let you delegate access without making someone
a repo admin. This is a HIGH-FREQUENCY exam topic.
The secret scanning API returns 404 (not 403) for unauthorized users.
"@

    Pause-Demo
}

# -------------------------------------------------------------------------------
# SECTION 8: Check Repository Security Coverage
# -------------------------------------------------------------------------------
# Uses the REST API to check which security features are enabled on the repo.
# This is the programmatic equivalent of the Coverage tab in Security Overview.
#
# [GH-500] The Coverage tab shows enablement gaps across all repos. If a repo
# is missing code scanning or secret scanning, the Coverage tab highlights it.
# -------------------------------------------------------------------------------
function Invoke-SecurityCoverage {
    Show-SectionHeader "Section 8: Check Repository Security Coverage"

    Show-TalkTrack @"
The Coverage tab in Security Overview shows which repos have which features
enabled. A gap means risk. Let's check our repo's security feature status
programmatically using the API.
"@

    Write-Host "  Security feature status for $ORG/${REPO}:" -ForegroundColor White
    Write-Host ""

    # --- Code scanning default setup ---
    # Checks if CodeQL default setup is configured (zero-config option)
    Write-Host "  Code Scanning (CodeQL Default Setup):" -ForegroundColor White
    Show-Command "gh api repos/$ORG/$REPO/code-scanning/default-setup"
    try {
        $setupJson = gh api "repos/$ORG/$REPO/code-scanning/default-setup" 2>&1
        $setup = $setupJson | ConvertFrom-Json
        if ($setup.state -eq 'configured') {
            Show-Success "Code scanning enabled (default setup)"
            Show-Result "State      :" $setup.state "Green"
            Show-Result "Languages  :" ($setup.languages -join ', ') "White"
            Show-Result "Query Suite:" $setup.query_suite "White"
            Show-Result "Updated    :" $setup.updated_at "DarkGray"
        } else {
            Show-Warning "Code scanning default setup state: $($setup.state)"
        }
    } catch {
        Show-Warning "Code scanning default setup not configured (may use advanced setup)"
        # Check for custom workflow as fallback
        try {
            Write-Host "     Checking for advanced setup (custom workflow)..." -ForegroundColor DarkGray
            gh run list --repo "$ORG/$REPO" --workflow=codeql.yml --limit 3 2>&1 | ForEach-Object {
                Write-Host "     $_" -ForegroundColor White
            }
        } catch {
            Show-Failure "No CodeQL workflow detected"
        }
    }
    Write-Host ""

    # --- Secret scanning status ---
    # The repo-level API exposes security_and_analysis settings
    Write-Host "  Secret Scanning and Other Features:" -ForegroundColor White
    Show-Command "gh api repos/$ORG/$REPO --jq '.security_and_analysis'"
    try {
        $repoJson = gh api "repos/$ORG/$REPO" 2>&1 | ConvertFrom-Json
        $security = $repoJson.security_and_analysis

        # Secret scanning
        $ssStatus = $security.secret_scanning.status ?? "not available"
        if ($ssStatus -eq "enabled") {
            Show-Success "Secret scanning: $ssStatus"
        } else {
            Show-Warning "Secret scanning: $ssStatus"
        }

        # Push protection
        $ppStatus = $security.secret_scanning_push_protection.status ?? "not available"
        if ($ppStatus -eq "enabled") {
            Show-Success "Push protection: $ppStatus"
        } else {
            Show-Warning "Push protection: $ppStatus"
        }

        # Dependabot security updates
        $dsStatus = $security.dependabot_security_updates.status ?? "not available"
        if ($dsStatus -eq "enabled") {
            Show-Success "Dependabot security updates: $dsStatus"
        } else {
            Show-Warning "Dependabot security updates: $dsStatus"
        }
    } catch {
        Show-Failure "Could not retrieve security settings. Check permissions and connectivity."
    }
    Write-Host ""

    # --- Dependabot alerts status ---
    Write-Host "  Vulnerability Alerts (Dependabot):" -ForegroundColor White
    Show-Command "gh api repos/$ORG/$REPO/vulnerability-alerts"
    try {
        gh api "repos/$ORG/$REPO/vulnerability-alerts" 2>&1 | Out-Null
        Show-Success "Dependabot vulnerability alerts: enabled"
    } catch {
        Show-Warning "Dependabot vulnerability alerts: could not determine status"
    }

    # --- Coverage summary ---
    Write-Host ""
    Write-Host "  +------------------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  | Coverage Summary                                                  |" -ForegroundColor Cyan
    Write-Host "  | Use the Coverage tab in Security Overview to see enablement       |" -ForegroundColor Cyan
    Write-Host "  | gaps across ALL repos. Green = enabled. Gap = risk.               |" -ForegroundColor Cyan
    Write-Host "  | URL: github.com/orgs/$ORG/security/coverage           |" -ForegroundColor Cyan
    Write-Host "  +------------------------------------------------------------------+" -ForegroundColor Cyan

    Show-ExamTip @"
The Coverage tab answers: "Are we actually protected?"
It shows a grid of repos vs. features. A missing checkmark = risk.
This is your enablement audit tool at the org level.
"@

    Pause-Demo
}

# -------------------------------------------------------------------------------
# SECTION 9: Export Alert Summary to CSV
# -------------------------------------------------------------------------------
# Pulls alerts from all three tools and exports them to a local CSV file.
# This mirrors the CSV export button in the Security Overview UI.
#
# [GH-500] CSV export is an Enterprise Cloud feature in the UI, but you can
# always generate your own CSV from the API. Compliance teams love CSV files.
# -------------------------------------------------------------------------------
function Invoke-ExportCSV {
    Show-SectionHeader "Section 9: Export Alert Summary to CSV"

    Show-TalkTrack @"
Compliance teams need auditable records. The Security Overview UI has a
CSV export button (Enterprise Cloud), but we can also generate our own
from the API. Let's pull alerts and create a CSV file.
"@

    $csvPath = Join-Path ([System.IO.Path]::GetTempPath()) "ghas-alert-summary-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
    Write-Host "  Export path: $csvPath" -ForegroundColor White
    Write-Host ""

    $allAlerts = @()

    # --- Code scanning alerts ---
    Write-Host "  Fetching code scanning alerts..." -ForegroundColor White
    try {
        $codeAlerts = gh api "orgs/$ORG/code-scanning/alerts" 2>&1 | ConvertFrom-Json
        foreach ($alert in $codeAlerts) {
            $allAlerts += [PSCustomObject]@{
                AlertType  = "Code Scanning"
                Repository = $alert.repository.name
                AlertNumber = $alert.number
                Rule       = $alert.rule.id
                Severity   = $alert.rule.severity
                State      = $alert.state
                Tool       = $alert.tool.name
                CreatedAt  = $alert.created_at
                URL        = $alert.html_url
            }
        }
        Show-Success "Code scanning: $($codeAlerts.Count) alerts"
    } catch {
        Show-Warning "Could not fetch code scanning alerts"
    }

    # --- Secret scanning alerts ---
    Write-Host "  Fetching secret scanning alerts..." -ForegroundColor White
    try {
        $secretAlerts = gh api "orgs/$ORG/secret-scanning/alerts" 2>&1 | ConvertFrom-Json
        foreach ($alert in $secretAlerts) {
            $allAlerts += [PSCustomObject]@{
                AlertType  = "Secret Scanning"
                Repository = $alert.repository.name
                AlertNumber = $alert.number
                Rule       = $alert.secret_type_display_name ?? $alert.secret_type
                Severity   = "N/A"
                State      = $alert.state
                Tool       = "Secret Scanning"
                CreatedAt  = $alert.created_at
                URL        = $alert.html_url
            }
        }
        Show-Success "Secret scanning: $($secretAlerts.Count) alerts"
    } catch {
        Show-Warning "Could not fetch secret scanning alerts (may require higher permissions)"
    }

    # --- Dependabot alerts ---
    Write-Host "  Fetching Dependabot alerts..." -ForegroundColor White
    try {
        $depAlerts = gh api "repos/$ORG/$REPO/dependabot/alerts" 2>&1 | ConvertFrom-Json
        foreach ($alert in $depAlerts) {
            $allAlerts += [PSCustomObject]@{
                AlertType  = "Dependabot"
                Repository = $REPO
                AlertNumber = $alert.number
                Rule       = $alert.security_advisory.summary ?? $alert.dependency.package.name
                Severity   = $alert.security_advisory.severity
                State      = $alert.state
                Tool       = "Dependabot"
                CreatedAt  = $alert.created_at
                URL        = $alert.html_url
            }
        }
        Show-Success "Dependabot: $($depAlerts.Count) alerts"
    } catch {
        Show-Warning "Could not fetch Dependabot alerts"
    }

    # --- Export to CSV ---
    Write-Host ""
    if ($allAlerts.Count -gt 0) {
        try {
            $allAlerts | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
            Show-Success "Exported $($allAlerts.Count) alerts to CSV"
            Write-Host ""
            Show-Result "File:" $csvPath "Cyan"
            Show-Result "Size:" "$(( Get-Item $csvPath ).Length) bytes" "White"
            Write-Host ""

            # Show a preview of the first few rows
            Write-Host "  Preview (first 5 rows):" -ForegroundColor White
            Write-Host ""
            $allAlerts | Select-Object -First 5 | Format-Table AlertType, Repository, Rule, Severity, State -AutoSize | Out-String | ForEach-Object {
                $_.Trim() -split "`n" | ForEach-Object { Write-Host "     $_" -ForegroundColor White }
            }
        } catch {
            Show-Failure "Failed to write CSV file. Check that the temp directory is writable."
        }
    } else {
        Show-Warning "No alerts to export."
    }

    Show-ExamTip @"
CSV export in the Security Overview UI requires Enterprise Cloud.
But you can always generate CSV from the API (as shown here).
Shareable filtered URLs are another compliance feature: filter
the Security Overview, then copy the URL. Your colleague sees
the same filtered view -- no screenshots needed.
"@

    Pause-Demo
}

# -------------------------------------------------------------------------------
# SECTION 10: Show GH-500 Exam Tips
# -------------------------------------------------------------------------------
# Consolidated exam tips for Module 5. These are the specific facts learners
# should memorize for the GH-500 certification exam.
# -------------------------------------------------------------------------------
function Invoke-ExamTips {
    Show-SectionHeader "Section 10: GH-500 Exam Tips for Module 5"

    Show-TalkTrack @"
Let's consolidate the key exam facts for this module. These are the
specific details you're most likely to see on the GH-500 exam.
"@

    Write-Host "  +====================================================================+" -ForegroundColor Magenta
    Write-Host "  | [GH-500] MODULE 5 EXAM CHEAT SHEET                                |" -ForegroundColor Magenta
    Write-Host "  +====================================================================+" -ForegroundColor Magenta
    Write-Host ""

    $tips = @(
        @{ Topic = "Security Overview location"; Fact = "ORGANIZATION level, not repo level" },
        @{ Topic = "Three tabs"; Fact = "Detection (found), Remediation (fixed), Prevention (blocked)" },
        @{ Topic = "Coverage tab"; Fact = "Shows enablement gaps across all repos" },
        @{ Topic = "Dependabot pricing"; Fact = "ALWAYS free, all repos including private" },
        @{ Topic = "Secret Protection pricing"; Fact = "~`$19/committer/month for private repos" },
        @{ Topic = "Code Security pricing"; Fact = "~`$30/committer/month for private repos" },
        @{ Topic = "Public repo pricing"; Fact = "ALL GHAS features free on public repos" },
        @{ Topic = "GHAS unbundling"; Fact = "April 2025 -- split into Secret Protection + Code Security" },
        @{ Topic = "Developer visibility"; Fact = "Code scanning + Dependabot YES; secret scanning NO" },
        @{ Topic = "Why hide secrets"; Fact = "Alert contains the actual secret value" },
        @{ Topic = "Org owner visibility"; Fact = "Full access to all alert types across all repos" },
        @{ Topic = "Custom security roles"; Fact = "Delegate access without over-provisioning admin rights" },
        @{ Topic = "Secret API (unauthorized)"; Fact = "Returns 404 (NOT 403) -- information disclosure prevention" },
        @{ Topic = "Org-level API endpoints"; Fact = "/orgs/{org}/code-scanning/alerts, /orgs/{org}/secret-scanning/alerts" },
        @{ Topic = "CSV export"; Fact = "Enterprise Cloud feature for compliance reporting" },
        @{ Topic = "Shareable URLs"; Fact = "Filter params encode into URL query string" },
        @{ Topic = "Push protection"; Fact = "Blocks at COMMIT time (shift-left, part of Secret Protection)" },
        @{ Topic = "CodeQL scanning"; Fact = "Runs at PR time (part of Code Security)" },
        @{ Topic = "Dependabot scanning"; Fact = "Always running (continuous monitoring, always free)" },
        @{ Topic = "Prevention tab"; Fact = "Shows what you block BEFORE merge -- the shift-left metric" }
    )

    foreach ($tip in $tips) {
        Write-Host "  [GH-500] " -ForegroundColor Magenta -NoNewline
        Write-Host "$($tip.Topic): " -ForegroundColor White -NoNewline
        Write-Host $tip.Fact -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "  +====================================================================+" -ForegroundColor Magenta
    Write-Host ""

    # Key URLs for further study
    Write-Host "  Key URLs:" -ForegroundColor White
    Write-Host "    Security Overview Docs  : docs.github.com/en/enterprise-cloud@latest/code-security/security-overview/about-security-overview" -ForegroundColor DarkGray
    Write-Host "    Custom Roles Docs       : docs.github.com/en/enterprise-cloud@latest/organizations/managing-peoples-access-to-your-organization-with-roles" -ForegroundColor DarkGray
    Write-Host "    GHAS Pricing            : docs.github.com/en/billing/managing-billing-for-your-products/managing-billing-for-github-advanced-security" -ForegroundColor DarkGray
    Write-Host "    Security API Docs       : docs.github.com/en/rest/code-scanning/code-scanning" -ForegroundColor DarkGray
    Write-Host ""

    Pause-Demo
}

# -------------------------------------------------------------------------------
# SECTION 11: Open Security Overview in Browser
# -------------------------------------------------------------------------------
# Launches the browser directly to the org Security Overview page.
# This is useful for transitioning from CLI demos to UI-based demos.
# -------------------------------------------------------------------------------
function Invoke-OpenBrowser {
    Show-SectionHeader "Section 11: Open Security Overview in Browser"

    Show-TalkTrack @"
Let's switch to the browser and look at the Security Overview UI directly.
This is where org owners and security managers spend their time during
compliance reviews and security posture assessments.
"@

    $urls = @(
        @{ Label = "Security Overview (main)"; URL = "https://github.com/orgs/$ORG/security" },
        @{ Label = "Coverage tab"; URL = "https://github.com/orgs/$ORG/security/coverage" },
        @{ Label = "Org Roles settings"; URL = "https://github.com/organizations/$ORG/settings/roles" },
        @{ Label = "Repo Security tab"; URL = "https://github.com/$ORG/$REPO/security" }
    )

    Write-Host "  Available URLs:" -ForegroundColor White
    Write-Host ""
    for ($i = 0; $i -lt $urls.Count; $i++) {
        Write-Host "     [$($i + 1)] $($urls[$i].Label)" -ForegroundColor White
        Write-Host "         $($urls[$i].URL)" -ForegroundColor DarkGray
    }
    Write-Host ""

    $urlChoice = Read-Host "  Enter number to open (1-$($urls.Count)), or press Enter for Security Overview"

    $selectedUrl = if ($urlChoice -match '^\d+$' -and [int]$urlChoice -ge 1 -and [int]$urlChoice -le $urls.Count) {
        $urls[[int]$urlChoice - 1].URL
    } else {
        $urls[0].URL
    }

    Write-Host ""
    Write-Host "  Opening: $selectedUrl" -ForegroundColor Cyan

    # Validate URL scheme before launching to prevent Start-Process abuse
    if ($selectedUrl -notmatch '^https://') {
        Show-Failure "Refusing to open URL with unexpected scheme: $selectedUrl"
    } else {
        try {
            Start-Process $selectedUrl
            Show-Success "Browser opened"
        } catch {
            Show-Failure "Could not open browser. Navigate manually to:"
            Write-Host "     $selectedUrl" -ForegroundColor Yellow
        }
    }

    Show-ExamTip @"
Security Overview URL pattern: github.com/orgs/{org}/security
Coverage tab: github.com/orgs/{org}/security/coverage
Custom roles: github.com/organizations/{org}/settings/roles
"@

    Pause-Demo
}

# -------------------------------------------------------------------------------
# SECTION 12: Run All Demos (Sequential)
# -------------------------------------------------------------------------------
# Runs sections 1-9 in order with pauses between each. Useful for:
#   - Full dry-run before a live presentation
#   - Recording a complete walkthrough video
#   - Self-paced learner practice
# -------------------------------------------------------------------------------
function Invoke-RunAll {
    Show-SectionHeader "Section 12: Run All Demos (Sequential)"

    Write-Host "  This will run through sections 1-11 with pauses between each." -ForegroundColor White
    Write-Host ""

    if (Confirm-Action "Run all demo sections sequentially?") {
        Invoke-CheckPrerequisites
        Invoke-SecurityOverviewSummary
        Invoke-CodeScanningAlerts
        Invoke-SecretScanningAlerts
        Invoke-DependabotAlerts
        Invoke-LicensingMatrix
        Invoke-RoleVisibilityMatrix
        Invoke-SecurityCoverage
        Invoke-ExportCSV
        Invoke-ExamTips
        Invoke-OpenBrowser

        # Final recap
        Show-SectionHeader "Demo Complete -- Module 5 Recap"

        Write-Host "  Module 5 Key Takeaways:" -ForegroundColor Green
        Write-Host ""
        Write-Host "    - Security Overview is org-level: Detection, Remediation, Prevention" -ForegroundColor White
        Write-Host "    - Coverage tab shows enablement gaps across all repos" -ForegroundColor White
        Write-Host "    - Developers see code scanning + Dependabot, NOT secret scanning" -ForegroundColor White
        Write-Host "    - Custom security roles bridge the gap without over-provisioning" -ForegroundColor White
        Write-Host "    - GHAS unbundled April 2025: Secret Protection + Code Security" -ForegroundColor White
        Write-Host "    - Dependabot is always free, even on private repos" -ForegroundColor White
        Write-Host "    - CSV export and shareable URLs for compliance reporting" -ForegroundColor White
        Write-Host "    - Push protection at commit, CodeQL at PR, Dependabot always" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host "     Cancelled." -ForegroundColor DarkGray
    }

    Pause-Demo
}

# ===============================================================================
# MAIN LOOP
# -------------------------------------------------------------------------------
# Simple menu-driven loop. The presenter selects a number, the corresponding
# function runs, and control returns to the menu. Enter 0 to exit.
#
# TIP FOR LEARNERS: You can run this script yourself to practice. Make sure
# gh CLI is authenticated with admin:org scope and you have org owner access.
# ===============================================================================

$running = $true

while ($running) {
    Show-Banner
    Show-Menu

    $choice = (Read-Host "  Enter selection").Trim()

    switch ($choice) {
        "1"  { Invoke-CheckPrerequisites }
        "2"  { Invoke-SecurityOverviewSummary }
        "3"  { Invoke-CodeScanningAlerts }
        "4"  { Invoke-SecretScanningAlerts }
        "5"  { Invoke-DependabotAlerts }
        "6"  { Invoke-LicensingMatrix }
        "7"  { Invoke-RoleVisibilityMatrix }
        "8"  { Invoke-SecurityCoverage }
        "9"  { Invoke-ExportCSV }
        "10" { Invoke-ExamTips }
        "11" { Invoke-OpenBrowser }
        "12" { Invoke-RunAll }
        "0"  {
            Write-Host ""
            Write-Host "  Thanks for using the GHAS Security Overview Demo Console!" -ForegroundColor Cyan
            Write-Host "  Good luck on the GH-500 exam." -ForegroundColor Cyan
            Write-Host ""
            $running = $false
        }
        default {
            Show-Warning "Invalid selection. Please enter a number from 0-12."
            Start-Sleep -Seconds 1
        }
    }
}
