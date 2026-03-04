# Project Guidelines

## Code Style

- Node/Express uses CommonJS `require` and lives in a single file; follow the existing style in [server.js](server.js).
- Views are standalone EJS pages (full HTML documents, no layout system); see [views/robots.ejs](views/robots.ejs). The legacy layout file is unused: [views/layout.ejs](views/layout.ejs).
- Client assets are simple vanilla JS/CSS; follow patterns in [public/js/app.js](public/js/app.js) and [public/css/style.css](public/css/style.css).

## Architecture

- Single Express server with in-memory mock data; no database layer. All routes, middleware, and data live in [server.js](server.js).
- Static assets served from `public/`, templates from `views/`; the server renders HTML and exposes JSON APIs for UI use.
- Separate Rust telemetry CLI lives under [rust-telemetry-cli/README.md](rust-telemetry-cli/README.md) and is independent of the Node app.

## Build and Test

- Install and run: `npm install`, then `npm start` (node server.js) or `npm run dev` (nodemon). See [README.md](README.md) and [package.json](package.json).
- There is no JS test suite; `npm test` exits with error by design. See [README.md](README.md).
- Rust CLI: `cargo build --release` and `cargo run -- sample` from the rust-telemetry-cli folder. See [rust-telemetry-cli/README.md](rust-telemetry-cli/README.md).

## Project Conventions

- Views are full-page EJS files and include their own `<head>`/`<body>`; do not assume shared layout. See [views/robots.ejs](views/robots.ejs).
- UI uses external CDNs (Bootstrap, Font Awesome) and custom CSS; keep those links consistent with [views/robots.ejs](views/robots.ejs) and [public/css/style.css](public/css/style.css).

## Integration Points

- External CDNs for Bootstrap/Font Awesome are referenced in EJS templates; CSS imports Google Fonts. See [views/robots.ejs](views/robots.ejs) and [public/css/style.css](public/css/style.css).
- API endpoints defined in [server.js](server.js) back the UI; keep routes and view data in sync.

## Security

- This repo is an intentional GHAS teaching demo with known vulnerable dependencies and insecure patterns. Do not fix or upgrade security issues unless explicitly asked. See [README.md](README.md), [package.json](package.json), and [server.js](server.js).
