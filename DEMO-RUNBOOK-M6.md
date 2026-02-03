# Module 6 Demo Runbook: Dependabot Config, Rules and Dependency Review Action

> **10-13 Minute Demo Script** - Configure Dependabot and implement proactive PR-time security controls for the Globomantics GHAS Dashboard

---

## Prerequisites

**Before recording:**

- [ ] GitHub account with `timothywarner-org` organization access
- [ ] Repo exists: `timothywarner-org/globomantics-ghas-dashboard`
- [ ] Module 5 demo completed (dependency graph enabled, alerts visible)
- [ ] VS Code with extensions: GitHub Copilot, ESLint, SARIF Viewer
- [ ] PowerShell 7+ terminal in VS Code
- [ ] GitHub CLI (`gh`) authenticated
- [ ] Windows 11 with Edge browser

**Expected repository state:**

- [ ] `.github/dependabot.yml` exists with npm + github-actions ecosystems
- [ ] `.github/workflows/dependency-review.yml` exists with fail-on-severity: high
- [ ] `.github/workflows/codeql.yml` exists (JavaScript scanning)
- [ ] `.github/workflows/ci.yml` exists (basic CI)
- [ ] Dependabot alerts visible (lodash, axios, node-fetch, minimist, etc.)
- [ ] package.json contains intentionally vulnerable packages

**Vulnerable packages already in package.json:**

| Package | Version | Known Vulnerabilities |
|---------|---------|----------------------|
| lodash | 4.17.20 | Prototype Pollution (CVE-2021-23337) |
| axios | 0.21.1 | Server-Side Request Forgery |
| node-fetch | 2.6.1 | Exposure of Sensitive Information |
| minimist | 1.2.5 | Prototype Pollution |
| tar | 4.4.13 | Arbitrary File Overwrite |
| glob-parent | 5.1.1 | ReDoS |
| trim-newlines | 3.0.0 | ReDoS |
| path-parse | 1.0.6 | ReDoS |

---

## Demo Part 1: The dependabot.yml File (2.5 min)

### Step 1.1: Open the Repository and Navigate to Config

**What to click:**
1. Open **github.com/timothywarner-org/globomantics-ghas-dashboard**
2. Navigate to **Code** tab
3. Click into `.github` folder
4. Click `dependabot.yml`

**Talking points:**
> "This file is the control center for all Dependabot behavior at Globomantics. Without it, you get bare-minimum defaults. With it, you control exactly what gets updated, when updates arrive, and how they're organized."

---

### Step 1.2: Walk Through the Version and Updates Array

**What to show:**
```yaml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "daily"
      time: "09:00"
      timezone: "America/New_York"
```

**Talking points:**
> "Version 2 is the ONLY supported schema version. There's no version 1 anymore, there's no version 3 yet. If you see version: 2 on the exam, that's correct. Anything else is wrong."

> "Updates is an array. One entry per ecosystem, per directory. Our dashboard uses npm for the Node.js dependencies."

> **Exam tip:** The version key must be exactly 2. No other value is valid.

---

### Step 1.3: Explain Scheduling Options

**What to show:**
```yaml
schedule:
  interval: "daily"
  time: "09:00"
  timezone: "America/New_York"
```

**Talking points:**
> "Globomantics' platform engineering team configured this for 9 AM Eastern, daily. PRs arrive when developers are at their desks, not at 3 AM disrupting on-call rotations. You can set interval to daily, weekly, or monthly."

---

### Step 1.4: Show the GitHub Actions Ecosystem Entry

**What to show:**
```yaml
- package-ecosystem: "github-actions"
  directory: "/"
  schedule:
    interval: "weekly"
```

**Talking points:**
> "Here's one that catches people on the exam: github-actions is a valid package ecosystem. Dependabot scans your workflow files and updates action versions. If actions/checkout has a vulnerability, Dependabot creates a PR to fix it."

> **Exam tip:** The `github-actions` ecosystem is valid and important. Many candidates forget this exists.

---

### Step 1.5: Show PR Limit and Labels

**What to show:**
```yaml
open-pull-requests-limit: 10
labels:
  - "dependencies"
  - "security"
  - "automated"
commit-message:
  prefix: "deps"
  include: "scope"
```

**Talking points:**
> "open-pull-requests-limit prevents Dependabot from flooding your repo with PRs. Ten active PRs max. Labels help with filtering and automation. The commit-message prefix keeps your git history clean and scannable."

---

## Demo Part 2: Grouped Updates (2 min)

### Step 2.1: Explain the Problem with Ungrouped Updates

**Talking points:**
> "Without grouping, updating React in a large project means 15 separate PRs. react, react-dom, react-router, react-scripts, every related package gets its own PR. Developers start ignoring ALL Dependabot PRs because there's too much noise. Including the critical security ones."

---

### Step 2.2: Show the Groups Configuration

**What to show:**
```yaml
groups:
  production-minor-patch:
    dependency-type: "production"
    update-types:
      - "minor"
      - "patch"
  development-minor-patch:
    dependency-type: "development"
    update-types:
      - "minor"
      - "patch"
```

**Talking points:**
> "Groups combine related updates into single PRs. This config at Globomantics: all production minor and patch updates arrive as one PR. Dev dependencies get their own grouped PR. 47 individual PRs become 3 or 4 manageable ones."

---

### Step 2.3: Explain the Three Grouping Options

**Talking points:**
> "Three ways to define groups. First: patterns, like 'react*' to match all React packages. Second: update-types to group by patch, minor, or major. Third: dependency-type to separate production from development dependencies. Mix and match based on your team's workflow."

> **Exam tip:** Know all three grouping options: `patterns`, `update-types`, and `dependency-type`.

---

## Demo Part 3: Security Updates vs Version Updates (2 min)

### Step 3.1: Explain the Critical Difference

**Talking points:**
> "Two completely different Dependabot features. VERSION updates keep dependencies current. New Express version? Here's a PR. SECURITY updates specifically address CVEs. Vulnerable Express version? Here's a fix PR. Both are valuable, but they're controlled separately."

---

### Step 3.2: Navigate to Security Settings

**What to click:**
1. Click **Settings** tab
2. Scroll down and click **Code security and analysis** in left sidebar
3. Point to **Dependency graph** (should show Enabled)
4. Point to **Dependabot alerts** (should show Enabled)
5. Point to **Dependabot security updates**

**Talking points:**
> "Here's the gotcha that trips up EVERYONE. See these three toggles? Dependency graph: enabled. Dependabot alerts: enabled. We can SEE vulnerabilities. But look at Dependabot security updates..."

---

### Step 3.3: Highlight the Default State

**What to show:**
- Point specifically to the **Dependabot security updates** toggle
- Note whether it's enabled or disabled

**Talking points:**
> "Security updates, the ones that automatically create fix PRs, are DISABLED by default. Even when alerts are fully enabled. This is the most common exam question. If someone says 'Dependabot found vulnerabilities but isn't creating PRs,' first thing to check: is this toggle on?"

> **Exam tip:** Dependabot security updates are DISABLED by default. This is separate from alerts. Most frequently tested concept.

---

### Step 3.4: Enable Security Updates (if needed)

**What to click:**
1. If disabled, click **Enable** for Dependabot security updates

**Talking points:**
> "Now Globomantics gets automatic fix PRs for any vulnerability with a known remediation. Reactive security, addressing vulnerabilities after they're in your code."

---

## Demo Part 4: The Dependency Review Action (2.5 min)

### Step 4.1: Explain Proactive vs Reactive Security

**Talking points:**
> "Everything we've covered so far is REACTIVE. Dependabot alerts tell you AFTER vulnerable code reaches your repository. But the dependency review action is PROACTIVE. It blocks vulnerabilities BEFORE they merge into main. This is shift-left security in action."

---

### Step 4.2: Navigate to the Workflow File

**What to click:**
1. Navigate to **Code** tab
2. Click into `.github/workflows`
3. Click `dependency-review.yml`

**What to show:**
```yaml
name: Dependency Review
on:
  pull_request:
    branches: [main]

permissions:
  contents: read
  pull-requests: write
```

**Talking points:**
> "Triggers on every pull request to main. The action compares the PR branch against main and identifies ANY newly introduced dependencies. If those dependencies have vulnerabilities or license issues, the PR fails."

---

### Step 4.3: Walk Through the Action Configuration

**What to show:**
```yaml
- uses: actions/dependency-review-action@v4
  with:
    fail-on-severity: high
    deny-licenses: GPL-3.0, AGPL-3.0
    comment-summary-in-pr: always
    fail-on-scopes: runtime, development
```

**Talking points:**
> "Four key settings for Globomantics. fail-on-severity: high means any critical or high CVE blocks the merge. deny-licenses: GPL-3.0 and AGPL-3.0 are blocked because Globomantics ships commercial software. comment-summary-in-pr: always posts findings directly on the PR. fail-on-scopes: catches both runtime and dev dependencies."

---

### Step 4.4: Explain License Enforcement Rules

**Talking points:**
> "Two approaches to license control. Deny-list: block specific licenses, allow everything else. Allow-list: permit ONLY approved licenses, block everything else. But here's the rule: you can NOT use both in the same action. It's one or the other."

> **Exam tip:** You CANNOT combine `allow-licenses` AND `deny-licenses` in the same action. Mutually exclusive.

---

### Step 4.5: Show Permissions Required

**What to show:**
```yaml
permissions:
  contents: read
  pull-requests: write
```

**Talking points:**
> "These permissions are important. contents: read to access the dependency manifests. pull-requests: write so the action can post comments with its findings. Without write permission, you won't see those helpful PR comments."

---

## Demo Part 5: Live PR Blocking Demo (2.5 min)

### Step 5.1: Open VS Code and Create a Test Branch

**What to type in PowerShell terminal:**
```powershell
# Navigate to repo (adjust path as needed)
cd C:\repos\globomantics-ghas-dashboard

# Ensure we're on main and up to date
git checkout main
git pull origin main

# Create test branch
git checkout -b test-vulnerable-dep
```

**Talking points:**
> "Let's see this in action. I'm going to add an npm package with known vulnerabilities and watch the dependency review action block it in real time."

---

### Step 5.2: Add a Vulnerable npm Package

**What to click:**
1. Open `package.json` in VS Code
2. Locate the `"dependencies"` section

**What to add:**
```json
"serialize-javascript": "3.0.0",
```

**Talking points:**
> "serialize-javascript version 3.0.0 has CVE-2020-7660, a critical arbitrary code execution vulnerability. Perfect test case. A developer might add this without knowing the risk."

**Alternative vulnerable packages if needed:**
- `"marked": "0.3.5"` - ReDoS vulnerability (CVE-2017-1000427)
- `"handlebars": "4.0.0"` - Prototype Pollution (CVE-2019-19919)
- `"ini": "1.3.5"` - Prototype Pollution (CVE-2020-7788)

---

### Step 5.3: Commit and Push the Change

**What to type in PowerShell:**
```powershell
# Stage the change
git add package.json

# Commit with a realistic message
git commit -m "deps: add serialize-javascript for data serialization"

# Push and set upstream
git push -u origin test-vulnerable-dep
```

**Talking points:**
> "Normal developer workflow. They need serialization functionality, find a package, add it. They might not even realize version 3.0.0 is two years old with known CVEs."

---

### Step 5.4: Create a Pull Request via CLI

**What to type in PowerShell:**
```powershell
gh pr create --title "Add data serialization support" --body "Adding serialize-javascript package for robot telemetry data serialization in the Globomantics dashboard."
```

**Talking points:**
> "PR created. Now watch the Checks section. The dependency review action is going to analyze this PR and find the vulnerability."

---

### Step 5.5: Open the PR in Browser and Watch the Action

**What to click:**
1. Copy the PR URL from the CLI output
2. Open in Edge browser
3. Scroll to **Checks** section
4. Watch for dependency-review to start and complete

**Talking points:**
> "There's the yellow dot, it's running. The action is comparing our branch against main, identifying the new serialize-javascript dependency, and checking it against vulnerability databases..."

---

### Step 5.6: Show the Failed Check

**What to show:**
- Red X next to dependency-review check
- Click **Details** to see the full log

**Talking points:**
> "Red X. Blocked. The dependency review action found CVE-2020-7660 in serialize-javascript 3.0.0 and failed the check. This PR cannot merge until the vulnerability is resolved."

---

### Step 5.7: Show the PR Comment

**What to click:**
1. Scroll down to the PR conversation
2. Find the auto-generated comment from the dependency-review action

**What to show:**
- Vulnerability name and CVE
- Severity level
- Affected package and version
- Remediation guidance (upgrade to 4.0.0+)

**Talking points:**
> "The developer gets immediate, actionable feedback right on the PR. No hunting through logs. 'Your PR introduces 1 vulnerability with high severity. Package: serialize-javascript. Fix: upgrade to version 4.0.0 or later.' Shift-left security, stopping bad dependencies before they reach main."

---

### Step 5.8: Clean Up (Optional)

**What to type in PowerShell:**
```powershell
# Close the test PR without merging
gh pr close test-vulnerable-dep

# Switch back to main
git checkout main

# Delete the test branch locally
git branch -D test-vulnerable-dep

# Delete the remote branch
git push origin --delete test-vulnerable-dep
```

**Talking points:**
> "Cleaning up our test. In a real scenario, the developer would either upgrade to a safe version or choose a different package entirely."

---

## Wrap-Up (30 sec)

**Talking points:**
> "Module 6 recap for your exam prep: The dependabot.yml file uses version 2, the only supported version. The github-actions ecosystem is valid and often forgotten. Groups reduce PR noise using patterns, update-types, or dependency-type. Security updates are disabled by default, separate from alerts. The dependency review action is proactive, blocking at PR time. And you cannot combine allow-licenses with deny-licenses."

> "Globomantics' platform engineering team now has complete supply chain protection. Vulnerabilities can't sneak into main. This is exactly what the GitHub Advanced Security exam expects you to configure and understand."

---

## Quick Reference

### Key Files

| File | Purpose |
|------|---------|
| `.github/dependabot.yml` | Dependabot configuration |
| `.github/workflows/dependency-review.yml` | PR-time vulnerability blocking |
| `.github/workflows/codeql.yml` | Code scanning (JavaScript) |
| `package.json` | npm dependencies |
| `package-lock.json` | Locked dependency versions |

### Key Navigation Paths

- Dependabot config: **Code > .github > dependabot.yml**
- Dependency review workflow: **Code > .github > workflows > dependency-review.yml**
- Security settings: **Settings > Code security and analysis**
- Dependabot alerts: **Security > Dependabot alerts**
- Active PRs: **Pull requests** tab

### PowerShell Commands

```powershell
# Create test branch for vulnerable dependency demo
git checkout -b test-vulnerable-dep

# Stage, commit, and push
git add package.json
git commit -m "deps: add serialize-javascript for data serialization"
git push -u origin test-vulnerable-dep

# Create PR via GitHub CLI
gh pr create --title "Add data serialization support" --body "Adding serialize-javascript for telemetry"

# Watch workflow run status
gh run list --workflow=dependency-review.yml

# View specific run details
gh run view <run-id>

# Check PR status
gh pr status

# View PR checks
gh pr checks

# Close test PR without merging
gh pr close test-vulnerable-dep

# Clean up branches
git checkout main
git branch -D test-vulnerable-dep
git push origin --delete test-vulnerable-dep
```

### API Commands (for reference)

```powershell
# List Dependabot alerts via API
gh api repos/timothywarner-org/globomantics-ghas-dashboard/dependabot/alerts

# Get specific alert details
gh api repos/timothywarner-org/globomantics-ghas-dashboard/dependabot/alerts/1

# List dependency review runs
gh api repos/timothywarner-org/globomantics-ghas-dashboard/actions/workflows/dependency-review.yml/runs
```

---

## Exam Tips Mentioned

| Topic | Key Point | Exam Relevance |
|-------|-----------|----------------|
| dependabot.yml version | Must be exactly `2` | Frequently tested |
| github-actions ecosystem | Valid ecosystem for workflow actions | Often overlooked |
| Security updates default | DISABLED by default (separate toggle) | Most common question |
| Groups configuration | Three options: patterns, update-types, dependency-type | Configuration questions |
| License enforcement | Cannot combine allow-licenses AND deny-licenses | Trick question territory |
| Dependency review timing | PROACTIVE (PR-time) vs reactive (post-merge) | Conceptual understanding |
| Permissions required | contents: read, pull-requests: write | Workflow configuration |

---

## Troubleshooting

### Dependency Review Not Running?

| Symptom | Solution |
|---------|----------|
| Workflow doesn't trigger | Verify trigger is `pull_request`, not `push` |
| Action not found | Check workflow file is in `.github/workflows/` |
| Permissions error | Ensure `pull-requests: write` permission is set |
| No PR comment appears | Check `comment-summary-in-pr: always` is configured |
| Actions disabled | Settings > Actions > Ensure actions are enabled |

### Dependabot Security Updates Not Creating PRs?

| Symptom | Solution |
|---------|----------|
| Alerts visible but no PRs | Enable **Dependabot security updates** toggle in Settings |
| Toggle is on but still no PRs | Fix version must exist; not all CVEs have patches |
| PRs not appearing | Check if PRs already exist (won't duplicate) |
| PRs going to wrong branch | Check `target-branch` in dependabot.yml |

### Grouped Updates Not Working?

| Symptom | Solution |
|---------|----------|
| Updates not grouped | Verify `groups` key syntax in dependabot.yml |
| Too many PRs still | Check `open-pull-requests-limit` setting |
| Wrong packages grouped | Review `patterns` or `dependency-type` filters |

### Live Demo Failures?

| Symptom | Solution |
|---------|----------|
| Branch already exists | Delete with `git branch -D test-vulnerable-dep` |
| Push rejected | Ensure you have write access to the repo |
| PR creation fails | Check `gh auth status` for CLI authentication |
| Action runs but doesn't fail | Verify the package version actually has CVEs |

---

## Vulnerable npm Packages for Testing

Use these packages to trigger dependency review failures:

| Package | Version | CVE | Severity |
|---------|---------|-----|----------|
| serialize-javascript | 3.0.0 | CVE-2020-7660 | Critical |
| marked | 0.3.5 | CVE-2017-1000427 | High |
| handlebars | 4.0.0 | CVE-2019-19919 | Critical |
| ini | 1.3.5 | CVE-2020-7788 | High |
| highlight.js | 9.18.1 | CVE-2020-26237 | High |
| lodash | 4.17.15 | CVE-2020-8203 | High |
| elliptic | 6.5.2 | CVE-2020-28498 | High |
| ua-parser-js | 0.7.28 | CVE-2021-27292 | High |

---

**Demo Length:** 10-13 minutes
**Module:** 6 - Dependabot Config, Rules and Dependency Review Action
**Repository:** timothywarner-org/globomantics-ghas-dashboard
**Tech Stack:** Node.js + Express backend, React + Vite frontend
