# Security Overview Demo Punchlist (Module 5)

**Repo:** `timothywarner-org/globomantics-robot-fleet`
**Total time:** ~12 min
**Last updated:** 2026-02-21

---

## Pre-Flight Checklist

- [ ] **Verify** `gh auth status` shows authenticated with `admin:org` scope
- [ ] **Open** browser to `github.com/timothywarner-org/globomantics-robot-fleet`
- [ ] **Open** a second browser tab to `github.com/organizations/timothywarner-org/settings/security`
- [ ] **Confirm** Security Overview has data (at least one repo with Secret Protection and/or Code Security enabled)
- [ ] **Confirm** you are logged in as an **org owner** (required for full Security Overview access)
- [ ] **Open** PowerShell 7 terminal (not Windows PS 5.1)
- [ ] **Confirm** Dependabot alerts exist in repo Security tab (at least 2)
- [ ] **Confirm** code scanning alerts exist in repo Security tab (at least 3)
- [ ] **Optional:** Open an incognito window logged in as a non-admin developer account to show restricted visibility

---

## MODULE 5: Security Overview and Role-based Alert Visibility

### 1. Set the Stage (~2 min)

- [ ] **Show** the repo in browser -- click through a few files briefly
- [ ] **SAY THIS:** "This repo has intentional vulnerabilities across code, dependencies, and secrets. We're going to zoom out from the repo level and look at how GitHub gives org owners a bird's-eye view of security posture across every repo in the organization."
- [ ] **Show** the repo-level Security tab briefly -- point out code scanning, Dependabot, and secret scanning sections
- [ ] **SAY THIS:** "This per-repo view is useful for individual contributors. But if you're a security manager responsible for 50 or 500 repos, you need Security Overview."

> **GH-500:** Security Overview is an **organization-level** feature. It does NOT exist at the repo level. Know where to find it: org settings, not repo settings.

---

### 2. Navigate Security Overview (~3 min)

- [ ] **Navigate** to the org: `github.com/orgs/timothywarner-org/security`
- [ ] **SHOW THIS:** The Security Overview landing page with its three tabs: **Detection**, **Remediation**, **Prevention**
- [ ] **Click** the **Detection** tab
- [ ] **SAY THIS:** "Detection shows you what's been found. This is your 'how exposed are we' view. Alert counts by severity, broken out by tool -- code scanning, Dependabot, secret scanning."
- [ ] **Point** to the severity breakdown -- critical, high, medium, low
- [ ] **Click** the **Remediation** tab
- [ ] **SAY THIS:** "Remediation tracks how fast your teams are closing alerts. Mean time to remediate is your key metric here. This is what leadership cares about -- are we getting better or worse?"
- [ ] **SHOW THIS:** The remediation trends over time
- [ ] **Click** the **Prevention** tab
- [ ] **SAY THIS:** "Prevention shows what you're catching before it lands in your default branch. Push protection blocks, secret scanning on PRs, code scanning PR checks. This is the shift-left story in data."

> **GH-500:** Three tabs: Detection (what's found), Remediation (how fast you fix), Prevention (what you block). Expect questions on which tab shows which data.

---

### 3. Filter and Export (~2 min)

- [ ] **Return** to the Detection tab
- [ ] **Click** the severity filter -- select **Critical** and **High** only
- [ ] **SAY THIS:** "Filtering by severity is the first thing a security manager does in a compliance review. Critical and high first, always."
- [ ] **Click** the tool filter -- select **Code scanning** only
- [ ] **SHOW THIS:** The filtered results narrowed to high-severity code scanning alerts
- [ ] **Clear** the tool filter -- show **Secret scanning** only
- [ ] **Click** the time-range filter -- set to **Last 30 days**
- [ ] **Point** to the browser URL bar
- [ ] **SAY THIS:** "Notice the URL updated with query parameters. Copy this URL and paste it into a Slack channel or email -- your colleague sees exactly the same filtered view. No screenshots needed."
- [ ] **Click** the **Export CSV** button (or the download icon)
- [ ] **SAY THIS:** "CSV export gives you every alert in a spreadsheet. Compliance teams love this. Attach it to your quarterly security review and you have an auditable record."

> **GH-500:** Shareable filtered URLs and CSV export are key compliance features. The exam tests whether you know how to generate evidence for auditors.

---

### 4. Coverage Tab (~2 min)

- [ ] **Click** the **Coverage** tab (within Security Overview)
- [ ] **SHOW THIS:** The grid showing which repos have which features enabled -- code scanning, Dependabot, secret scanning
- [ ] **SAY THIS:** "Coverage answers the question: are we actually protected? A green checkmark means that feature is enabled. A gap means risk. This is your enablement audit."
- [ ] **Point** to any repo with a missing feature -- highlight the gap
- [ ] **SAY THIS:** "Since April 2025, GitHub unbundled GHAS into two separate products. Secret Protection at about 19 dollars per committer per month, and Code Security at about 30 dollars per committer per month. Dependabot is always free, even on private repos."
- [ ] **Show** a repo with full coverage vs. one with partial coverage

> **GH-500:** Licensing matrix -- Dependabot is **free** for all repos. Secret Protection is ~$19/committer/month. Code Security is ~$30/committer/month. Public repos get everything free. Know which features require which product.

> **GH-500:** The unbundling happened in **April 2025**. Before that, GHAS was a single SKU. Expect the exam to reference the current two-product model.

---

### 5. Role-based Visibility (~2 min)

- [ ] **SAY THIS:** "Not everyone sees the same alerts. GitHub uses role-based visibility to control who sees what in Security Overview."
- [ ] **SHOW THIS:** Point to the current view (full org-level data visible because you are an org owner)
- [ ] **SAY THIS:** "As an org owner or security manager, I see alerts across every repo. A repo admin only sees alerts for repos they administer. And a regular developer? They see code scanning and Dependabot alerts for their repos, but they do NOT see secret scanning alerts by default."

| Role | Code Scanning | Dependabot | Secret Scanning | Security Overview |
|---|---|---|---|---|
| **Org owner / Security manager** | All repos | All repos | All repos | Full access |
| **Repo admin** | Their repos | Their repos | Their repos | Their repos only |
| **Developer (write access)** | Their repos | Their repos | **No** | **No** |

- [ ] **SAY THIS:** "Why hide secret scanning from developers? Because the alert itself contains the secret value. GitHub limits exposure by restricting who can see it."
- [ ] **SAY THIS:** "If you need to give a developer or a security champion access to secret scanning without making them a repo admin, you create a custom security role at the org level. Navigate to Organization settings, Roles, and create a role that includes the 'View secret scanning alerts' permission."
- [ ] **SHOW THIS:** Navigate to `github.com/organizations/timothywarner-org/settings/roles` (or describe if custom roles require GitHub Enterprise)

> **GH-500:** Developers do NOT see secret scanning alerts by default. Custom security roles let you delegate access without over-provisioning admin rights. This is a high-frequency exam topic.

---

### 6. CLI: Query Alerts via API (~2 min)

**Switch to PowerShell terminal.**

- [ ] **SAY THIS:** "Everything you see in the UI is available through the API. Let's query org-level alerts from the command line."
- [ ] **Run** org-level code scanning alerts:

```powershell
gh api orgs/timothywarner-org/code-scanning/alerts `
    --jq '.[0:5] | .[] | {repo: .repository.name, rule: .rule.id, severity: .rule.severity}'
```

- [ ] **SHOW THIS:** The JSON output with repo name, rule ID, and severity
- [ ] **SAY THIS:** "This is the org-level endpoint. It returns alerts from every repo you have access to. As an org owner, that means everything."
- [ ] **Run** secret scanning alerts (requires security manager role):

```powershell
gh api orgs/timothywarner-org/secret-scanning/alerts `
    --jq '.[0:5] | .[] | {repo: .repository.name, secret_type: .secret_type}'
```

- [ ] **SAY THIS:** "This endpoint requires org owner or security manager permissions. A regular developer would get a 404 -- not a 403. GitHub returns 404 to avoid confirming the endpoint even exists."
- [ ] **Run** Dependabot alerts for a specific repo:

```powershell
gh api repos/timothywarner-org/globomantics-robot-fleet/dependabot/alerts `
    --jq '.[0:5] | .[] | {package: .dependency.package.name, severity: .security_advisory.severity}'
```

- [ ] **SHOW THIS:** The Dependabot alert output with package names and severities

> **GH-500:** The org-level secret scanning API returns **404** (not 403) for unauthorized users. This prevents information disclosure about the endpoint itself.

> **GH-500:** Org-level API endpoints: `/orgs/{org}/code-scanning/alerts`, `/orgs/{org}/secret-scanning/alerts`, `/orgs/{org}/dependabot/alerts`. Repo-level uses `/repos/{owner}/{repo}/...` instead.

---

### 7. Module 5 Wrap-Up (~30 sec)

- [ ] **SAY THIS:** "Recap: Security Overview gives org owners and security managers a single pane of glass across all repos. Three tabs -- Detection, Remediation, Prevention. The Coverage tab shows enablement gaps. Role-based visibility means developers see code scanning and Dependabot but not secret scanning. Custom roles bridge the gap without over-provisioning. CSV export and shareable URLs make compliance reporting painless. And since April 2025, GHAS is two products: Secret Protection and Code Security, with Dependabot staying free."

---

## Emergency Fallbacks

If **Security Overview** is not loading or the org has no data:
- Describe the three tabs verbally and show the GitHub docs page: `docs.github.com/en/enterprise-cloud@latest/code-security/security-overview/about-security-overview`

If the **CLI commands fail** (auth or permission issues):
- Run `gh auth status` to verify scopes
- Run `gh auth refresh -s admin:org` to add missing scopes
- Show the expected JSON output verbally or from a pre-captured screenshot

If **custom security roles** are not available (requires GitHub Enterprise Cloud):
- Explain the feature verbally
- Show the docs page: `docs.github.com/en/enterprise-cloud@latest/organizations/managing-peoples-access-to-your-organization-with-roles/managing-custom-repository-roles-for-an-organization`

If **CSV export** button is missing:
- Note that CSV export requires GitHub Enterprise Cloud
- Show the API alternative: `gh api orgs/timothywarner-org/code-scanning/alerts > alerts-export.json`

---

## GH-500 Exam Cheat Sheet

| Topic | Remember This |
|---|---|
| Security Overview location | **Organization level**, not repo level |
| Three tabs | Detection (found), Remediation (fixed), Prevention (blocked) |
| Coverage tab | Shows enablement gaps across all repos |
| Dependabot pricing | **Always free**, all repos including private |
| Secret Protection pricing | ~$19/committer/month for private repos |
| Code Security pricing | ~$30/committer/month for private repos |
| Public repo pricing | **All GHAS features free** on public repos |
| GHAS unbundling | April 2025 -- split into Secret Protection + Code Security |
| Developer visibility | Code scanning + Dependabot yes; secret scanning **NO** |
| Org owner visibility | Full access to all alert types across all repos |
| Custom security roles | Delegate secret scanning access without admin rights |
| Why hide secrets from devs | Alert contains the actual secret value |
| Secret scanning API (unauthorized) | Returns **404**, not 403 (information disclosure prevention) |
| Org-level API endpoints | `/orgs/{org}/code-scanning/alerts`, `/orgs/{org}/secret-scanning/alerts` |
| CSV export | Enterprise Cloud feature for compliance reporting |
| Shareable URLs | Filter parameters encode into URL query string |
| Shift-left metric | Prevention tab tracks what's blocked before merge |

---

## Key URLs

- **Repo:** `https://github.com/timothywarner-org/globomantics-robot-fleet`
- **Org Security Overview:** `https://github.com/orgs/timothywarner-org/security`
- **Org Settings (Roles):** `https://github.com/organizations/timothywarner-org/settings/roles`
- **Repo Security Tab:** `https://github.com/timothywarner-org/globomantics-robot-fleet/security`
- **Security Overview Docs:** `https://docs.github.com/en/enterprise-cloud@latest/code-security/security-overview/about-security-overview`
- **Custom Roles Docs:** `https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-peoples-access-to-your-organization-with-roles/managing-custom-repository-roles-for-an-organization`
- **GHAS Pricing:** `https://docs.github.com/en/billing/managing-billing-for-your-products/managing-billing-for-github-advanced-security`
- **Security API Docs:** `https://docs.github.com/en/rest/code-scanning/code-scanning`
