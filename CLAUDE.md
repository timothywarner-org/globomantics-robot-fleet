# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

Educational demo repository for Tim Warner's Pluralsight course on GitHub Advanced Security (GHAS) — specifically focused on secret scanning, dependency management, and supply chain security (GH-500 cert and non-cert tracks). This is **not a production application**. It intentionally contains vulnerable dependencies and insecure code patterns for training demonstrations.

## Build & Run Commands

```bash
# Install dependencies
npm install

# Start the server (port 3000)
npm start            # node server.js
npm run dev          # nodemon server.js (auto-reload)

# Lint (ESLint configured but no custom rules)
npx eslint .

# Tests — no test suite exists; `npm test` exits with error by design
```

There is no build step — the app runs directly via Node.js/Express.

```bash
# Rust telemetry CLI (requires Rust toolchain)
cd rust-telemetry-cli
cargo build --release
cargo run -- sample                          # print sample telemetry JSON
cargo run -- health sample-telemetry.json    # fleet health analysis
```

## Architecture

**Single-server Express app** (`server.js`) serving EJS templates with in-memory mock data (no database).

- `server.js` — Entire backend: routes, middleware, mock data (3 robots, 1 admin user), and intentional vulnerabilities
- `views/*.ejs` — EJS templates (`layout.ejs` base template, `dashboard.ejs`, `robots.ejs`, `robot-detail.ejs`, `maintenance.ejs`)
- `public/` — Static assets (CSS, JS, SVG logo)

### Rust Telemetry CLI (`rust-telemetry-cli/`)

Standalone Rust binary for fleet telemetry decoding, health analysis, and report generation. Provides a multi-language scanning target for Semgrep and CodeQL demos alongside the JavaScript codebase.

- `src/main.rs` — CLI entry point and argument routing
- `src/telemetry.rs` — Data structures, JSON parsing, sample data generation
- `src/fleet.rs` — Health analysis engine with configurable alert thresholds
- `src/report.rs` — Formatted text report output

### Intentional Vulnerabilities (for demo purposes)

These exist on purpose — do not "fix" them unless specifically asked:
- CSP disabled in Helmet config (`server.js` ~line 19)
- Hardcoded weak session secret (`server.js` ~line 28)
- Insecure cookie settings (`server.js` ~line 31)
- Unsafe `_.merge()` on user input — prototype pollution (`server.js` ~line 127)
- Unsafe `eval()` in export endpoint (`server.js` ~line 153)
- 34+ known vulnerable npm dependencies (lodash 4.17.20, axios 0.21.1, handlebars 4.0.0, ws 5.2.0, tar 4.4.8, serialize-javascript 3.0.0, etc.)

## GitHub Security Configuration

- **`.github/dependabot.yml`** — Enterprise-grade Dependabot config: daily npm updates, weekly GitHub Actions updates, grouped PRs, smart ignore rules
- **`.github/workflows/dependency.review.yml`** — Dependency review workflow on PRs to main: vulnerability scanning (fails on HIGH), license compliance (allowlist-based), OpenSSF Scorecard
- **`SECURITY.md`** — Comprehensive enterprise security policy (SOC 2, ISO 27001 framework references)

## Key Documentation

- `DEMO-RUNBOOK-M5.md` — Module 5 demo script: Dependency Graph, SBOM, Alert Mechanics
- `DEMO-RUNBOOK-M6.md` — Module 6 demo script: Dependabot Config, Rules, Dependency Review
- `learner-resources.md` — Curated GHAS learning links
- `security-policy-implementation.md` — Enterprise security policy implementation guide
- `example-files/` — Reference Dependabot configurations (basic through enterprise-grade)

## Helper Scripts

- `gh-dependency-toolkit.sh` — Bash script using `gh` CLI for vulnerability alerts and Dependabot PR management
- `dependabot-runbook.ps1` — PowerShell Dependabot automation
- `get-dependabot-dismissals.ps1` — PowerShell script to analyze dismissed Dependabot alerts
- `scripts/link-verifier/` — Python-based link verification toolkit

## Working With This Repo

- **Do not upgrade vulnerable dependencies** unless explicitly asked — they are intentional teaching material
- **Do not remove intentional security flaws** in `server.js` — they demonstrate GHAS detection capabilities
- The `sbom-example.json` is a reference SPDX 2.3 SBOM export (209 KB) — do not regenerate without asking
- Demo runbooks follow a specific timing/flow for live presentations — preserve their structure
- The repo targets `timothywarner-org` GitHub org (some scripts reference `warnertech/globomantics-robot-fleet`)
