# Learner Resources: Modules 5 & 6

> Dependency Graph, SBOM, Dependabot Alerts, Configuration, and Dependency Review

All links verified February 2026.

---

## Module 5: Dependency Graph, SBOM, and Alert Mechanics

### Dependency Graph

| Resource | Link |
|----------|------|
| About the dependency graph | https://docs.github.com/en/code-security/supply-chain-security/understanding-your-software-supply-chain/about-the-dependency-graph |
| Enabling the dependency graph | https://docs.github.com/en/code-security/supply-chain-security/understanding-your-software-supply-chain/configuring-the-dependency-graph |
| Exploring the dependencies of a repository | https://docs.github.com/en/code-security/supply-chain-security/understanding-your-software-supply-chain/exploring-the-dependencies-of-a-repository |
| About supply chain security (overview) | https://docs.github.com/en/code-security/supply-chain-security/understanding-your-software-supply-chain/about-supply-chain-security |

### Software Bill of Materials (SBOM)

| Resource | Link |
|----------|------|
| Exporting an SBOM for your repository | https://docs.github.com/en/code-security/supply-chain-security/understanding-your-software-supply-chain/exporting-a-software-bill-of-materials-for-your-repository |
| SPDX specification overview | https://spdx.dev/learn/overview/ |
| SPDX tools and libraries | https://spdx.dev/use/spdx-tools/ |
| CISA: Software Bill of Materials (SBOM) | https://www.cisa.gov/sbom |

### Dependabot Alerts

| Resource | Link |
|----------|------|
| About Dependabot alerts | https://docs.github.com/en/code-security/dependabot/dependabot-alerts/about-dependabot-alerts |
| Configuring Dependabot alerts | https://docs.github.com/en/code-security/dependabot/dependabot-alerts/configuring-dependabot-alerts |
| About Dependabot auto-triage rules | https://docs.github.com/en/code-security/dependabot/dependabot-auto-triage-rules/about-dependabot-auto-triage-rules |
| Dependabot alerts REST API | https://docs.github.com/en/rest/dependabot/alerts |

### GitHub Advisory Database

| Resource | Link |
|----------|------|
| About the GitHub Advisory Database | https://docs.github.com/en/code-security/security-advisories/working-with-global-security-advisories-from-the-github-advisory-database/about-the-github-advisory-database |
| Browse the Advisory Database | https://github.com/advisories |
| National Vulnerability Database (NVD) | https://nvd.nist.gov/ |

---

## Module 6: Dependabot Config, Rules, and Dependency Review Action

### dependabot.yml Configuration

| Resource | Link |
|----------|------|
| Dependabot options reference (dependabot.yml) | https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file |
| Configuring Dependabot version updates | https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuring-dependabot-version-updates |
| About Dependabot version updates | https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/about-dependabot-version-updates |
| Managing pull requests for dependency updates | https://docs.github.com/en/code-security/dependabot/working-with-dependabot/managing-pull-requests-for-dependency-updates |

### Security Updates vs Version Updates

| Resource | Link |
|----------|------|
| About Dependabot security updates | https://docs.github.com/en/code-security/dependabot/dependabot-security-updates/about-dependabot-security-updates |

### Dependency Review Action

| Resource | Link |
|----------|------|
| About dependency review | https://docs.github.com/en/code-security/supply-chain-security/understanding-your-software-supply-chain/about-dependency-review |
| dependency-review-action (GitHub repo) | https://github.com/actions/dependency-review-action |

---

## Microsoft Learn: Supply Chain Security

| Resource | Link |
|----------|------|
| Azure Security Benchmark: DevOps Security (DS-2) | https://learn.microsoft.com/en-us/security/benchmark/azure/mcsb-devops-security#ds-2-secure-the-software-supply-chain |
| Embed Zero Trust security into your developer workflow | https://learn.microsoft.com/en-us/security/zero-trust/develop/embed-zero-trust-dev-workflow |
| NuGet supply chain best practices (dependency concepts) | https://learn.microsoft.com/en-us/nuget/concepts/security-best-practices |
| DoD Zero Trust: Software risk management | https://learn.microsoft.com/en-us/security/zero-trust/dod-zero-trust-strategy-apps#33-software-risk-management |

---

## Standards and Government References

| Resource | Link |
|----------|------|
| SPDX specification (ISO/IEC 5962:2021) | https://spdx.dev/learn/overview/ |
| NIST National Vulnerability Database | https://nvd.nist.gov/ |
| CISA SBOM resources | https://www.cisa.gov/sbom |

---

## Exam Tip Quick Links

These resources map directly to exam-tested concepts from Modules 5 and 6:

| Exam Topic | Key Resource |
|------------|-------------|
| Dependency graph must be enabled before alerts | [Enabling the dependency graph](https://docs.github.com/en/code-security/supply-chain-security/understanding-your-software-supply-chain/configuring-the-dependency-graph) |
| Lock files produce more accurate graphs | [About the dependency graph](https://docs.github.com/en/code-security/supply-chain-security/understanding-your-software-supply-chain/about-the-dependency-graph) |
| SBOM exports in SPDX 2.3 format | [Exporting an SBOM](https://docs.github.com/en/code-security/supply-chain-security/understanding-your-software-supply-chain/exporting-a-software-bill-of-materials-for-your-repository) |
| Alerts use GitHub Advisory Database | [About the Advisory Database](https://docs.github.com/en/code-security/security-advisories/working-with-global-security-advisories-from-the-github-advisory-database/about-the-github-advisory-database) |
| Write access required for alerts | [Configuring Dependabot alerts](https://docs.github.com/en/code-security/dependabot/dependabot-alerts/configuring-dependabot-alerts) |
| dependabot.yml version must be 2 | [Dependabot options reference](https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file) |
| github-actions is a valid ecosystem | [Dependabot options reference](https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file) |
| Security updates disabled by default | [About Dependabot security updates](https://docs.github.com/en/code-security/dependabot/dependabot-security-updates/about-dependabot-security-updates) |
| Grouped updates: patterns, update-types, dependency-type | [Dependabot options reference](https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file) |
| Cannot combine allow-licenses and deny-licenses | [dependency-review-action](https://github.com/actions/dependency-review-action) |
| Dependency review is proactive (PR-time) | [About dependency review](https://docs.github.com/en/code-security/supply-chain-security/understanding-your-software-supply-chain/about-dependency-review) |
