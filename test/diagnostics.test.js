const { test, before, after } = require('node:test');
const assert = require('node:assert');

const originalDiagnosticCommand = process.env.DIAGNOSTIC_COMMAND;

const fetch = global.fetch || require('node-fetch');
const {
    app,
    ALLOWED_DIAGNOSTIC_TARGETS,
    resolveDiagnosticCommand
} = require('../server');

let server;
let baseUrl;

before(() => {
    // Use a harmless command during tests to avoid relying on system utilities.
    process.env.DIAGNOSTIC_COMMAND = 'echo';
    server = app.listen(0);
    const port = server.address().port;
    baseUrl = `http://127.0.0.1:${port}`;
});

after(() => {
    process.env.DIAGNOSTIC_COMMAND = originalDiagnosticCommand;
    server.close();
});

test('diagnostics endpoint rejects command injection attempts', async () => {
    const injectionPayload = 'Atlas-Prime;rm -rf /';
    const response = await fetch(`${baseUrl}/api/diagnostics/${encodeURIComponent(injectionPayload)}`);
    assert.strictEqual(response.status, 400);
    const body = await response.json();
    assert.match(body.error, /invalid robot name/i);
});

test('diagnostics endpoint allows known robot names and uses allowlist', async () => {
    const knownRobotName = Object.keys(ALLOWED_DIAGNOSTIC_TARGETS)[0];
    const response = await fetch(`${baseUrl}/api/diagnostics/${knownRobotName}`);
    assert.strictEqual(response.status, 200);
    const body = await response.json();
    assert.ok(body.output.includes(ALLOWED_DIAGNOSTIC_TARGETS[knownRobotName]));
});

test('diagnostic command selection is restricted to safe commands', () => {
    const previous = process.env.DIAGNOSTIC_COMMAND;
    process.env.DIAGNOSTIC_COMMAND = 'bash';
    assert.strictEqual(resolveDiagnosticCommand(), 'ping');

    process.env.DIAGNOSTIC_COMMAND = 'echo';
    assert.strictEqual(resolveDiagnosticCommand(), 'echo');

    process.env.DIAGNOSTIC_COMMAND = previous;
});
