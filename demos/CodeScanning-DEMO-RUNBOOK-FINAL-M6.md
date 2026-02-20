# Module 6 Demo Runbook: CodeQL Analysis Model, Troubleshooting, and Copilot-Assisted Remediation

> **15-Minute Demo Script** — Explore query suites and build modes, trace data flow with show paths, use Copilot Chat for vulnerability explanation, triage alerts with dismissal workflows, and troubleshoot failing CodeQL workflows in the Globomantics Robot Fleet Manager

## Prerequisites

**Before recording:**

- [ ] GitHub account with `timothywarner-org` organization access
- [ ] Repo exists: `timothywarner-org/globomantics-robot-fleet`
- [ ] GHAS license active on the repository
- [ ] Copilot Enterprise license for Chat features (Autofix works with GHAS alone)
- [ ] CodeQL default setup running with alerts present (path-problem alerts ideal)
- [ ] Module 5 completed (Semgrep workflow added, combined results visible)
- [ ] GitHub CLI (`gh`) authenticated — verify with `gh auth status`
- [ ] VS Code open with extensions: GitHub Copilot, CodeQL, GitHub Actions
- [ ] PowerShell 7 terminal in VS Code

**Expected repo state:**

- CodeQL alerts from `server.js` — eval injection (CWE-94), unsafe merge (CWE-915)
- At least one alert with **Show paths** capability (path-problem query result)
- Semgrep results also visible from Module 5 (for tool filtering contrast)
- Multiple alert severities present for triage demo

**Key vulnerable patterns to reference:**

| Alert | Type | Show Paths? |
|-------|------|-------------|
| eval() code injection | Path-problem | Yes — traces `:format` param to `eval()` |
| lodash merge mass assignment | Path-problem | Yes — traces `req.body` to `_.merge()` |
| Hardcoded session secret | Problem (no path) | No |

---

## Demo Part 1: Query Suite Deep Dive (3 min)

### Step 1.1: Show Default Setup Configuration

**What to click:**
1. Open **github.com/timothywarner-org/globomantics-robot-fleet**
2. Click **Settings** tab
3. In the **Security** sidebar section, click **Advanced Security**
4. Scroll to **Code scanning** / **CodeQL analysis**
5. Point to the default setup configuration

**Talk track:**
> "This repo uses CodeQL default setup — GitHub's zero-config option. You don't write a workflow file. GitHub detects the languages, picks the query suite, and runs analysis automatically. Let's talk about what's actually happening under the hood."

---

### Step 1.2: Explain the Query Suites

**Talk track (reference your slides):**
> "Three query suites. **Default** — fewer queries, lower noise, core security only. **Security-extended** — wider net, more experimental checks. **Security-and-quality** — adds code quality findings on top."

> "Globomantics uses extended because they want max coverage and can handle the triage volume."

> **GH-500 EXAM TIP:** 'default' suite ≠ 'default setup.' Default setup is zero-config enablement. The default suite is a specific query set. Default setup lets you choose EITHER default suite OR security-extended.

---

### Step 1.3: Explain Build Modes

**Talk track:**
> "JavaScript is interpreted — CodeQL extracts from source directly. No build step. That's why default setup works so smoothly here."

> "For compiled languages: three build modes. `none` — direct extraction. `autobuild` — GitHub guesses your build system. `manual` — you specify exact build commands."

> "Globomantics' Rust CLI? CodeQL doesn't cover Rust — that's why we added Semgrep in Module 5."

> **GH-500 EXAM TIP:** Java supports `none` mode for faster scans. C++ typically needs `manual`. Know which languages need building.

---

## Demo Part 2: Show Paths — Tracing Data Flow (4 min)

### Step 2.1: Navigate to a Path-Problem Alert

**What to click:**
1. Click **Security** tab
2. Click **Code scanning** in left sidebar
3. Filter by **Tool: CodeQL**
4. Look for the **eval injection** alert or any alert with a **Show paths** link
5. Click on the alert

**Talk track:**
> "Not every alert has show paths. It only appears on path-problem queries — where CodeQL actually traced data flowing from a source to a sink. Let's follow the journey that user input takes through the code."

---

### Step 2.2: Expand Show Paths

**What to click:**
1. Locate the **Show paths** link on the alert detail page
2. Click **Show paths**

**What to show:**
- **Source node:** Where user input enters (e.g., the `:format` route parameter in Express)
- **Intermediate nodes:** Data transformations, function calls, variable assignments
- **Sink node:** Where the dangerous operation occurs (the `eval()` call)

**Talk track:**
> "This is the evidence. User input enters at the Express route parameter, flows through the handler function, gets interpolated into a string, and lands directly inside `eval()`. No sanitization, no validation, no allowlist check at any step. Click any intermediate node to jump to that exact line of code. This visualization is how you determine if an alert is a true positive or if the data is actually sanitized somewhere in the chain."

---

### Step 2.3: Validate True vs False Positive

**What to click:**
1. Click on an intermediate node in the path
2. View the code at that location in `server.js`

**Talk track:**
> "If there were proper sanitization at any step — an input validation function, an allowlist check, a type cast — the path would break. CodeQL wouldn't flag it because the tainted data would be cleaned before reaching the sink. The fact that this unbroken path exists from user input to `eval()` means this is a confirmed true positive. That's your evidence for prioritizing remediation."

> **GH-500 EXAM TIP:** Show paths traces source to sink. Use it to validate true positives and explain to developers WHY code is vulnerable, not just WHERE.

---

## Demo Part 3: Copilot Chat for Vulnerability Explanation (3 min)

### Step 3.1: Open Copilot Chat on the Alert

**What to click:**
1. Stay on the alert detail page
2. Locate the **Copilot Chat icon** (top right area of the alert)
3. Click to open Chat panel

**Checkpoint:** Chat window opens with alert context pre-loaded

**Talk track:**
> "Copilot Chat requires Copilot Enterprise — that's a different license from Autofix, which ships free with GHAS. But when you have it, you can interrogate any alert in natural language. The AI has full context: the alert, the code, the data flow."

---

### Step 3.2: Ask About the Vulnerability

**What to type:**
```
Explain how this alert introduces a vulnerability into the code.
```

**Wait for response, then show:**
- Plain-English explanation of CWE-94 (Code Injection)
- How the `:format` parameter flows to `eval()`
- Why this pattern is exploitable (arbitrary code execution)

**Talk track:**
> "When a junior developer sees 'CWE-94 Code Injection,' they might freeze. Copilot explains it: 'The format parameter from the URL is interpolated directly into an eval() call. An attacker can craft a URL that executes arbitrary JavaScript on your server.' That plain-English explanation is worth more than a thousand OWASP documentation pages for getting developers to actually fix the issue."

---

### Step 3.3: Ask for Remediation Guidance

**What to type:**
```
What is the recommended fix for this vulnerability?
```

**Show Copilot's response:**
- Specific fix: replace `eval()` with a safe mapping/switch
- Code example in JavaScript
- Explanation of why the fix prevents the attack

---

### Step 3.4: Ask About the Data Flow

**What to type:**
```
Looking at the data flow, why doesn't the existing code prevent exploitation?
```

**Talk track:**
> "Show paths gives you the map. Copilot Chat is the tour guide. You can see data flowing through the Express handler, but you don't immediately understand why there's no validation. Copilot explains: 'The handler function receives the format parameter and passes it directly to the template string inside eval(). There is no input validation, no allowlist, and no sanitization between the route parameter and the eval call.' Map plus tour guide equals developer who actually understands the fix."

---

## Demo Part 4: Alert Dismissal Workflow (2.5 min)

### Step 4.1: Navigate to an Alert for Dismissal

**What to click:**
1. Go back to **Security** > **Code scanning**
2. Pick an alert you want to demonstrate dismissal on (ideally the hardcoded session secret — it's a real issue but not exploitable in a demo app)

**Talk track:**
> "Not every alert demands immediate remediation. Some are real issues in code that's only used internally. Some are false positives from unusual code patterns. The dismissal workflow lets you document decisions — and creates an audit trail."

---

### Step 4.2: Dismiss the Alert

**What to click:**
1. Click **Dismiss alert** button
2. Select a dismissal reason:
   - **False positive** — code pattern flagged but not actually exploitable
   - **Won't fix** — real issue but accepted risk
   - **Used in tests** — intentionally vulnerable test/demo code
3. Type a comment: `"Hardcoded secret is for educational demo only. Not deployed to production. Acceptable risk for training repository."`
4. Click **Dismiss alert**

**What to show:**
- Alert moves to **Closed** list
- Dismissal reason and comment are recorded with timestamp and username

**Talk track:**
> "Three dismissal reasons. False positive: the scanner got it wrong. Won't fix: it's real but you've accepted the risk. Used in tests: intentionally vulnerable code for testing or demos — which is exactly our situation. Every dismissal creates an audit trail. Your comment should be defensible. 'I didn't feel like fixing it' won't fly with auditors."

> **GH-500 EXAM TIP:** Dismissals require documentation. Know all three reasons: false positive, won't fix, used in tests. All create audit trails.

---

### Step 4.3: Dismiss via CLI (Automation Path)

**Switch to VS Code pwsh 7 terminal.**

**What to type:**

```powershell
# Dismiss an alert via API (replace 1 with actual alert number)
gh api repos/timothywarner-org/globomantics-robot-fleet/code-scanning/alerts/1 `
    --method PATCH `
    --field state=dismissed `
    --field dismissed_reason="used in tests" `
    --field dismissed_comment="Educational demo repo with intentional vulnerabilities"

# Verify the dismissal
gh api repos/timothywarner-org/globomantics-robot-fleet/code-scanning/alerts/1 `
    --jq '{number, state, dismissed_reason, dismissed_comment}'
```

**Talk track:**
> "For bulk triage or automation, use the API. Same dismissal reasons, same audit trail, fully scriptable. Globomantics' security team could write a script that auto-dismisses known false positives across 50 repos."

---

## Demo Part 5: Troubleshooting Failing Workflows (2.5 min)

### Step 5.1: Common Failure Scenarios

**Talk track (show the table from your slides):**

| Error | Cause | Fix |
|-------|-------|-----|
| Language detection failed | Auto-detection missed a language | Specify `languages:` explicitly in workflow |
| Autobuild failed | Complex or non-standard build system | Use `build-mode: manual` with explicit commands |
| Timeout exceeded | Large codebase or mono-repo | Increase `timeout-minutes`, split into matrix jobs |
| Permission denied (403) | Missing workflow permission | Add `security-events: write` |
| No results returned | Extraction failed silently | Check logs, switch to `security-extended` suite |

> "Ninety percent of CodeQL failures boil down to one thing: not being explicit enough. Auto-detection is convenient until it breaks. The fix is always more configuration, not less."

---

### Step 5.2: Show Workflow Logs

**What to click:**
1. Navigate to **Actions** tab
2. Click on a CodeQL workflow run (or the Semgrep run from Module 5)
3. Expand the **Analyze** or **Upload SARIF** step
4. Show the log output

**Talk track:**
> "The logs tell you everything. Permission failures show 403. Build failures show compiler errors. Extraction issues list which files couldn't be processed. When someone says 'CodeQL isn't working,' the first thing you do is read the logs. They're verbose, but the answer is always in there."

---

### Step 5.3: Demonstrate Manual Build Mode Fix (Conceptual)

**What to show (explain, don't actually break the workflow):**

```yaml
# Example: fixing a failing C++ CodeQL scan
strategy:
  matrix:
    include:
      - language: c-cpp
        build-mode: manual

steps:
  - uses: actions/checkout@v4

  - name: Initialize CodeQL
    uses: github/codeql-action/init@v4
    with:
      languages: ${{ matrix.language }}
      build-mode: ${{ matrix.build-mode }}

  # Manual build for complex CMake project
  - if: matrix.build-mode == 'manual'
    name: Build C++ code
    run: |
      cmake -B build -S .
      cmake --build build

  - name: Perform CodeQL Analysis
    uses: github/codeql-action/analyze@v4
```

**Talk track:**
> "When autobuild chokes — and it will with anything beyond a basic Makefile — go manual. Specify languages, build commands, timeouts."

> "This is the pattern for any compiled language where default setup can't figure out the build."

> **GH-500 EXAM TIP:** Default setup = interpreted languages. Advanced setup with `build-mode: manual` = compiled languages with complex builds. Know when to switch.

---

## Wrap-Up (30 sec)

**Talk track:**
> "Module 6 recap. Query suites control what CodeQL looks for — default is minimal, security-extended is comprehensive. Build modes matter for compiled languages but JavaScript gets a free pass. Show paths traces data flow from source to sink, giving you the evidence to validate true positives. Copilot Chat explains vulnerabilities in plain English — requires Copilot Enterprise. Dismissals require documentation with defensible reasoning. And troubleshooting? Be more explicit in your configuration. That's the fix 90% of the time."

> "Together, Modules 5 and 6 give you the complete code scanning picture: multiple scanners unified through SARIF, AI-assisted remediation with Autofix, data flow visualization with show paths, Copilot Chat for understanding, and the troubleshooting muscle to keep it all running."

---

## Quick Reference

### Key Navigation Paths

| Feature | Navigation Path |
|---------|----------------|
| Code scanning alerts | **Security** > **Code scanning** |
| CodeQL default setup config | **Settings** > **Advanced Security** > **Code scanning** |
| Show paths | Alert page > **Show paths** link |
| Copilot Chat | Alert page > **Copilot Chat icon** |
| Dismiss alert | Alert page > **Dismiss alert** button |
| Workflow logs | **Actions** > Workflow run > Step logs |

### PowerShell Commands

```powershell
# List all code scanning alerts
gh api repos/timothywarner-org/globomantics-robot-fleet/code-scanning/alerts `
    --jq '.[] | {number, rule: .rule.id, tool: .tool.name, severity: .rule.severity}'

# Filter by severity (errors = high/critical)
gh api repos/timothywarner-org/globomantics-robot-fleet/code-scanning/alerts `
    --jq '.[] | select(.rule.severity == "error") | {number, rule: .rule.id}'

# Dismiss an alert
gh api repos/timothywarner-org/globomantics-robot-fleet/code-scanning/alerts/1 `
    --method PATCH `
    --field state=dismissed `
    --field dismissed_reason="used in tests" `
    --field dismissed_comment="Educational demo with intentional vulnerabilities"

# Re-open a dismissed alert
gh api repos/timothywarner-org/globomantics-robot-fleet/code-scanning/alerts/1 `
    --method PATCH `
    --field state=open

# Check CodeQL workflow run status
gh run list --workflow=codeql.yml --limit=5

# View workflow logs for a specific run
gh run view <run-id> --log
```

### Copilot Chat Prompts

```
# Understanding the vulnerability
Explain how this alert introduces a vulnerability into the code.

# Getting remediation guidance
What is the recommended fix for this vulnerability?

# Understanding data flow
Looking at the data flow, why doesn't the existing code prevent exploitation?

# Testing the fix
How can I test that my fix actually prevents this vulnerability?
```

### GH-500 Exam Tips

| Topic | Key Point |
|-------|-----------|
| Query suites | default = fewer queries, security-extended = comprehensive |
| Default setup vs default suite | Different things — default setup is zero-config enablement |
| Build modes | `none` (interpreted), `autobuild` (auto-detect), `manual` (explicit) |
| Show paths | Traces source to sink — validates true positives |
| Copilot Chat | Requires Copilot Enterprise (unlike Autofix which is GHAS-only) |
| Dismissal reasons | false positive, won't fix, used in tests — all create audit trails |
| Troubleshooting | Be explicit — specify languages, build commands, timeouts |

---

## Troubleshooting

**Show paths not appearing?**
→ Only path-problem queries produce show paths; not all alert types support it

**Copilot Chat not available?**
→ Requires Copilot Enterprise license; check org settings for Copilot enablement

**Workflow timing out?**
→ Add `timeout-minutes: 120` to the analyze step; split into matrix jobs

**No results after workflow success?**
→ Check extraction logs for parsing errors; try security-extended suite; verify language detection

**Dismissed alert reappearing?**
→ New commit may re-introduce the same pattern; check if it's a new instance vs. re-opened

---

**Demo Length:** 15 minutes
**Module:** 6 — CodeQL Analysis Model, Troubleshooting, and Copilot-Assisted Remediation
**Repository:** `timothywarner-org/globomantics-robot-fleet`
**Tech Stack:** Node.js (Express + EJS) + Rust (serde) with CodeQL default setup + Semgrep
