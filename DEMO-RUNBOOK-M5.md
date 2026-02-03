# Module 5 Demo Runbook: Dependency Graph, SBOM and Alert Mechanics

> **10-13 Minute Demo Script** - Explore how GitHub discovers dependencies and surfaces vulnerabilities in the Globomantics GHAS Dashboard

## Prerequisites

**Before recording:**

- [ ] GitHub account with `timothywarner-org` organization access
- [ ] Repo exists: `timothywarner-org/globomantics-ghas-dashboard`
- [ ] VS Code with extensions: GitHub Copilot, ESLint, JavaScript
- [ ] PowerShell 7+ terminal in VS Code
- [ ] GitHub CLI (`gh`) authenticated
- [ ] Edge browser open and signed into GitHub
- [ ] Dependabot alerts populated (wait 5-10 min after initial push)

**Expected state:**
- Dependency graph enabled (automatic for public repos)
- 8+ Dependabot alerts visible from intentionally vulnerable packages
- SBOM exportable via UI and API

**Vulnerable packages in package.json (for reference):**
| Package | Version | CVE | Severity |
|---------|---------|-----|----------|
| lodash | 4.17.20 | CVE-2021-23337, CVE-2020-28500 | Critical, High |
| axios | 0.21.1 | CVE-2021-3749 | High |
| node-fetch | 2.6.1 | CVE-2022-0235 | High |
| minimist | 1.2.5 | CVE-2021-44906 | Critical |
| tar | 4.4.13 | CVE-2021-32803, CVE-2021-32804 | High |
| glob-parent | 5.1.1 | CVE-2020-28469 | High |
| trim-newlines | 3.0.0 | CVE-2021-33623 | High |
| path-parse | 1.0.6 | CVE-2021-23343 | High |

---

## Demo Part 1: What Is the Dependency Graph? (2.5 min)

### Step 1.1: Open the Repository

**What to click:**
1. Open **github.com/timothywarner-org/globomantics-ghas-dashboard**
2. Click **Insights** tab
3. Click **Dependency graph** in left sidebar

**Talking points:**
> "The dependency graph is the foundation of GitHub's supply chain security. Think of it as the bedrock everything else builds on. No graph means no Dependabot alerts. No alerts means no automated security updates. The Globomantics platform engineering team needs to understand this chain."

---

### Step 1.2: Explore the Dependencies Tab

**What to show:**
- Note the **npm** ecosystem indicator at the top
- Scroll through the parsed dependencies
- Point to direct production dependencies: `express`, `@octokit/rest`, `cors`, `helmet`
- Point to the vulnerable packages: `lodash`, `axios`, `node-fetch`, `minimist`

**Talking points:**
> "GitHub parsed our package.json and built this graph automatically. These are direct dependencies the Globomantics team explicitly declared. For each one, GitHub tracks the version and cross-references it against the Advisory Database. Notice we're seeing npm ecosystem here since this is a Node.js application."

---

### Step 1.3: Show Dependents Tab

**What to click:**
1. Click **Dependents** tab

**Talking points:**
> "The other direction: who depends on US? If Globomantics published this dashboard as a public npm package, downstream consumers would appear here. This is critical for maintainers to understand blast radius. Ship a vulnerability, and you can see exactly who gets affected."

---

### Step 1.4: Show Where the Data Comes From

**What to click:**
1. Navigate to **Code** tab
2. Open `package.json`
3. Scroll to the `dependencies` section

**What to show:**
```json
"dependencies": {
  "@octokit/rest": "^20.0.0",
  "cors": "^2.8.5",
  "express": "^4.18.2",
  "lodash": "4.17.20",
  "axios": "0.21.1"
}
```

**Talking points:**
> "GitHub parses this manifest file to build the graph. For Node.js: package.json plus lock files. For Python: pyproject.toml, requirements.txt. For Go: go.mod. The more precise your dependency declarations, especially with lock files, the better the graph accuracy."

---

## Demo Part 2: Manifest vs Lock Files (2 min)

### Step 2.1: Explain the Difference

**What to show:**
- Stay on `package.json`
- Highlight version specifiers like `"express": "^4.18.2"` and `"@octokit/rest": "^20.0.0"`

**Talking points:**
> "See this caret? It means 'version 4.18.2 or any compatible higher version.' That's a range. We don't know exactly what version got installed. A package-lock.json pins it precisely: express 4.18.2, with this exact integrity hash, pulling these exact transitive dependencies."

---

### Step 2.2: Why It Matters for Security

**Talking points:**
> "Lock files give GitHub more reliable data. Without them, GitHub sees what you ASKED for. With them, GitHub sees what you GOT. For vulnerability detection, that precision matters enormously. The Globomantics security team should always verify lock files are committed."

> "Exam tip: Lock files produce more accurate dependency graphs. Always commit your package-lock.json or yarn.lock files."

---

### Step 2.3: Show Supported Ecosystems

**Talking points:**
> "GitHub supports all major ecosystems: npm with package-lock.json, pip with Pipfile.lock or requirements.txt, Maven with pom.xml, NuGet, Cargo, Go modules. And here's one people miss constantly: GitHub Actions workflows. Dependabot scans those too for vulnerable action versions."

---

## Demo Part 3: Enabling the Dependency Graph (1.5 min)

### Step 3.1: Show Settings Location

**What to click:**
1. Click **Settings** tab
2. Click **Code security and analysis** in left sidebar
3. Point to **Dependency graph** toggle

**Talking points:**
> "Public repos like this Globomantics dashboard: dependency graph is automatically enabled. Private repos: you flip this switch manually. This is always step one before anything else works."

---

### Step 3.2: Show the Dependency Chain

**What to click:**
1. Point to **Dependency graph** toggle
2. Point to **Dependabot alerts** toggle (directly below)
3. Point to **Dependabot security updates** toggle (below that)

**Talking points:**
> "See the order? Dependency graph first. Then alerts. Then security updates. Each feature depends on the one above it. If someone asks 'why aren't my Dependabot alerts working?' first thing to check: is the dependency graph enabled?"

> "Exam tip: The dependency graph MUST be enabled before Dependabot alerts can function. Know this chain."

---

## Demo Part 4: Software Bill of Materials (2.5 min)

### Step 4.1: Explain What SBOM Is

**Talking points:**
> "SBOM: Software Bill of Materials. A complete, machine-readable inventory of every component in your software. Think of it like a nutrition label for code. Federal contracts under Executive Order 14028 now require these. Globomantics' government clients are asking for SBOMs on every delivery."

---

### Step 4.2: Export SBOM via UI

**What to click:**
1. Click **Insights** tab
2. Click **Dependency graph** in left sidebar
3. Click **Export SBOM** button (top right of the dependencies list)
4. Save the downloaded file

**Talking points:**
> "One click. GitHub generates a complete inventory of everything in this repository. This is exactly what you hand to auditors, compliance teams, or government contract officers."

---

### Step 4.3: Examine SBOM Contents

**What to click:**
1. Open the downloaded SBOM JSON file in VS Code

**What to show:**
```json
{
  "spdxVersion": "SPDX-2.3",
  "dataLicense": "CC0-1.0",
  "SPDXID": "SPDXRef-DOCUMENT",
  "name": "com.github.timothywarner-org/globomantics-ghas-dashboard",
  "packages": [
    {
      "name": "npm:lodash",
      "versionInfo": "4.17.20",
      "SPDXID": "SPDXRef-Package-npm-lodash-4.17.20"
    }
  ]
}
```

**Talking points:**
> "SPDX 2.3 format. That's the ISO/IEC 5962:2021 standard. NOT CycloneDX. Know this for the exam. If a compliance team specifically needs CycloneDX format, you'll need external tooling like Syft or cdxgen to convert. GitHub exports SPDX natively."

---

### Step 4.4: Export via CLI

**What to type in PowerShell:**
```powershell
# Export SBOM using GitHub CLI
gh api repos/timothywarner-org/globomantics-ghas-dashboard/dependency-graph/sbom > sbom.json

# View the file
code sbom.json
```

**Talking points:**
> "For automation, CI pipelines, or compliance workflows, use the API. Same data, fully scriptable. The Globomantics DevSecOps team runs this command on every release and archives the SBOM for audit trail."

---

## Demo Part 5: Dependabot Alerts Deep Dive (2.5 min)

### Step 5.1: Navigate to Security Tab

**What to click:**
1. Click **Security** tab
2. Click **Dependabot alerts** in left sidebar (under Vulnerability alerts)

**Talking points:**
> "This is where vulnerabilities surface. GitHub cross-referenced our dependency graph against the GitHub Advisory Database and found matches. These are real CVEs in packages we declared."

---

### Step 5.2: Examine Alert List

**What to show:**
- Count of alerts (should be 8+ alerts)
- Severity badges: Critical (red), High (orange), Medium (yellow)
- Package names: lodash, axios, node-fetch, minimist, tar, etc.

**Talking points:**
> "lodash, axios, node-fetch, minimist, tar, and more. All have known CVEs. GitHub shows severity to help us prioritize. The Globomantics security team should address Critical first, then High, then work down the list."

---

### Step 5.3: Deep Dive on One Alert

**What to click:**
1. Click the **lodash** alert for **CVE-2021-23337** (Command Injection)

**What to show:**
- CVE identifier: CVE-2021-23337
- Severity: Critical (CVSS 7.2)
- Description: Command Injection vulnerability
- Affected versions: < 4.17.21
- Patched version: 4.17.21
- Remediation: Update to lodash 4.17.21 or later

**Talking points:**
> "CVE-2021-23337: command injection in lodash's template function. Critical severity. Affects all versions before 4.17.21. The fix? Update to 4.17.21. GitHub gives us everything needed to act: the CVE, severity, affected range, and exact fix version."

---

### Step 5.4: Show the Advisory Database Source

**Talking points:**
> "This data comes from the GitHub Advisory Database, not a direct NVD lookup. GitHub curates each entry: they verify affected version ranges, add ecosystem-specific context, and reduce false positives. That curation is what makes Dependabot alerts actionable."

> "Exam tip: Dependabot alerts use the GitHub Advisory Database as their primary source, not direct NVD queries."

---

### Step 5.5: Demonstrate Alert Permissions

**Talking points:**
> "Who can see these alerts? Not everyone. Read access to the repository? You see nothing. Write access? You can view and dismiss alerts. Admin access? You can enable or disable the feature entirely. This catches people off guard in enterprise environments."

> "Exam tip: Write access is the MINIMUM required to view Dependabot alerts. Read-only collaborators cannot see security alerts."

---

### Step 5.6: Direct vs Transitive Dependencies

**What to show:**
- Point to the "Dependency" section in an alert
- Show whether the vulnerable package is direct or transitive

**Talking points:**
> "Notice GitHub tells us whether this is a direct dependency, something we explicitly declared, or a transitive dependency, something pulled in by another package. Direct dependencies are easier to fix: update your package.json. Transitive ones require updating the parent package that pulls them in."

---

## Wrap-Up (30 sec)

**Talking points:**
> "Module 5 recap for the Globomantics platform engineering team: The dependency graph is the foundation. No graph, no alerts, no security updates. Lock files give better data than manifest ranges. SBOMs export in SPDX 2.3 format for compliance. Dependabot alerts come from the curated GitHub Advisory Database. And write access is required to even see alerts."

> "In Module 6, we'll configure Dependabot with dependabot.yml and implement proactive PR-time controls with the dependency review action."

---

## Quick Reference

### Key Navigation Paths

| Feature | Navigation Path |
|---------|----------------|
| Dependency graph | **Insights** > **Dependency graph** |
| Dependabot alerts | **Security** > **Dependabot alerts** |
| Enable features | **Settings** > **Code security and analysis** |
| Export SBOM (UI) | **Insights** > **Dependency graph** > **Export SBOM** |
| Package manifest | **Code** > `package.json` |

### PowerShell Commands

```powershell
# Export SBOM via API
gh api repos/timothywarner-org/globomantics-ghas-dashboard/dependency-graph/sbom > sbom.json

# List all Dependabot alerts
gh api repos/timothywarner-org/globomantics-ghas-dashboard/dependabot/alerts

# Get a specific alert by number
gh api repos/timothywarner-org/globomantics-ghas-dashboard/dependabot/alerts/1

# List alerts with severity filter (PowerShell)
gh api repos/timothywarner-org/globomantics-ghas-dashboard/dependabot/alerts --jq '.[] | select(.security_advisory.severity == "critical")'

# Count alerts by severity
gh api repos/timothywarner-org/globomantics-ghas-dashboard/dependabot/alerts --jq 'group_by(.security_advisory.severity) | .[] | {severity: .[0].security_advisory.severity, count: length}'
```

### Vulnerable Packages Reference

| Package | Pinned Version | CVE | Type | Severity |
|---------|---------------|-----|------|----------|
| lodash | 4.17.20 | CVE-2021-23337 | Command Injection | Critical |
| lodash | 4.17.20 | CVE-2020-28500 | ReDoS | High |
| axios | 0.21.1 | CVE-2021-3749 | ReDoS | High |
| node-fetch | 2.6.1 | CVE-2022-0235 | Info Exposure | High |
| minimist | 1.2.5 | CVE-2021-44906 | Prototype Pollution | Critical |
| tar | 4.4.13 | CVE-2021-32803 | Arbitrary File Write | High |
| tar | 4.4.13 | CVE-2021-32804 | Arbitrary File Write | High |
| glob-parent | 5.1.1 | CVE-2020-28469 | ReDoS | High |
| trim-newlines | 3.0.0 | CVE-2021-33623 | ReDoS | High |
| path-parse | 1.0.6 | CVE-2021-23343 | ReDoS | High |

### Exam Tips Mentioned

| Topic | Key Point |
|-------|-----------|
| Dependency graph | Must be enabled BEFORE Dependabot alerts can function |
| Lock files | Produce more reliable/accurate dependency graphs |
| SBOM format | GitHub exports SPDX 2.3 (NOT CycloneDX) |
| Advisory source | GitHub Advisory Database (NOT direct NVD lookup) |
| Alert permissions | Write access required to view Dependabot alerts |
| Feature chain | Graph > Alerts > Security Updates (dependency order) |

---

## Troubleshooting

**No alerts showing?**
- Wait 5-10 minutes after initial repository push
- Verify dependency graph is enabled in Settings
- Confirm package.json contains vulnerable versions
- Check that you have write access (read-only cannot see alerts)

**SBOM export button missing?**
- Dependency graph must be enabled first
- Button appears in the Dependency graph view under Insights

**CLI commands failing?**
- Verify `gh auth status` shows authenticated
- Confirm you have appropriate repository permissions
- Check organization access: `gh auth refresh -s read:org`

---

**Demo Length:** 10-13 minutes
**Module:** 5 - Dependency Graph, SBOM and Alert Mechanics
**Repository:** `timothywarner-org/globomantics-ghas-dashboard`
**Tech Stack:** Node.js + Express backend, React + Vite frontend
