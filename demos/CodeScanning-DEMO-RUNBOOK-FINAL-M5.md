# Module 5 Demo Runbook: Third-Party Scanners, SARIF Integration, and Copilot Autofix

> **15-Minute Demo Script** — Integrate Semgrep as a third-party scanner targeting the Rust telemetry CLI, upload SARIF results to unified Security tab, and use Copilot Autofix to remediate CodeQL alerts in the Globomantics Robot Fleet Manager

## Prerequisites

**Before recording:**

- [ ] GitHub account with `timothywarner-org` organization access
- [ ] Repo exists: `timothywarner-org/globomantics-robot-fleet`
- [ ] GHAS license active on the repository
- [ ] CodeQL default setup already enabled (JavaScript) with alerts present
- [ ] GitHub CLI (`gh`) authenticated — verify with `gh auth status`
- [ ] Semgrep CLI installed — `pip install semgrep` (or `pipx install semgrep`)
- [ ] VS Code open with extensions: GitHub Copilot, CodeQL, GitHub Actions
- [ ] PowerShell 7 terminal in VS Code (not Windows PowerShell 5.1)
- [ ] Set `$env:PYTHONUTF8 = "1"` in terminal (prevents Semgrep Unicode errors on Windows)
- [ ] Repo cloned locally to `C:\repos\globomantics-robot-fleet`

**Expected repo state:**

- CodeQL alerts present from `server.js` vulnerabilities (eval injection, unsafe lodash merge)
- `rust-telemetry-cli/` directory contains Rust source (serde + serde_json deps)
- No existing Semgrep workflow (you create it on camera)
- At least one CodeQL alert with Copilot Autofix support (JS alerts typically qualify)

**Known vulnerable code patterns in server.js:**

| Pattern | Location | CWE |
|---------|----------|-----|
| `eval()` with user input | `/api/export/:format` | CWE-94 Code Injection |
| `_.merge(robot, req.body)` | `/robot/:id/update` | CWE-915 Mass Assignment |
| Hardcoded session secret | Session config | CWE-798 Hard-coded Credentials |
| CSP disabled | Helmet config | CWE-693 Protection Mechanism Failure |

---

## Demo Part 1: Why Third-Party Scanners? (2 min)

### Talk Track (No clicks — set the stage)

> "CodeQL is the engine that ships with GitHub Advanced Security. It's excellent for JavaScript, Python, Java, C++, and a handful of other languages. But here's the thing — Globomantics doesn't just run Node.js. They have a Rust telemetry CLI in this same repo for decoding robot fleet data. CodeQL doesn't support Rust. Their compliance team also wants coverage from multiple scanning engines. The answer? Third-party scanners that output SARIF — Static Analysis Results Interchange Format. All results land in the same Security tab, regardless of which tool found them."

> "We're going to add Semgrep as a second scanner. Semgrep is fast, pattern-based, supports 30+ languages including Rust, and outputs SARIF 2.1.0 natively. One repo, two scanners, unified results."

> **GH-500 EXAM TIP:** Third-party scanners use the `upload-sarif` action, NOT `codeql-action/analyze`. Know the difference.

---

## Demo Part 2: Create Semgrep Workflow (4 min)

### Step 2.1: Navigate to Actions

**What to click:**
1. Open **github.com/timothywarner-org/globomantics-robot-fleet**
2. Click **Actions** tab
3. Click **New workflow**
4. Click **set up a workflow yourself**

**Talk track:**
> "We already have CodeQL running via default setup. Now we're adding Semgrep alongside it. Same repo, two analysis engines, one Security tab."

---

### Step 2.2: Create the Workflow File

**What to type:**
- Name the file: `.github/workflows/semgrep-analysis.yml`
- Paste this workflow:

```yaml
# Third-party scanner: Semgrep (covers Rust, JS, and 30+ languages)
# GH-500 EXAM TIP: Third-party tools use upload-sarif, NOT codeql-action/analyze
name: "Semgrep Security Analysis"

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 14 * * 1'  # Weekly Monday 9 AM Central

jobs:
  semgrep:
    name: Semgrep SAST Scan
    runs-on: ubuntu-latest

    permissions:
      # CRITICAL: Required for SARIF upload — miss this and you get a 403
      security-events: write
      actions: read
      contents: read

    container:
      # Official Semgrep Docker image — matches semgrep.dev docs
      image: semgrep/semgrep

    # Skip Dependabot PRs to avoid permission issues
    if: (github.actor != 'dependabot[bot]')

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Run Semgrep scan
        run: semgrep scan --config p/security-audit --config p/rust --sarif > semgrep.sarif

      # upload-sarif lives in the codeql-action repo — same repo, different action
      - name: Upload SARIF results
        uses: github/codeql-action/upload-sarif@v4
        if: always()
        with:
          sarif_file: semgrep.sarif
          # Category prevents overwriting CodeQL results
          category: semgrep-security-audit
```

**Talk track:**
> "Three things to burn into memory. First — `security-events: write`. Miss this permission and you get a cryptic 403 that tells you nothing useful. Second — `upload-sarif` lives inside the `codeql-action` repository. Same repo, different action entry point. Third — the `category` field. Without it, Semgrep results overwrite CodeQL results. Categories are namespaces. Two scanners, two categories, no collisions."

> "We're using the official `semgrep/semgrep` Docker container — this is what Semgrep's own docs recommend. The `semgrep scan` command with `--sarif` flag outputs the results file directly. Two config packs stacked: `p/security-audit` covers JavaScript and general patterns, `p/rust` catches unsafe blocks, panics in library code, and common Rust anti-patterns. One workflow scans the entire repo — Node.js AND Rust."

---

### Step 2.3: Commit and Verify

**What to click:**
1. Click **Commit changes**
2. Select **Commit directly to the main branch**
3. Navigate to **Actions** tab
4. Watch the Semgrep workflow run

**Checkpoint:** Workflow completes with green checkmark (1-2 minutes)

**Talk track:**
> "Semgrep runs, generates SARIF, and uploads to GitHub's code scanning backend. Let's see where the results show up."

---

### Step 2.4: View Combined Results

**What to click:**
1. Click **Security** tab
2. Click **Code scanning** in left sidebar
3. Click the **Tool** filter dropdown

**What to show:**
- Filter by tool: **CodeQL** — see the JS vulnerability alerts
- Filter by tool: **Semgrep** — see the Rust and JS findings
- Clear filter — unified view of everything

**Talk track:**
> "Same Security tab, same alert format, two different engines. The Globomantics security team sees everything in one place. They don't care which scanner found the issue — they care that it's found and prioritized. This is exactly what GHAS is designed for: a single pane of glass for code security."

---

## Demo Part 3: Upload SARIF via CLI (3 min)

### Step 3.1: Run Semgrep Locally

**Switch to VS Code. Open pwsh 7 terminal.**

**What to type:**

```powershell
# Navigate to repo
cd C:\repos\globomantics-robot-fleet

# Fix Semgrep Unicode encoding on Windows
$env:PYTHONUTF8 = "1"

# Run Semgrep against the Rust telemetry CLI specifically
semgrep scan --config p/rust --sarif --output rust-scan.sarif ./rust-telemetry-cli

# Verify SARIF file
Get-Item rust-scan.sarif | Select-Object Name, Length, LastWriteTime
```

**Talk track:**
> "Not everyone uses GitHub Actions. Jenkins, Azure DevOps, GitLab CI, CircleCI — they all need to get results into GitHub. Running Semgrep locally and uploading via CLI bridges that gap. Here I'm scanning just the Rust directory to show you can target specific paths."

---

### Step 3.2: Upload via CodeQL CLI

**What to type:**

```powershell
# Upload SARIF to GitHub code scanning
codeql github upload-results `
    --repository=timothywarner-org/globomantics-robot-fleet `
    --ref=refs/heads/main `
    --commit=$(git rev-parse HEAD) `
    --sarif=rust-scan.sarif `
    --sarif-category=semgrep-rust-local
```

**Talk track:**
> "Same SARIF, different transport. The `--sarif-category` distinguishes this CLI upload from our Actions workflow upload. Two Semgrep runs, two categories, zero overwrites. If you don't have the CodeQL CLI installed, you can also use the REST API directly with `gh api`."

---

### Step 3.3: Examine SARIF Structure

**What to type:**

```powershell
# Peek inside the SARIF file
$sarif = Get-Content rust-scan.sarif | ConvertFrom-Json
$sarif.runs | Select-Object @{N='Tool';E={$_.tool.driver.name}},
                            @{N='Rules';E={$_.tool.driver.rules.Count}},
                            @{N='Results';E={$_.results.Count}}
```

**Talk track:**
> "SARIF 2.1.0 has a clean structure: runs at the top level, each run has a tool driver with rules definitions, and results with locations. The `partialFingerprints` field is how GitHub tracks alerts across commits. Even if you rename files or refactor, GitHub knows it's the same finding. That fingerprint is the secret sauce for alert stability."

> **GH-500 EXAM TIP:** SARIF categories prevent result overwrites when using multiple scanners or multiple upload sources. Always set `--sarif-category` or the `category` input.

---

## Demo Part 4: Copilot Autofix for CodeQL Alerts (5 min)

### Step 4.1: Navigate to a CodeQL Alert

**What to click:**
1. Click **Security** tab
2. Click **Code scanning** in left sidebar
3. Filter by **Tool: CodeQL**
4. Click on the **eval injection** alert (CWE-94) or any High/Critical alert

**Talk track:**
> "Copilot Autofix works on CodeQL alerts specifically — not third-party scanner results like Semgrep. It analyzes the vulnerability context, understands the data flow, and generates a working code fix. The licensing is important: Autofix comes with GHAS. No separate Copilot subscription required."

---

### Step 4.2: Generate a Fix

**What to click:**
1. Locate the **Generate fix** button on the alert page
2. Click **Generate fix**
3. Wait 10-30 seconds for AI generation

**What to show:**
- The code diff with exact changes highlighted
- The plain-English explanation of why this fix works
- The commit options (create PR or commit to branch)

**Checkpoint:** Fix appears with diff and explanation

**Talk track:**
> "Autofix analyzed the data flow through `server.js`, found that user input from the `:format` route parameter flows directly into `eval()`, and generated a fix that replaces the eval with a safe lookup pattern. The diff shows exactly what changes. The explanation tells your developers why it works — not just where the problem is, but what the secure pattern looks like."

---

### Step 4.3: Create PR with Fix

**What to click:**
1. Review the generated fix
2. Click **Create PR with fix**
3. Wait for branch creation and PR opening

**What to show:**
- Draft PR opens automatically
- Branch created with fix committed
- PR description explains the security remediation

**Talk track:**
> "Draft PR. That's intentional. Autofix generates the fix, but humans make the judgment call. Review it, run your tests, then merge. This is AI-assisted security — not auto-pilot. For Globomantics developers who aren't security specialists, this is the difference between a ticket sitting in the backlog for weeks and a fix deployed in hours."

---

### Step 4.4: Review the PR

**What to click:**
1. Click **Files changed** tab in the PR
2. Review the actual code diff

**Talk track:**
> "The changes match what Autofix previewed. For that eval injection, you'll see the dynamic eval replaced with a static mapping or switch statement. The AI handled the cognitive load of figuring out the secure pattern. Your developer just needs to verify it doesn't break business logic."

---

## Demo Part 5: When Autofix Needs Help (30 sec)

### Talk Track (No clicks)

> "Quick reality check: Autofix is best-effort, not guaranteed. Path-problem queries work best because they have clear source-to-sink data flows. Complex business logic or multi-file fixes might need manual adjustment. Some alert types don't support Autofix yet. When Autofix can't help, Copilot Chat lets you ask follow-up questions about the vulnerability. We'll see that in Module 6."

---

## Wrap-Up (30 sec)

**Talk track:**
> "Module 5 recap. Third-party scanners like Semgrep output SARIF 2.1.0 and use the `upload-sarif` action — not `codeql-action/analyze`. Categories prevent result overwrites. The CLI and REST API bridge non-GitHub CI systems. Semgrep covers languages CodeQL doesn't, like Rust. Copilot Autofix generates fixes for CodeQL alerts with no extra subscription — it ships with GHAS. Same Security tab, unified view, AI-assisted remediation."

> "In Module 6, we'll dig into query suites, trace data flow with show paths, use Copilot Chat to explain vulnerabilities in plain English, and troubleshoot failing workflows."

---

## Quick Reference

### Key Navigation Paths

| Feature | Navigation Path |
|---------|----------------|
| Code scanning alerts | **Security** > **Code scanning** |
| Create workflow | **Actions** > **New workflow** |
| Copilot Autofix | Alert page > **Generate fix** |
| Filter by tool | **Security** > **Code scanning** > **Tool** dropdown |
| GHAS settings | **Settings** > **Advanced Security** |

### PowerShell Commands

```powershell
# Fix Semgrep Unicode encoding on Windows (set once per terminal session)
$env:PYTHONUTF8 = "1"

# Run Semgrep locally (full repo)
semgrep scan --config p/security-audit --config p/rust --sarif --output results.sarif .

# Run Semgrep on Rust directory only
semgrep scan --config p/rust --sarif --output rust-scan.sarif ./rust-telemetry-cli

# Upload SARIF via CodeQL CLI
codeql github upload-results `
    --repository=timothywarner-org/globomantics-robot-fleet `
    --ref=refs/heads/main `
    --commit=$(git rev-parse HEAD) `
    --sarif=results.sarif `
    --sarif-category=semgrep-local

# List code scanning alerts via gh CLI
gh api repos/timothywarner-org/globomantics-robot-fleet/code-scanning/alerts `
    --jq '.[].rule.id'

# Filter alerts by tool
gh api repos/timothywarner-org/globomantics-robot-fleet/code-scanning/alerts `
    --jq '.[] | select(.tool.name == "Semgrep") | {number, rule: .rule.id}'
```

### GH-500 Exam Tips

| Topic | Key Point |
|-------|-----------|
| SARIF upload | Uses `upload-sarif` action (part of codeql-action repo) |
| Permission | `security-events: write` required — 403 without it |
| Categories | REQUIRED for multiple scanners — prevents overwrites |
| Autofix licensing | Included with GHAS, no Copilot subscription needed |
| Autofix scope | Works on CodeQL alerts only, not third-party results |
| SARIF version | Must be 2.1.0 |
| Fingerprints | `partialFingerprints` track alerts across commits |

---

## Troubleshooting

**SARIF upload fails with 403?**
→ Add `security-events: write` to workflow permissions

**Results overwriting each other?**
→ Add unique `category` / `--sarif-category` to each scanner

**Autofix button missing?**
→ Verify alert is from CodeQL (not third-party); check if alert type supports Autofix

**Semgrep not finding Rust files?**
→ Add `p/rust` to the config; verify `rust-telemetry-cli/` is checked out

**CLI upload fails authentication?**
→ Run `gh auth status`; ensure token has `security_events` scope

---

**Demo Length:** 15 minutes
**Module:** 5 — Third-Party Scanners, SARIF Integration, and Copilot Autofix
**Repository:** `timothywarner-org/globomantics-robot-fleet`
**Tech Stack:** Node.js (Express + EJS) + Rust (serde) with intentionally vulnerable code
