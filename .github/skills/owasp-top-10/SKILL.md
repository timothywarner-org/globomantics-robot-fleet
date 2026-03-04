---
name: owasp-top-10
description: Reference knowledge for the OWASP Top 10 (2021) web application security risks. Use when scanning code for vulnerabilities, reviewing security posture, classifying findings by severity, or providing remediation guidance aligned with OWASP standards.
---

# OWASP Top 10 (2021) Security Reference

Use this skill when analyzing code for security vulnerabilities, classifying security findings, or recommending remediations. Map every finding to the relevant OWASP category and CWE identifier.

## A01:2021 - Broken Access Control

**CWEs**: CWE-200, CWE-201, CWE-352, CWE-639, CWE-862, CWE-863

Access control enforces policy so users cannot act outside their intended permissions.

### What to look for

- Missing authorization checks on routes or API endpoints
- IDOR (Insecure Direct Object References) — user-controlled IDs without ownership validation
- CORS misconfigurations allowing unauthorized origins
- Missing CSRF protection on state-changing operations
- Privilege escalation via parameter tampering (e.g., `role=admin` in request body)
- Directory traversal in file access paths

### Secure patterns

```javascript
// Verify ownership before returning data
app.get('/api/orders/:id', authenticate, async (req, res) => {
  const order = await Order.findById(req.params.id)
  if (!order || order.userId !== req.user.id) {
    return res.status(404).json({ error: 'Not found' })
  }
  res.json(order)
})
```

```javascript
// Deny by default — explicit allowlist
const ALLOWED_ROLES = ['admin', 'manager']
function requireRole(...roles) {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ error: 'Forbidden' })
    }
    next()
  }
}
```

---

## A02:2021 - Cryptographic Failures

**CWEs**: CWE-259, CWE-327, CWE-328, CWE-331, CWE-916

Failures related to cryptography that expose sensitive data.

### What to look for

- Hardcoded secrets, API keys, or passwords in source code
- Weak hashing algorithms (MD5, SHA1) used for passwords or security
- Data transmitted over HTTP instead of HTTPS
- Missing encryption for sensitive data at rest
- Predictable random values used for tokens or session IDs
- Sensitive data in URL query parameters or logs

### Secure patterns

```javascript
// Use bcrypt for password hashing (not MD5/SHA1)
const bcrypt = require('bcrypt')
const SALT_ROUNDS = 12
const hash = await bcrypt.hash(password, SALT_ROUNDS)
const isValid = await bcrypt.compare(password, hash)
```

```javascript
// Use crypto.randomBytes for secure tokens
const crypto = require('crypto')
const token = crypto.randomBytes(32).toString('hex')
```

```javascript
// Load secrets from environment, never hardcode
const apiKey = process.env.API_KEY
if (!apiKey) {
  throw new Error('API_KEY environment variable is required')
}
```

---

## A03:2021 - Injection

**CWEs**: CWE-20, CWE-74, CWE-75, CWE-77, CWE-78, CWE-79, CWE-89, CWE-94, CWE-116

Untrusted data sent to an interpreter as part of a command or query.

### What to look for

- SQL queries built with string concatenation or template literals
- `eval()`, `Function()`, or `vm.runInNewContext()` with user input
- `child_process.exec()` with unsanitized input (command injection)
- Template injection in server-side rendering engines
- LDAP, XPath, or NoSQL injection vectors
- `_.merge()`, `Object.assign()`, or spread on unvalidated user input (prototype pollution)

### Secure patterns

```javascript
// Parameterized queries — never concatenate SQL
const result = await db.query(
  'SELECT * FROM users WHERE email = $1',
  [req.body.email]
)
```

```javascript
// Use allowlists instead of eval for dynamic behavior
const ALLOWED_FORMATS = {
  json: (data) => JSON.stringify(data),
  csv: (data) => convertToCsv(data),
}
const formatter = ALLOWED_FORMATS[req.query.format]
if (!formatter) {
  return res.status(400).json({ error: 'Invalid format' })
}
res.send(formatter(data))
```

```javascript
// Use execFile (not exec) to prevent command injection
const { execFile } = require('child_process')
execFile('ls', ['-la', sanitizedPath], callback)
```

---

## A04:2021 - Insecure Design

**CWEs**: CWE-209, CWE-256, CWE-501, CWE-522

Security flaws from missing or ineffective control design, not implementation bugs.

### What to look for

- No rate limiting on authentication or sensitive endpoints
- Missing account lockout after failed login attempts
- Business logic flaws (e.g., negative quantities, price manipulation)
- Lack of input length limits on text fields
- Missing re-authentication for sensitive operations
- No separation between user tiers or trust levels

### Secure patterns

```javascript
// Rate limiting on login endpoint
const rateLimit = require('express-rate-limit')
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: { error: 'Too many login attempts. Try again in 15 minutes.' },
})
app.post('/login', loginLimiter, loginHandler)
```

---

## A05:2021 - Security Misconfiguration

**CWEs**: CWE-2, CWE-11, CWE-13, CWE-15, CWE-16, CWE-388

Insecure default configurations, incomplete setups, or overly permissive settings.

### What to look for

- Default credentials or unchanged secret keys
- Verbose error messages exposing stack traces or internal paths
- Unnecessary HTTP methods enabled (TRACE, OPTIONS)
- Missing or misconfigured security headers (CSP, HSTS, X-Frame-Options)
- Directory listing enabled on web servers
- Debug mode or development settings in production
- Overly permissive CORS (`Access-Control-Allow-Origin: *`)

### Secure patterns

```javascript
// Helmet with strict configuration
const helmet = require('helmet')
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:"],
    },
  },
  hsts: { maxAge: 31536000, includeSubDomains: true },
}))
```

```javascript
// Production error handler — no stack traces
app.use((err, req, res, next) => {
  console.error(err.stack)
  res.status(500).json({ error: 'Internal server error' })
})
```

---

## A06:2021 - Vulnerable and Outdated Components

**CWEs**: CWE-1035, CWE-1104

Using components with known vulnerabilities or that are no longer maintained.

### What to look for

- Dependencies with known CVEs (`npm audit`)
- Outdated packages with available security patches (`npm outdated`)
- Abandoned packages with no recent maintenance
- Transitive dependencies pulling in vulnerable versions
- Missing lock file (`package-lock.json`) allowing version drift
- No automated dependency update process (Dependabot, Renovate)

### Detection commands

```bash
npm audit                    # Check for known vulnerabilities
npm audit --json             # Machine-readable output
npm outdated                 # List outdated packages
npx npm-check-updates        # Show available updates
```

### Secure patterns

- Pin dependency versions in `package.json`
- Use `package-lock.json` and commit it to the repository
- Configure Dependabot or Renovate for automated PRs
- Run `npm audit` in CI/CD pipelines and fail on HIGH/CRITICAL
- Review transitive dependencies, not just direct ones

---

## A07:2021 - Identification and Authentication Failures

**CWEs**: CWE-255, CWE-287, CWE-384, CWE-798

Weaknesses in confirming user identity, authentication, and session management.

### What to look for

- Weak password policies (no minimum length, complexity, or breach checks)
- Session tokens in URLs or exposed in logs
- Missing session expiration or rotation after login
- Insecure cookie settings (missing `httpOnly`, `secure`, `sameSite`)
- Credentials sent over unencrypted connections
- Hardcoded credentials in source code

### Secure patterns

```javascript
// Secure session configuration
app.use(session({
  secret: process.env.SESSION_SECRET,
  name: '__Host-sid',
  resave: false,
  saveUninitialized: false,
  cookie: {
    httpOnly: true,
    secure: true,
    sameSite: 'strict',
    maxAge: 1800000, // 30 minutes
  },
}))
```

```javascript
// Regenerate session ID after login to prevent fixation
req.session.regenerate((err) => {
  if (err) return next(err)
  req.session.userId = user.id
  res.redirect('/dashboard')
})
```

---

## A08:2021 - Software and Data Integrity Failures

**CWEs**: CWE-345, CWE-353, CWE-426, CWE-494, CWE-502, CWE-565, CWE-829

Code and infrastructure that does not protect against integrity violations.

### What to look for

- Deserialization of untrusted data (`JSON.parse` on user input without validation)
- CI/CD pipelines without integrity verification
- Auto-update mechanisms without signature verification
- CDN resources loaded without Subresource Integrity (SRI) hashes
- Unsigned or unverified JWT tokens
- GitHub Actions using mutable tags instead of pinned SHAs

### Secure patterns

```html
<!-- Subresource Integrity for CDN scripts -->
<script
  src="https://cdn.example.com/lib.min.js"
  integrity="sha384-abc123..."
  crossorigin="anonymous">
</script>
```

```javascript
// Validate deserialized data with a schema
const { z } = require('zod')
const UserInput = z.object({
  name: z.string().min(1).max(100),
  email: z.string().email(),
})
const validated = UserInput.parse(JSON.parse(req.body.data))
```

---

## A09:2021 - Security Logging and Monitoring Failures

**CWEs**: CWE-117, CWE-223, CWE-532, CWE-778

Insufficient logging, detection, monitoring, and active response.

### What to look for

- No logging of authentication events (login, logout, failed attempts)
- Sensitive data written to logs (passwords, tokens, PII)
- No log integrity protection (logs can be tampered with)
- Missing alerting on suspicious patterns (brute force, privilege escalation)
- Logs not centralized or monitored
- No audit trail for administrative actions

### Secure patterns

```javascript
// Log security events without sensitive data
function logSecurityEvent(event, details) {
  console.log(JSON.stringify({
    timestamp: new Date().toISOString(),
    event,
    userId: details.userId,
    ip: details.ip,
    userAgent: details.userAgent,
    // Never log passwords, tokens, or session IDs
  }))
}

logSecurityEvent('LOGIN_FAILED', {
  userId: req.body.username,
  ip: req.ip,
  userAgent: req.get('User-Agent'),
})
```

---

## A10:2021 - Server-Side Request Forgery (SSRF)

**CWEs**: CWE-918

The application fetches a remote resource using a user-supplied URL without validation.

### What to look for

- User-supplied URLs passed directly to `fetch()`, `axios()`, or `http.get()`
- URL parameters used to load internal resources
- Redirect following without origin validation
- Webhook URLs that can target internal services
- Image/file processing from user-supplied URLs

### Secure patterns

```javascript
const { URL } = require('url')

function validateExternalUrl(input) {
  const parsed = new URL(input)
  // Block private/internal ranges
  const BLOCKED = ['localhost', '127.0.0.1', '0.0.0.0', '169.254.169.254']
  if (BLOCKED.includes(parsed.hostname)) {
    throw new Error('Internal URLs are not allowed')
  }
  if (parsed.protocol !== 'https:') {
    throw new Error('Only HTTPS URLs are allowed')
  }
  // Block private IP ranges
  if (/^(10\.|172\.(1[6-9]|2\d|3[01])\.|192\.168\.)/.test(parsed.hostname)) {
    throw new Error('Private IP ranges are not allowed')
  }
  return parsed.href
}
```

---

## Severity Classification Guide

When reporting findings, use this severity mapping:

| Severity | Criteria | Examples |
| -------- | -------- | -------- |
| CRITICAL | Exploitable remotely, no authentication required, high impact | RCE via eval injection, SQL injection on auth endpoint |
| HIGH | Exploitable with some conditions, significant impact | Stored XSS, SSRF to internal services, broken access control |
| MEDIUM | Requires specific conditions or authenticated access | Reflected XSS, missing rate limiting, weak session config |
| LOW | Limited impact or difficult to exploit | Missing security headers, verbose errors, outdated non-critical deps |
| INFO | Best practice recommendations, no direct vulnerability | Missing SRI hashes, logging improvements, dependency hygiene |
