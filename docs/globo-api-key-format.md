# Globomantics Robotics API Key Format

Custom API key specification for the Globomantics Robot Fleet Management Platform. This document defines the key format, provides a Hyperscan-compatible regex for GitHub Advanced Security (GHAS) custom secret scanning patterns, and includes example keys for testing.

---

## Key Anatomy

A Globomantics Robotics API key consists of four segments separated by underscores:

```text
glbrt_prod_9f3a2c7e1b4d8a6f0e5c9b2d7a1f4e8c3b6d0a9e_G7k2
|     |    |                                        |
|     |    |                                        +-- Checksum (4 alphanumeric chars)
|     |    +-- Key Body (40 lowercase hex chars)
|     +-- Environment (prod | stg | dev)
+-- Prefix (always "glbrt")
```

### Segment Breakdown

| Segment     | Length | Characters     | Description                                                                                    |
|-------------|--------|----------------|------------------------------------------------------------------------------------------------|
| Prefix      | 5      | `glbrt`        | Fixed identifier for Globomantics Robotics. Analogous to `AKIA` (AWS) or `sk_live` (Stripe).  |
| Environment | 3-4    | `prod` `stg` `dev` | Deployment environment the key is authorized for.                                         |
| Key Body    | 40     | `[a-f0-9]`    | 160-bit cryptographic random value encoded as lowercase hexadecimal.                           |
| Checksum    | 4      | `[A-Za-z0-9]` | CRC-derived integrity check to detect transcription errors.                                    |

> **Note:** Segments are separated by underscore (`_`) delimiters. Total key length is 55-56 characters (`dev` = 55, `stg` = 55, `prod` = 56).

### Why This Format

- **Prefix `glbrt_`** makes keys immediately identifiable in logs, config files, and code reviews.
- **Environment segment** prevents accidental production usage with a development key (and vice versa).
- **40-character hex body** provides 160 bits of entropy, sufficient for API authentication.
- **Checksum suffix** reduces false positives in secret scanning and catches copy-paste truncation errors.

---

## Hyperscan Regex for GHAS Custom Pattern

Use the following regex when creating a custom secret scanning pattern in GitHub Advanced Security. Navigate to **Settings > Code security and analysis > Secret scanning > Custom patterns > New pattern**.

### Secret Pattern (Required)

```regex
glbrt_(prod|stg|dev)_[a-f0-9]{40}_[A-Za-z0-9]{4}
```

### Regex Breakdown

| Component            | Matches                                                       |
|----------------------|---------------------------------------------------------------|
| `glbrt_`             | Literal prefix identifying a Globomantics Robotics key.       |
| `(prod\|stg\|dev)`  | Environment: production, staging, or development.             |
| `_`                  | Underscore separator.                                         |
| `[a-f0-9]{40}`      | Exactly 40 lowercase hexadecimal characters (the key body).   |
| `_`                  | Underscore separator.                                         |
| `[A-Za-z0-9]{4}`    | Exactly 4 alphanumeric characters (the checksum).             |

### GHAS Custom Pattern Configuration

When entering this in the GitHub UI:

| Field               | Value                                                                          |
|---------------------|--------------------------------------------------------------------------------|
| **Pattern name**    | Globomantics Robotics API Key                                                  |
| **Secret format**   | `glbrt_(prod\|stg\|dev)_[a-f0-9]{40}_[A-Za-z0-9]{4}`                          |
| **Before secret**   | *(leave empty, or use `[^a-zA-Z0-9]` to anchor on a word boundary)*           |
| **After secret**    | *(leave empty, or use `[^a-zA-Z0-9]` to anchor on a word boundary)*           |
| **Test string**     | `glbrt_prod_9f3a2c7e1b4d8a6f0e5c9b2d7a1f4e8c3b6d0a9e_G7k2`                   |

### Notes on Hyperscan Compatibility

- GHAS uses [Intel Hyperscan](https://www.intel.com/content/www/us/en/developer/articles/technical/introduction-to-hyperscan.html) as its regex engine.
- Hyperscan supports PCRE-like syntax but restricts backreferences and lookbehinds with unbounded repetition.
- The pattern above uses only basic alternation, character classes, and fixed quantifiers -- all fully supported.

---

## Example Keys

The following keys are **fake examples for testing only**. They follow the correct format and will match the regex above.

### Production Key

```text
glbrt_prod_9f3a2c7e1b4d8a6f0e5c9b2d7a1f4e8c3b6d0a9e_G7k2
```

**Use case:** Robot Fleet Command and Control API in the production environment.

### Staging Key

```text
glbrt_stg_4b8e1d6a3f9c7025e8d1a4b7f3c6e9d2a5b8f1c4_Xm9p
```

**Use case:** Telemetry ingestion endpoint in the pre-production staging environment.

### Development Key

```text
glbrt_dev_a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0_Tn3q
```

**Use case:** Local development and integration testing against the sandbox fleet API.

### Quick Validation

To verify these examples match the regex, use any PCRE-compatible tool:

```bash
echo "glbrt_prod_9f3a2c7e1b4d8a6f0e5c9b2d7a1f4e8c3b6d0a9e_G7k2" | grep -P "glbrt_(prod|stg|dev)_[a-f0-9]{40}_[A-Za-z0-9]{4}"
```

Or test directly in the GHAS custom pattern UI using the "Test string" field.

---

## Usage Context

Globomantics Robotics API keys authenticate requests to three core platform services:

### 1. Robot Fleet Command and Control API

- **Base URL**: `https://api.globomantics.com/v2/fleet`
- **Purpose**: Issue commands to robots (start, stop, reposition), retrieve robot status, and manage fleet assignments.
- **Authentication**: Pass the key in the `X-Globo-Api-Key` header.
- **Environment enforcement**: Production keys are rejected by staging and development endpoints (and vice versa).

```bash
curl -H "X-Globo-Api-Key: glbrt_prod_9f3a2c7e1b4d8a6f0e5c9b2d7a1f4e8c3b6d0a9e_G7k2" \
     https://api.globomantics.com/v2/fleet/robots
```

### 2. Telemetry Ingestion API

- **Base URL**: `https://telemetry.globomantics.com/v1/ingest`
- **Purpose**: Robots push sensor data (battery level, position, temperature, error codes) to the central telemetry service.
- **Authentication**: Embedded in the robot firmware configuration; transmitted via `Authorization: Bearer <key>`.

### 3. Maintenance Scheduling API

- **Base URL**: `https://api.globomantics.com/v2/maintenance`
- **Purpose**: Schedule preventive maintenance windows, report diagnostic results, and manage spare parts inventory.
- **Authentication**: Same `X-Globo-Api-Key` header pattern.

### Where Keys Appear (and Should Not)

| Location                         | Expected | Flagged by GHAS    |
|----------------------------------|----------|--------------------|
| Environment variables (`.env`)   | Yes      | No (not committed) |
| CI/CD secrets (GitHub Actions)   | Yes      | No (encrypted)     |
| Vault / secrets manager          | Yes      | No (external)      |
| Source code (hardcoded)          | **No**   | **Yes**            |
| Configuration files in repo      | **No**   | **Yes**            |
| Documentation / comments         | **No**   | **Yes**            |
| Commit messages                  | **No**   | **Yes**            |

---

## Rotation Policy

### Recommended Rotation Schedule

| Environment | Rotation Interval | Trigger Events                                               |
|-------------|-------------------|--------------------------------------------------------------|
| Production  | Every 90 days     | Personnel departure, suspected compromise, security incident |
| Staging     | Every 180 days    | Personnel departure, environment rebuild                     |
| Development | Every 365 days    | Personnel departure                                          |

### Rotation Procedure

1. **Generate** a new key through the [Globomantics Developer Portal](https://portal.globomantics.com/api-keys).
2. **Deploy** the new key to all consuming services before revoking the old key (zero-downtime rotation).
3. **Revoke** the old key through the Developer Portal.
4. **Verify** no services return 401/403 errors after revocation.
5. **Audit** the Git history and CI/CD logs to confirm the old key does not appear in any committed files. If it does, treat it as a compromised secret and follow the incident response process.

### Emergency Rotation (Compromised Key)

If GHAS secret scanning detects a Globomantics key in a repository:

1. **Immediately revoke** the detected key via the Developer Portal.
2. **Generate** a replacement key.
3. **Deploy** the replacement to all services.
4. **Review** audit logs for unauthorized usage during the exposure window.
5. **Remove** the secret from Git history using `git filter-repo` or BFG Repo-Cleaner.
6. **Force-push** the cleaned history and notify all contributors to re-clone.

---

## GHAS Integration Checklist

Use this checklist when setting up the custom pattern in your GitHub organization:

- [ ] Navigate to **Organization Settings > Code security and analysis > Secret scanning**
- [ ] Click **New pattern** under Custom patterns
- [ ] Enter pattern name: `Globomantics Robotics API Key`
- [ ] Enter secret format: `glbrt_(prod|stg|dev)_[a-f0-9]{40}_[A-Za-z0-9]{4}`
- [ ] Paste a test string to verify the pattern matches
- [ ] Optionally enable **Push protection** to block commits containing this key
- [ ] Save and enable the pattern
- [ ] Perform a dry run by committing a test key to a private repository
- [ ] Verify the alert appears in **Security > Secret scanning alerts**
- [ ] Delete the test commit and close the alert

---

*Globomantics Robotics Corporation -- Internal Engineering Documentation*
*Last updated: 2026-02-09*
