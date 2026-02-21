const express = require('express');
const bodyParser = require('body-parser');
const cookieParser = require('cookie-parser');
const session = require('express-session');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const { execSync } = require('child_process');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const _ = require('lodash');
const moment = require('moment');
const axios = require('axios');
const axios = require('axios');
const helmet = require('helmet');
const cors = require('cors');
const serialize = require('serialize-javascript');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware (minimal for demo purposes)
app.use(helmet({
    contentSecurityPolicy: false // Intentionally disabled for demo
}));
app.use(cors());

// Middleware
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(cookieParser());
app.use(session({
    secret: 'globomantics-secret-key', // Intentionally weak for demo
    resave: false,
    saveUninitialized: true,
    cookie: { secure: false } // Intentionally insecure for demo
}));

// Set view engine
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Static files
app.use(express.static(path.join(__dirname, 'public')));

// Mock database (in-memory for demo)
let robots = [
    {
        id: 1,
        name: 'Atlas-Prime',
        model: 'GX-2000',
        status: 'Active',
        location: 'Warehouse A',
        batteryLevel: 87,
        lastMaintenance: '2023-12-01',
        assignedTask: 'Package Sorting'
    },
    {
        id: 2,
        name: 'Beta-Unit',
        model: 'GX-1500',
        status: 'Maintenance',
        location: 'Service Bay 1',
        batteryLevel: 23,
        lastMaintenance: '2023-11-28',
        assignedTask: 'Under Repair'
    },
    {
        id: 3,
        name: 'Charlie-Loader',
        model: 'HL-3000',
        status: 'Active',
        location: 'Loading Dock B',
        batteryLevel: 95,
        lastMaintenance: '2023-12-03',
        assignedTask: 'Heavy Lifting'
    }
];

let users = [
    {
        id: 1,
        username: 'admin',
        password: '$2b$10$rOFLC.b8.TaEZQZlpJo.h.D8J8J1J.1J', // 'password123'
        role: 'Administrator'
    }
];

// Routes
app.get('/', (req, res) => {
    res.render('dashboard', {
        title: 'Globomantics Robot Fleet Manager',
        robots: robots,
        totalRobots: robots.length,
        activeRobots: robots.filter(r => r.status === 'Active').length,
        moment: moment
    });
});

app.get('/robots', (req, res) => {
    res.render('robots', {
        title: 'Robot Fleet - Globomantics',
        robots: robots,
        moment: moment
    });
});

app.get('/robot/:id', (req, res) => {
    const robotId = parseInt(req.params.id);
    const robot = robots.find(r => r.id === robotId);

    if (!robot) {
        return res.status(404).render('error', {
            title: 'Robot Not Found',
            message: 'The requested robot could not be found.'
        });
    }

    res.render('robot-detail', {
        title: `${robot.name} - Globomantics`,
        robot: robot,
        moment: moment
    });
});

app.post('/robot/:id/update', (req, res) => {
    const robotId = parseInt(req.params.id);
    const robot = robots.find(r => r.id === robotId);

    if (robot) {
        // Intentionally using unsafe merge for demo purposes
        _.merge(robot, req.body);
        res.redirect(`/robot/${robotId}`);
    } else {
        res.status(404).send('Robot not found');
    }
});

app.get('/maintenance', (req, res) => {
    const maintenanceRobots = robots.filter(r => r.status === 'Maintenance');
    res.render('maintenance', {
        title: 'Maintenance Schedule - Globomantics',
        robots: maintenanceRobots,
        moment: moment
    });
});

app.get('/api/robots', (req, res) => {
    res.json(robots);
});

// Intentionally vulnerable endpoint for demo
app.get('/api/export/:format', (req, res) => {
    const format = req.params.format;

    // Intentionally unsafe eval for demo purposes
    try {
        const exportFunction = eval(`(function() { return "Exporting data as ${format}"; })`);
        res.json({ message: exportFunction() });
    } catch (error) {
        res.status(400).json({ error: 'Invalid format' });
    }
});

// =====================================================================
// ADDITIONAL INTENTIONAL VULNERABILITIES (for Semgrep / CodeQL demos)
// These exist on purpose — do NOT fix unless specifically asked.
// =====================================================================

// --- Command Injection (CWE-78) ---
// Semgrep: javascript.lang.security.audit.child-process-injection
app.get('/api/diagnostics/:robotName', (req, res) => {
    const robotName = req.params.robotName;
    try {
        const result = execSync(`ping -c 1 ${robotName}.globomantics.local`);
        res.json({ output: result.toString() });
    } catch (error) {
        res.status(500).json({ error: 'Diagnostics failed' });
    }
});

// --- Path Traversal (CWE-22) ---
// Semgrep: javascript.lang.security.audit.path-traversal
app.get('/api/logs/:filename', (req, res) => {
    const filename = req.params.filename;
    const logPath = path.join(__dirname, 'logs', filename);
    res.sendFile(logPath);
});

// --- SSRF (CWE-918) ---
// Semgrep: javascript.lang.security.audit.request-ssrf

// Allow-list of robot health check endpoints. The query parameter selects a key here,
// rather than allowing arbitrary URLs to be requested.
const ALLOWED_HEALTH_ENDPOINTS = {
    // Example entries; adjust to match actual robot identifiers and URLs.
    robot1: 'http://robot1.internal/health',
    robot2: 'http://robot2.internal/health'
};

app.get('/api/robot-health', async (req, res) => {
    const targetKey = req.query.url;
    const endpoint = ALLOWED_HEALTH_ENDPOINTS[targetKey];

    if (!endpoint) {
        return res.status(400).json({ error: 'Invalid robot health endpoint' });
    }

    try {
        const response = await axios.get(endpoint);
        res.json(response.data);
    } catch (error) {
        res.status(502).json({ error: 'Health check failed' });
    }
});

// --- Hardcoded JWT Secret (CWE-798) ---
// Semgrep: javascript.lang.security.audit.hardcoded-jwt-secret
const JWT_SECRET = 'super-secret-globomantics-key-2024';

app.post('/api/auth/login', (req, res) => {
    const { username, password } = req.body;
    const user = users.find(u => u.username === username);
    if (user) {
        const token = jwt.sign(
            { userId: user.id, role: user.role },
            JWT_SECRET,
            { expiresIn: '24h' }
        );
        res.json({ token });
    } else {
        res.status(401).json({ error: 'Invalid credentials' });
    }
});

// --- SQL Injection Pattern (CWE-89) ---
// Semgrep: javascript.lang.security.audit.sqli
app.get('/api/search', (req, res) => {
    const query = req.query.q;
    // Intentionally unsafe string concatenation for demo
    const sql = "SELECT * FROM robots WHERE name LIKE '%" + query + "%'";
    // Mock response (no real DB) — the pattern is what scanners flag
    res.json({ query: sql, results: robots.filter(r =>
        r.name.toLowerCase().includes((query || '').toLowerCase())
    )});
});

// --- NoSQL Injection Pattern (CWE-943) ---
// Semgrep: javascript.lang.security.audit.nosql-injection
app.post('/api/robots/find', (req, res) => {
    const filter = req.body;
    // Directly using user input as a query filter — NoSQL injection
    const results = robots.filter(r => {
        return Object.keys(filter).every(key => r[key] === filter[key]);
    });
    res.json(results);
});

// --- Regex DoS / ReDoS (CWE-1333) ---
// Semgrep: javascript.lang.security.audit.detect-regex-dos
app.post('/api/validate-serial', (req, res) => {
    const serial = req.body.serial;
    // Vulnerable regex — catastrophic backtracking
    const pattern = /^(([a-z])+.)+[A-Z]([a-z])+$/;
    const isValid = pattern.test(serial);
    res.json({ serial, valid: isValid });
});

// --- Insecure Randomness (CWE-330) ---
// Semgrep: javascript.lang.security.audit.insecure-random
app.get('/api/token/generate', (req, res) => {
    // Math.random() is not cryptographically secure
    const token = Math.random().toString(36).substring(2) +
                  Math.random().toString(36).substring(2);
    res.json({ resetToken: token });
});

// --- XSS via innerHTML Pattern (CWE-79) ---
// Semgrep: javascript.browser.security.audit.innerHTML
app.get('/api/robot-label/:id', (req, res) => {
    const robotId = parseInt(req.params.id);
    const robot = robots.find(r => r.id === robotId);
    const name = req.query.customName || (robot ? robot.name : 'Unknown');
    // Reflected user input in HTML response — XSS
    res.send(`<html><body><h1>Robot: ${name}</h1><p>Status: ${robot ? robot.status : 'N/A'}</p></body></html>`);
});

// --- Deserialization / Unsafe Serialize (CWE-502) ---
app.get('/api/config/export', (req, res) => {
    const config = {
        robots: robots,
        generatedAt: new Date(),
        version: '2.0.0'
    };
    // serialize-javascript with unsafe option
    const serialized = serialize(config, { unsafe: true });
    res.type('application/javascript').send(`window.__CONFIG__ = ${serialized}`);
});

// --- Weak Crypto (CWE-327) ---
// Semgrep: javascript.lang.security.audit.weak-crypto
app.post('/api/robot/verify', (req, res) => {
    const { robotId, checksum } = req.body;
    // MD5 is cryptographically broken
    const hash = crypto.createHash('md5').update(String(robotId)).digest('hex');
    res.json({ match: hash === checksum, hash });
});

// --- Open Redirect (CWE-601) ---
// Semgrep: javascript.lang.security.audit.open-redirect
app.get('/redirect', (req, res) => {
    const target = req.query.url;
    res.redirect(target);
});

// --- Prototype Pollution via Object.assign (CWE-1321) ---
app.post('/api/robot/:id/settings', (req, res) => {
    const robotId = parseInt(req.params.id);
    const robot = robots.find(r => r.id === robotId);
    if (robot) {
        // Prototype pollution via Object.assign with user input
        const settings = Object.assign({}, robot, req.body);
        res.json(settings);
    } else {
        res.status(404).json({ error: 'Robot not found' });
    }
});

// --- Hardcoded API Credentials (CWE-798) ---
const TELEMETRY_API_KEY = 'sk-globo-prod-4f8a2b1c9d3e7f6a5b4c3d2e1f0a9b8c';
const DATABASE_PASSWORD = 'Gl0bomantics_Pr0d_2024!';
const AWS_ACCESS_KEY = 'AKIAIOSFODNN7GLOBOMAN';

app.get('/api/telemetry/config', (req, res) => {
    res.json({
        endpoint: 'https://telemetry.globomantics.com/v2',
        apiKey: TELEMETRY_API_KEY,
        region: 'us-east-1'
    });
});

app.listen(PORT, () => {
    console.log(`🤖 Globomantics Robot Fleet Manager running on http://localhost:${PORT}`);
    console.log('📊 Internal LOB Application - Authorized Personnel Only');
});
