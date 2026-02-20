# Code Scanning Demo Punchlist (Modules 5 & 6)

**Repo:** `timothywarner-org/globomantics-robot-fleet`
**Total time:** ~30 min (two 15-min modules)
**Last updated:** 2026-02-20

---

## Pre-Flight Checklist

- [ ] **Verify** `gh auth status` shows authenticated
- [ ] **Verify** `semgrep --version` returns 1.x+
- [ ] **Verify** `codeql --version` returns 2.x+
- [ ] **Open** VS Code with repo loaded
- [ ] **Open** PowerShell 7 terminal (not Windows PS 5.1)
- [ ] **Open** browser to `github.com/timothywarner-org/globomantics-robot-fleet`
- [ ] **Confirm** CodeQL alerts exist in Security tab (at least 3)
- [ ] **Confirm** no existing Semgrep workflow (if doing live creation)
- [ ] **Open** `demos/codeql-demo.ipynb` in VS Code (backup reference)
- [ ] **Open** `demos/semgrep-demo.ipynb` in VS Code (backup reference)

---

---

## MODULE 5: Third-Party Scanners, SARIF, Copilot Autofix

---

### 1. Set the Stage (~2 min)

- [ ] **Show** the repo in browser -- click through `server.js` briefly
- [ ] **SAY THIS:** "This repo has 15+ intentional vulnerabilities -- eval injection, command injection, path traversal, hardcoded secrets. We built it to break."
- [ ] **Show** Security tab > Code scanning -- point out existing CodeQL alerts
- [ ] **SAY THIS:** "CodeQL found these. But CodeQL doesn't support Rust, and our compliance team wants a second scanner. Enter Semgrep."

> **GH-500:** Third-party scanners use `upload-sarif`, NOT `codeql-action/analyze`. Know the difference.

---

### 2. Show / Create Semgrep Workflow (~4 min)

- [ ] **Navigate** to Actions tab
- [ ] **Click** New workflow > set up a workflow yourself
- [ ] **Name** the file: `.github/workflows/semgrep-analysis.yml`
- [ ] **Paste** the workflow (or show existing file if already committed):

```yaml
name: "Semgrep Security Analysis"
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 14 * * 1'
jobs:
  semgrep:
    name: Semgrep SAST Scan
    runs-on: ubuntu-latest
    permissions:
      security-events: write
      actions: read
      contents: read
    container:
      image: semgrep/semgrep
    if: (github.actor != 'dependabot[bot]')
    steps:
      - uses: actions/checkout@v4
      - run: semgrep scan --config p/security-audit --config p/rust --sarif > semgrep.sarif
      - uses: github/codeql-action/upload-sarif@v4
        if: always()
        with:
          sarif_file: semgrep.sarif
          category: semgrep-security-audit
```

- [ ] **SAY THIS:** "Three things to remember. One: `security-events: write` -- miss it and you get a 403. Two: `upload-sarif` lives in the codeql-action repo -- same repo, different action. Three: the `category` prevents Semgrep from overwriting CodeQL results."
- [ ] **Commit** directly to main
- [ ] **Watch** Actions tab -- wait for green checkmark (~1-2 min)

> **GH-500:** `security-events: write` permission is required for SARIF upload. 403 without it.

---

### 3. View Combined Results in Security Tab (~2 min)

- [ ] **Navigate** to Security > Code scanning
- [ ] **Click** Tool filter dropdown
- [ ] **Filter** by CodeQL -- show JS alerts (eval injection, insecure helmet, clear-text cookie)
- [ ] **Filter** by Semgrep -- show Rust + JS findings (child process, JWT hardcode, redirect)
- [ ] **Clear** filter -- show unified view
- [ ] **SAY THIS:** "Same Security tab, two engines, one pane of glass. The team doesn't care which scanner found it -- they care that it's found."

---

### 4. Drill Into an Alert (~2 min)

- [ ] **Click** a high-severity alert (eval injection `js/code-injection` is best)
- [ ] **Show** the rule ID, severity, file location, and description
- [ ] **Click** Show paths (if path-problem alert)
- [ ] **SHOW THIS:** Source node (`:format` param) > intermediate nodes > sink node (`eval()`)
- [ ] **SAY THIS:** "Unbroken path from user input to eval. No sanitization anywhere. Confirmed true positive."

> **GH-500:** Show paths traces source to sink. Use it to validate true positives.

---

### 5. Upload SARIF via CLI (~3 min)

**Switch to VS Code terminal.**

- [ ] **Run** Semgrep locally on Rust directory:

```powershell
semgrep scan --config p/rust --sarif --output rust-scan.sarif ./rust-telemetry-cli
```

- [ ] **SAY THIS:** "CodeQL doesn't support Rust. Semgrep fills the gap. One command, SARIF output."
- [ ] **Upload** results to GitHub:

```powershell
codeql github upload-results `
    --repository=timothywarner-org/globomantics-robot-fleet `
    --ref=refs/heads/main `
    --commit=$(git rev-parse HEAD) `
    --sarif=rust-scan.sarif `
    --sarif-category=semgrep-rust-local
```

- [ ] **SAY THIS:** "`--sarif-category` is required when multiple scanners upload. Without it, results overwrite each other."
- [ ] **Inspect** SARIF structure (optional):

```powershell
$sarif = Get-Content rust-scan.sarif | ConvertFrom-Json
$sarif.runs | Select-Object @{N='Tool';E={$_.tool.driver.name}}, @{N='Rules';E={$_.tool.driver.rules.Count}}, @{N='Results';E={$_.results.Count}}
```

> **GH-500:** SARIF must be version 2.1.0. `partialFingerprints` track alerts across commits and file renames.

---

### 6. Copilot Autofix (~3 min)

- [ ] **Navigate** to Security > Code scanning
- [ ] **Filter** by Tool: CodeQL
- [ ] **Click** the eval injection alert (or any high-severity CodeQL alert)
- [ ] **Click** Generate fix button
- [ ] **Wait** 10-30 seconds
- [ ] **SHOW THIS:** The code diff, the plain-English explanation, and the "Create PR" button
- [ ] **SAY THIS:** "Autofix ships with GHAS -- no separate Copilot subscription. It only works on CodeQL alerts, not third-party results."
- [ ] **Click** Create PR with fix (creates a draft PR)
- [ ] **Show** the draft PR with branch and description

> **GH-500:** Autofix = included with GHAS. Copilot Chat = requires Copilot Enterprise (separate license).

---

### 7. Module 5 Wrap-Up (~30 sec)

- [ ] **SAY THIS:** "Recap: third-party scanners produce SARIF 2.1.0 and use upload-sarif. Categories prevent overwrites. CLI bridges non-GitHub CI systems. Autofix generates fixes for CodeQL alerts with no extra subscription."

---

---

## MODULE 6: Analysis Model, Triage, Troubleshooting

---

### 8. Query Suites & Build Modes (~3 min)

- [ ] **Navigate** to Settings > Advanced Security > Code scanning
- [ ] **Show** the default setup configuration
- [ ] **SAY THIS:** "Three query suites: default (fewer queries, low noise), security-extended (wider net), security-and-quality (adds code quality). This repo uses extended for max coverage."

| Suite | Scope |
|---|---|
| default | Core security, fewer queries |
| security-extended | Broader, more experimental |
| security-and-quality | Security + code quality |

- [ ] **SAY THIS:** "Three build modes: `none` for interpreted languages like JS, `autobuild` for auto-detect, `manual` for explicit build commands."

> **GH-500:** "Default setup" and "default suite" are DIFFERENT. Default setup = zero-config enablement. Default suite = a specific query set.

> **GH-500:** JavaScript uses `build-mode: none`. Java also supports `none`. C++ typically needs `manual`.

---

### 9. Show Paths Deep Dive (~2 min)

- [ ] **Navigate** to Security > Code scanning
- [ ] **Click** the eval injection alert (`js/code-injection`)
- [ ] **Click** Show paths
- [ ] **Click** each intermediate node to jump to code
- [ ] **SAY THIS:** "If there were sanitization at any step, the path would break. Unbroken path equals confirmed vulnerability. This is your evidence."

---

### 10. Copilot Chat (~2 min)

- [ ] **Stay** on the alert detail page
- [ ] **Click** Copilot Chat icon (top-right area)
- [ ] **Type:** `Explain how this alert introduces a vulnerability into the code.`
- [ ] **Show** the plain-English response
- [ ] **Type:** `What is the recommended fix for this vulnerability?`
- [ ] **Show** the code suggestion
- [ ] **SAY THIS:** "Show paths is the map. Copilot Chat is the tour guide."

> **GH-500:** Copilot Chat requires Copilot Enterprise license (separate from GHAS).

---

### 11. Filter Alerts by Severity & Tool (~1 min)

**In browser OR switch to terminal:**

- [ ] **Filter** by severity in Security tab -- show error (high), warning (medium), note (low)
- [ ] **Or run** via CLI:

```powershell
# High/critical alerts
gh api repos/timothywarner-org/globomantics-robot-fleet/code-scanning/alerts `
    --jq '.[] | select(.rule.severity == "error") | {number, rule: .rule.id}'

# Filter by tool
gh api repos/timothywarner-org/globomantics-robot-fleet/code-scanning/alerts `
    --jq '.[] | select(.tool.name == "CodeQL") | {number, rule: .rule.id}'
```

> **GH-500:** Severity `error` = high/critical. `warning` = medium. `note` = low.

---

### 12. Dismiss an Alert (~2 min)

- [ ] **Click** an alert (hardcoded session secret is a good candidate)
- [ ] **Click** Dismiss alert
- [ ] **Select** reason: "Used in tests"
- [ ] **Type** comment: `Educational demo repo with intentional vulnerabilities`
- [ ] **Click** Dismiss alert
- [ ] **SHOW THIS:** Alert moves to Closed, dismissal recorded with timestamp

**Or via CLI:**

```powershell
gh api repos/timothywarner-org/globomantics-robot-fleet/code-scanning/alerts/1 `
    --method PATCH `
    --field state=dismissed `
    --field dismissed_reason="used in tests" `
    --field dismissed_comment="Educational demo repo with intentional vulnerabilities"
```

- [ ] **SAY THIS:** "Three reasons: false positive, won't fix, used in tests. All create audit trails. Your comment should be defensible."

> **GH-500:** Dismissals require documentation. All three reasons create audit trails.

---

### 13. Re-open a Dismissed Alert (~1 min)

- [ ] **Navigate** to Code scanning > filter Closed/Dismissed alerts
- [ ] **Click** the alert you just dismissed
- [ ] **Click** Reopen alert

**Or via CLI:**

```powershell
gh api repos/timothywarner-org/globomantics-robot-fleet/code-scanning/alerts/1 `
    --method PATCH `
    --field state=open
```

- [ ] **SAY THIS:** "Dismissals aren't permanent. Circumstances change. Demo code becomes production code. Always re-open when the context shifts."

---

### 14. CodeQL CLI Local Analysis (~3 min)

**Switch to VS Code terminal.**

- [ ] **Create** CodeQL database:

```powershell
codeql database create codeql-db-javascript `
    --language=javascript `
    --source-root=. `
    --overwrite
```

- [ ] **SAY THIS:** "JavaScript uses direct extraction -- no build step needed. The database is a relational snapshot of the source."
- [ ] **Analyze** with security-extended suite:

```powershell
codeql database analyze codeql-db-javascript `
    --format=sarifv2.1.0 `
    --output=codeql-results.sarif `
    codeql/javascript-queries:codeql-suites/javascript-security-extended.qls
```

- [ ] **Run** a single query (optional, if time):

```powershell
codeql database analyze codeql-db-javascript `
    --format=sarifv2.1.0 `
    --output=codeql-single-query.sarif `
    codeql/javascript-queries:Security/CWE-094/CodeInjection.ql
```

- [ ] **Upload** results:

```powershell
codeql github upload-results `
    --repository=timothywarner-org/globomantics-robot-fleet `
    --ref=refs/heads/main `
    --commit=$(git rev-parse HEAD) `
    --sarif=codeql-results.sarif `
    --sarif-category=codeql-cli-local
```

> **GH-500:** `--format=sarifv2.1.0` is required for GitHub ingestion. The default CodeQL output format is NOT SARIF.

---

### 15. Troubleshooting Reference (~1 min)

- [ ] **Show** Actions tab -- point to recent workflow runs
- [ ] **SAY THIS:** "When CodeQL breaks, read the logs first. The answer is always in there."

| Error | Fix |
|---|---|
| Language detection failed | Specify `languages:` explicitly |
| Autobuild failed | Use `build-mode: manual` |
| Timeout exceeded | Increase `timeout-minutes`, split into matrix |
| Permission denied (403) | Add `security-events: write` |
| No results returned | Check extraction logs, try extended suite |

- [ ] **SAY THIS:** "90% of CodeQL failures: not explicit enough in configuration."

> **GH-500:** Default setup = interpreted languages. Advanced setup with `build-mode: manual` = compiled languages with complex builds.

---

### 16. Show Jupyter Notebooks (~1 min)

- [ ] **Open** `demos/codeql-demo.ipynb` in VS Code
- [ ] **Scroll** through -- show pre-captured outputs from all CodeQL CLI commands
- [ ] **Open** `demos/semgrep-demo.ipynb`
- [ ] **Scroll** through -- show Semgrep scan outputs and SARIF inspection
- [ ] **SAY THIS:** "These notebooks have every command with captured output. Great for review or if a live command fails."

---

### 17. Module 6 Wrap-Up (~30 sec)

- [ ] **SAY THIS:** "Recap: Query suites control what CodeQL looks for. Show paths validates true positives. Copilot Chat explains vulnerabilities in plain English. Dismissals require defensible documentation. Troubleshooting means being more explicit in configuration. Together with Module 5, you have the complete code scanning picture."

---

---

## Emergency Fallbacks

If a live command **fails**, switch to the pre-captured notebook:
- CodeQL commands: `demos/codeql-demo.ipynb`
- Semgrep commands: `demos/semgrep-demo.ipynb`

If the GitHub **workflow won't run**, show the existing workflow file:
- `.github/workflows/semgrep-analysis.yml`

If **Copilot Autofix** is unavailable, describe it verbally and show the alert detail page.

Interactive PS1 consoles (menu-driven, good for ad-hoc exploration):
- `demos/codeql-demo-commands.ps1`
- `demos/semgrep-demo-commands.ps1`

---

## GH-500 Exam Cheat Sheet

| Topic | Remember This |
|---|---|
| Third-party SARIF upload | `upload-sarif` action, NOT `codeql-action/analyze` |
| SARIF version | Must be **2.1.0** |
| Permissions | `security-events: write` required |
| Categories | REQUIRED for multiple scanners -- prevents overwrites |
| Default setup vs default suite | Different things -- setup is enablement, suite is query set |
| Build modes | `none` (interpreted), `autobuild` (auto-detect), `manual` (explicit) |
| Show paths | Source to sink -- validates true positives |
| Dismissal reasons | false positive, won't fix, used in tests |
| Copilot Autofix | Ships with GHAS, no extra license |
| Copilot Chat | Requires Copilot Enterprise (separate license) |
| Troubleshooting | Be explicit -- specify languages, build commands, timeouts |
| Alert severity | `error` = high/critical, `warning` = medium, `note` = low |
| Fingerprints | `partialFingerprints` track alerts across commits and renames |

---

## Key URLs

- **Repo:** `https://github.com/timothywarner-org/globomantics-robot-fleet`
- **Security tab:** `https://github.com/timothywarner-org/globomantics-robot-fleet/security/code-scanning`
- **Actions tab:** `https://github.com/timothywarner-org/globomantics-robot-fleet/actions`
- **Settings:** `https://github.com/timothywarner-org/globomantics-robot-fleet/settings/security_analysis`
