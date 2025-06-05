# Globomantics Robot Fleet Manager V2

**Internal LOB Application - Educational Demo**

This is a fictional internal business application for Globomantics Robotics Corporation's robot fleet management system. This application is designed for educational purposes to demonstrate GitHub Advanced Security features, specifically **Dependency Review** and **Dependabot**.

## ⚠️ IMPORTANT - Educational Use Only

This application contains **intentionally vulnerable dependencies** for security training purposes. **DO NOT use in production environments.**

## Vulnerable Dependencies (For Demo)

The following dependencies contain known vulnerabilities for demonstration purposes:

- `express` 4.17.1 - Contains various security vulnerabilities
- `lodash` 4.17.20 - Prototype pollution vulnerabilities
- `axios` 0.21.1 - Server-side request forgery vulnerabilities
- `ejs` 3.1.6 - Code injection vulnerabilities
- `moment` 2.29.1 - ReDoS vulnerabilities (also deprecated)

## Features

- **Dashboard**: Overview of robot fleet status
- **Fleet Management**: Individual robot monitoring and control
- **Maintenance Scheduling**: Track robots requiring service
- **Real-time Status Updates**: Battery levels, locations, and task assignments

## Quick Start

```bash
npm install
npm start
```

Visit `http://localhost:3000` to access the Globomantics Robot Fleet Manager.

## Demonstration Goals

This application demonstrates:
1. How dependency vulnerabilities appear in GitHub security alerts
2. Dependabot's automatic security updates
3. Dependency review process in pull requests
4. Security best practices for Node.js applications

---
*Globomantics Robotics Corporation - Internal Use Only*
