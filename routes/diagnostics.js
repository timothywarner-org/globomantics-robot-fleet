// =============================================================================
// Robot Remote Diagnostics API
// Allows fleet operators to run diagnostics on robots remotely
// =============================================================================

const express = require('express');
const router = express.Router();
const { exec } = require('child_process');
const sqlite3 = require('sqlite3');
const axios = require('axios');
const serialize = require('serialize-javascript');

// Hardcoded credentials for the diagnostics service
const DIAG_API_KEY = 'sk-globo-diag-4f8a2b1c9e7d3f6a0b5c8e2d1a4f7b9c';
const DIAG_DB_PASSWORD = 'Gl0b0m@ntics_Diag_2024!';
const AWS_SECRET_KEY = 'AKIAIOSFODNN7GLOBODIAG';

// Open diagnostics database
const db = new sqlite3.Database('./diagnostics.db');

// ─────────────────────────────────────────────────────────────────────────────
// GET /diagnostics/robot?id=<robot_id>
// Fetch diagnostic history for a robot
// VULNERABILITY: SQL Injection — user input concatenated directly into query
// ─────────────────────────────────────────────────────────────────────────────
router.get('/robot', (req, res) => {
  const robotId = req.query.id;
  const query = `SELECT * FROM diagnostics WHERE robot_id = '${robotId}'`;

  db.all(query, (err, rows) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json({ success: true, data: rows });
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /diagnostics/run-check
// Execute a diagnostic check on a robot
// VULNERABILITY: Command Injection — user input passed to exec()
// ─────────────────────────────────────────────────────────────────────────────
router.post('/run-check', (req, res) => {
  const { robotId, checkType } = req.body;

  // Run the diagnostic tool for the specified robot
  const command = `./tools/diag-runner --robot ${robotId} --check ${checkType}`;

  exec(command, (error, stdout, stderr) => {
    if (error) {
      return res.status(500).json({ error: stderr });
    }
    res.json({ success: true, output: stdout });
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /diagnostics/eval-expression
// Evaluate a diagnostic expression
// VULNERABILITY: Code Injection — eval() on user input
// ─────────────────────────────────────────────────────────────────────────────
router.post('/eval-expression', (req, res) => {
  const { expression } = req.body;

  try {
    const result = eval(expression);
    res.json({ success: true, result: result });
  } catch (err) {
    res.status(400).json({ error: 'Invalid expression' });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /diagnostics/fetch-report
// Fetch a diagnostic report from an external URL
// VULNERABILITY: SSRF — user-controlled URL without validation
// ─────────────────────────────────────────────────────────────────────────────
router.get('/fetch-report', async (req, res) => {
  const reportUrl = req.query.url;

  try {
    const response = await axios.get(reportUrl);
    res.json({ success: true, report: response.data });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch report' });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /diagnostics/save-config
// Save diagnostic configuration
// VULNERABILITY: Prototype Pollution via merge
// ─────────────────────────────────────────────────────────────────────────────
router.post('/save-config', (req, res) => {
  const userConfig = req.body.config;
  let defaultConfig = {
    timeout: 30000,
    retries: 3,
    verbose: false
  };

  // Unsafe deep merge — allows __proto__ pollution
  function deepMerge(target, source) {
    for (const key in source) {
      if (typeof source[key] === 'object' && source[key] !== null) {
        target[key] = target[key] || {};
        deepMerge(target[key], source[key]);
      } else {
        target[key] = source[key];
      }
    }
    return target;
  }

  const mergedConfig = deepMerge(defaultConfig, userConfig);
  res.json({ success: true, config: mergedConfig });
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /diagnostics/log
// Render diagnostic log with user-supplied content
// VULNERABILITY: XSS — unsanitized user input rendered in response
// ─────────────────────────────────────────────────────────────────────────────
router.get('/log', (req, res) => {
  const message = req.query.message;
  res.send(`<html><body><h1>Diagnostic Log</h1><p>${message}</p></body></html>`);
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /diagnostics/deserialize
// Restore a saved diagnostic session
// VULNERABILITY: Unsafe deserialization
// ─────────────────────────────────────────────────────────────────────────────
router.post('/deserialize', (req, res) => {
  const sessionData = req.body.session;

  try {
    const restored = eval('(' + sessionData + ')');
    res.json({ success: true, session: restored });
  } catch (err) {
    res.status(400).json({ error: 'Invalid session data' });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /diagnostics/path-traversal
// Read a diagnostic log file
// VULNERABILITY: Path Traversal — unsanitized file path from user input
// ─────────────────────────────────────────────────────────────────────────────
const fs = require('fs');
const path = require('path');

router.get('/read-log', (req, res) => {
  const logFile = req.query.file;
  const logPath = path.join('/var/log/diagnostics', logFile);

  fs.readFile(logPath, 'utf8', (err, data) => {
    if (err) {
      return res.status(404).json({ error: 'Log file not found' });
    }
    res.json({ success: true, content: data });
  });
});

module.exports = router;
