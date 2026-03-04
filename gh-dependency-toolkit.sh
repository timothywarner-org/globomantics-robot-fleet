#!/bin/bash
# ========================================================================
# GitHub CLI Dependency Management Toolkit
# Real-world patterns for dependency review, alerts, and PR automation
#
# Author: Tim Warner (Microsoft MVP)
# Repo: globomantics-robot-fleet (Demo repo with 34+ vulnerabilities)
# Purpose: Pluralsight course demonstrations
# ========================================================================

# Color codes for output formatting (because we're not animals)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PINK='\033[0;35m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Repository context (change these for your own repos)
REPO_OWNER="warnertech"
REPO_NAME="globomantics-robot-fleet"

REPO_FULL="${REPO_OWNER}/${REPO_NAME}"

# Ensure we're authenticated (uses your GITHUB_TOKEN env var)
echo -e "${BLUE}🔐 Checking GitHub CLI authentication...${NC}"
if ! gh auth status > /dev/null 2>&1; then
    echo -e "${RED}❌ Not authenticated with GitHub CLI${NC}"
    echo -e "${YELLOW}💡 Run: gh auth login --with-token < token_file${NC}"
    exit 1
fi

echo -e "${GREEN}✅ GitHub CLI authenticated successfully${NC}"
echo -e "${CYAN}Repository: ${REPO_FULL}${NC}"
echo ""

# ========================================================================
# VULNERABILITY ALERTS MANAGEMENT
# Real-world pattern: Daily security hygiene for enterprise teams
# ========================================================================
function show_vulnerability_alerts() {
    echo -e "${PURPLE}🚨 VULNERABILITY ALERTS ANALYSIS${NC}"
    echo -e "${CYAN}=====================================${NC}"

    # Get all Dependabot alerts (this repo has 34+ vulnerabilities!)
    echo -e "${YELLOW}📊 Current vulnerability alerts:${NC}"
    gh api repos/${REPO_FULL}/dependabot/alerts \
        --jq '.[] | {number, state, severity: .security_advisory.severity, summary: .security_advisory.summary, package: .dependency.package.name}' \
        --template '{{range .}}Alert #{{.number}} [{{.severity | upper}}]: {{.package}} - {{.summary}}
{{end}}'

    echo ""

    # Count by severity (enterprise reporting pattern)
    echo -e "${YELLOW}📈 Vulnerability breakdown by severity:${NC}"
    gh api repos/${REPO_FULL}/dependabot/alerts \
        --jq 'group_by(.security_advisory.severity) | map({severity: .[0].security_advisory.severity, count: length}) | sort_by(.severity)' \
        --template '{{range .}}{{.severity | upper}}: {{.count}} vulnerabilities
{{end}}'

    echo ""

    # Show only CRITICAL and HIGH severity (executive summary pattern)
    echo -e "${RED}🔥 CRITICAL & HIGH SEVERITY ALERTS (Executive Dashboard):${NC}"
    gh api repos/${REPO_FULL}/dependabot/alerts \
        --jq '.[] | select(.security_advisory.severity == "critical" or .security_advisory.severity == "high") | {number, severity: .security_advisory.severity, package: .dependency.package.name, summary: .security_advisory.summary, html_url}' \
        --template '{{range .}}🚨 Alert #{{.number}} [{{.severity | upper}}]
   Package: {{.package}}
   Issue: {{.summary}}
   URL: {{.html_url}}

{{end}}'
}

# ========================================================================
# DEPENDABOT PR MANAGEMENT
# Real-world pattern: Automated dependency update workflows
# ========================================================================
function manage_dependabot_prs() {
    echo -e "${PURPLE}🤖 DEPENDABOT PR MANAGEMENT${NC}"
    echo -e "${CYAN}=============================${NC}"

    # List all open Dependabot PRs
    echo -e "${YELLOW}📋 Open Dependabot PRs:${NC}"
    gh pr list --author app/dependabot \
        --json number,title,headRefName,createdAt,mergeable \
        --template '{{range .}}PR #{{.number}}: {{.title}}
   Branch: {{.headRefName}}
   Created: {{.createdAt | timeago}}
   Mergeable: {{.mergeable}}

{{end}}'

    echo ""

    # Show PR review status (team workflow pattern)
    echo -e "${YELLOW}👀 PR Review Status:${NC}"
    gh pr list --author app/dependabot \
        --json number,title,reviewDecision,statusCheckRollup \
        --template '{{range .}}PR #{{.number}}: {{.title}}
   Review Status: {{.reviewDecision | default "PENDING"}}
   Checks: {{if .statusCheckRollup}}{{len .statusCheckRollup}} checks{{else}}No checks{{end}}

{{end}}'

    echo ""

    # Security-focused PR filtering (show only security updates)
    echo -e "${RED}🛡️  SECURITY UPDATE PRs (Priority Queue):${NC}"
    gh pr list --author app/dependabot \
        --json number,title,body,labels \
        --jq '.[] | select(.title | test("security|vulnerability|CVE"; "i") or (.labels // [] | map(.name) | any(test("security"; "i"))))' \
        --template '{{range .}}🔒 SECURITY PR #{{.number}}: {{.title}}

{{end}}'
}

# ========================================================================
# DEPENDENCY REVIEW FOR ACTIVE PRs
# Real-world pattern: Pre-merge security validation
# ========================================================================
function review_pr_dependencies() {
    echo -e "${PURPLE}🔍 DEPENDENCY REVIEW ANALYSIS${NC}"
    echo -e "${CYAN}===============================${NC}"

    # Get the specific PR we know exists (tim/branch-protect #10)
    local pr_number=${1:-}
    if [[ -z "$pr_number" ]]; then
        echo -n -e "${BLUE}Enter the PR number to analyze: ${NC}"
        read -r pr_number
    fi

    echo -e "${YELLOW}📋 Analyzing PR #${pr_number} dependency changes:${NC}"

    # Get PR details first
    gh pr view ${pr_number} --json title,author,headRefName,baseRefName

    echo ""

    # Try to get dependency review (this might not work if no package.json changes)
    echo -e "${YELLOW}🔍 Dependency changes in PR #${pr_number}:${NC}"
    gh api repos/${REPO_FULL}/dependency-graph/compare/main...tim/branch-protect 2>/dev/null || {
        echo -e "${CYAN}ℹ️  No dependency changes detected in this PR${NC}"
        echo -e "${CYAN}💡 To trigger dependency review, modify package.json${NC}"
    }

    echo ""

    # Show how to check for vulnerable dependencies in PR
    echo -e "${YELLOW}🚨 Security impact analysis:${NC}"
    echo -e "${BLUE}Command to check vulnerable deps in PR branch:${NC}"
    echo "gh api repos/${REPO_FULL}/dependabot/alerts --jq '.[] | select(.state == \"open\")'"
}

# ========================================================================
# BULK OPERATIONS & AUTOMATION
# Real-world pattern: Enterprise-scale dependency management
# ========================================================================
function bulk_operations() {
    echo -e "${PURPLE}⚡ BULK OPERATIONS & AUTOMATION${NC}"
    echo -e "${CYAN}================================${NC}"

    # Auto-merge safe Dependabot PRs (patch updates only)
    echo -e "${YELLOW}🔄 Safe auto-merge candidates (patch updates):${NC}"
    gh pr list --author app/dependabot \
        --json number,title,headRefName \
        --jq '.[] | select(.title | test("Bump.*from.*[0-9]+\\.[0-9]+\\.[0-9]+ to [0-9]+\\.[0-9]+\\.[0-9]+$"))' \
        --template '{{range .}}✅ Safe to auto-merge: PR #{{.number}} - {{.title}}
   Command: gh pr merge {{.number}} --auto --squash
{{end}}'

    echo ""

    # Batch dismiss low-severity alerts (with reason)
    echo -e "${YELLOW}📝 Batch operations for low-severity alerts:${NC}"
    echo -e "${BLUE}# Dismiss all 'low' severity alerts (use with caution!)${NC}"
    echo "gh api repos/${REPO_FULL}/dependabot/alerts \\"
    echo "  --jq '.[] | select(.security_advisory.severity == \"low\" and .state == \"open\") | .number' \\"
    echo "  | xargs -I {} gh api repos/${REPO_FULL}/dependabot/alerts/{} \\"
    echo "  --method PATCH --field state=dismissed --field dismissed_reason=tolerable_risk"

    echo ""

    # Weekly dependency report generation
    echo -e "${YELLOW}📊 Weekly dependency health report:${NC}"
    echo -e "${BLUE}# Generate CSV report for stakeholders${NC}"
    echo "gh api repos/${REPO_FULL}/dependabot/alerts \\"
    echo "  --jq -r '\"Alert,Severity,Package,Summary,State\" as \$header | \$header, (.[] | [.number, .security_advisory.severity, .dependency.package.name, .security_advisory.summary, .state] | @csv)' \\"
    echo "  > dependency-report-\$(date +%Y%m%d).csv"
}

# ========================================================================
# GITHUB ACTIONS INTEGRATION
# Real-world pattern: CI/CD dependency checks
# ========================================================================
function github_actions_integration() {
    echo -e "${PURPLE}🔄 GITHUB ACTIONS INTEGRATION${NC}"
    echo -e "${CYAN}==============================${NC}"

    # Check workflow runs related to dependency updates
    echo -e "${YELLOW}⚙️  Recent workflow runs (dependency-related):${NC}"
    gh run list --limit 5 --json conclusion,createdAt,event,name,number,status

    echo ""

    # Show how to trigger dependency review workflow
    echo -e "${YELLOW}🚀 Trigger custom dependency review workflow:${NC}"
    echo -e "${BLUE}# Example: Trigger dependency audit workflow${NC}"
    echo "gh workflow run dependency-audit.yml"

    echo ""

    # Check repository secrets (for automation)
    echo -e "${YELLOW}🔐 Repository secrets for automation:${NC}"
    echo -e "${BLUE}# List available secrets (names only, not values)${NC}"
    echo "gh secret list"
}

# ========================================================================
# ENTERPRISE REPORTING FUNCTIONS
# Real-world pattern: Executive dashboards and compliance
# ========================================================================
function generate_executive_report() {
    echo -e "${PURPLE}📋 EXECUTIVE SECURITY DASHBOARD${NC}"
    echo -e "${CYAN}================================${NC}"

    local report_date=$(date +"%Y-%m-%d %H:%M:%S")
    local report_file="security-dashboard-$(date +%Y%m%d-%H%M).md"

    cat << EOF > ${report_file}
# Security Dashboard Report
**Repository:** ${REPO_FULL}
**Generated:** ${report_date}
**Report Type:** Dependency Security Analysis

## 🚨 Critical Metrics
EOF

    # Add critical metrics to report
    gh api repos/${REPO_FULL}/dependabot/alerts \
        --jq 'group_by(.security_advisory.severity) | map({severity: .[0].security_advisory.severity, count: length}) | sort_by(.severity)' \
        --template '{{range .}}| {{.severity | upper}} | {{.count}} |
{{end}}' >> ${report_file}

    echo -e "${GREEN}✅ Executive report generated: ${report_file}${NC}"
    echo -e "${BLUE}📧 Ready to send to stakeholders via email or Slack${NC}"
}

# ========================================================================
# MAIN MENU SYSTEM
# Real-world pattern: Interactive tooling for practitioners
# ========================================================================
function show_menu() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║               GitHub Dependency Toolkit                     ║${NC}"
    echo -e "${CYAN}║           Real-world patterns for practitioners             ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Choose an operation:${NC}"
    echo -e "${GREEN}1)${NC} 🚨 Show vulnerability alerts analysis"
    echo -e "${GREEN}2)${NC} 🤖 Manage Dependabot PRs"
    echo -e "${GREEN}3)${NC} 🔍 Review PR dependencies (PR #10)"
    echo -e "${GREEN}4)${NC} ⚡ Bulk operations & automation"
    echo -e "${GREEN}5)${NC} 🔄 GitHub Actions integration"
    echo -e "${GREEN}6)${NC} 📋 Generate executive security report"
    echo -e "${GREEN}7)${NC} 🔍 Run ALL analyses (comprehensive audit)"
    echo -e "${GREEN}8)${NC} 🚪 Exit"
    echo ""
    echo -n -e "${BLUE}Enter your choice [1-8]: ${NC}"
}

# ========================================================================
# MAIN EXECUTION LOGIC
# ========================================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Interactive mode
    while true; do
        show_menu
        read -r choice
        echo ""

        case $choice in
            1)
                show_vulnerability_alerts
                ;;
            2)
                manage_dependabot_prs
                ;;
            3)
                review_pr_dependencies
                ;;
            4)
                bulk_operations
                ;;
            5)
                github_actions_integration
                ;;
            6)
                generate_executive_report
                ;;
            7)
                show_ghas_features
                ;;
            7)
                echo -e "${PURPLE}🔍 COMPREHENSIVE DEPENDENCY AUDIT${NC}"
                echo -e "${CYAN}==================================${NC}"
                show_vulnerability_alerts
                manage_dependabot_prs
                review_pr_dependencies
                bulk_operations
                generate_executive_report
                ;;
            8)
                echo -e "${GREEN}👋 Happy dependency hunting, Tim!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Invalid choice. Please try again.${NC}"
                ;;
        esac

        echo ""
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read -r
        clear
    done
fi

# ========================================================================
# BONUS: Direct function calls for automation
# Usage examples:
#   ./gh-dependency-toolkit.sh show_vulnerability_alerts
#   ./gh-dependency-toolkit.sh generate_executive_report
# ========================================================================
if [[ $# -eq 1 ]]; then
    case $1 in
        "show_vulnerability_alerts"|"manage_dependabot_prs"|"review_pr_dependencies"|"bulk_operations"|"github_actions_integration"|"generate_executive_report")
            $1
            ;;
        *)
            echo -e "${RED}❌ Unknown function: $1${NC}"
            echo -e "${YELLOW}💡 Available functions: show_vulnerability_alerts, manage_dependabot_prs, review_pr_dependencies, bulk_operations, github_actions_integration, generate_executive_report${NC}"
            exit 1
            ;;
    esac
fi
