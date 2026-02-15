# Fleet Telemetry CLI

Rust CLI utility for decoding robot telemetry data, analyzing fleet health, and generating status reports for the Globomantics Robot Fleet.

## Purpose

This utility supplements the main Node.js fleet manager by providing a standalone Rust binary for telemetry analysis. It also serves as a multi-language scanning target for demonstrating **Semgrep** and **CodeQL** code scanning workflows alongside the existing JavaScript codebase.

## Build

Requires [Rust](https://rustup.rs/) (1.70+ recommended).

```bash
cd rust-telemetry-cli
cargo build --release
```

The binary is output to `target/release/fleet-telemetry-cli` (or `.exe` on Windows).

## Usage

```bash
# Generate sample telemetry JSON
fleet-telemetry-cli sample > telemetry.json

# Decode and display telemetry readings
fleet-telemetry-cli decode telemetry.json

# Run fleet health analysis with alerts
fleet-telemetry-cli health telemetry.json

# Generate a formatted status report
fleet-telemetry-cli report telemetry.json
```

## Telemetry JSON Format

Each reading in the JSON array contains:

| Field                | Type     | Description                                    |
|----------------------|----------|------------------------------------------------|
| `robot_id`           | string   | Unique robot identifier (e.g. `RBT-001`)       |
| `robot_name`         | string   | Human-readable name                            |
| `timestamp`          | string   | ISO 8601 timestamp                             |
| `battery_level`      | float    | Battery percentage (0-100)                     |
| `cpu_temp_celsius`   | float    | CPU temperature in Celsius                     |
| `signal_strength_dbm`| integer  | Signal strength in dBm (negative)              |
| `status`             | enum     | `active`, `idle`, `charging`, `maintenance`, `error` |
| `location`           | object   | `{ zone, x, y }` coordinates                  |
| `task`               | string?  | Current task assignment (nullable)             |
| `error_codes`        | array    | Active error codes (empty if none)             |

## Health Analysis Thresholds

| Metric       | Warning     | Critical    |
|--------------|-------------|-------------|
| Battery      | < 20%       | < 10%       |
| CPU Temp     | > 75 C      | > 90 C      |
| Signal       | < -80 dBm   | --          |
| Status       | --          | `error`     |

## Project Structure

```
rust-telemetry-cli/
  Cargo.toml          # Dependencies: serde, serde_json
  src/
    main.rs           # CLI entry point and argument routing
    telemetry.rs      # Data structures, JSON (de)serialization, sample data
    fleet.rs          # Health analysis engine and alert generation
    report.rs         # Formatted text report output
```

## Dependencies

- `serde` + `serde_json` -- JSON serialization/deserialization
