mod fleet;
mod report;
mod telemetry;

use std::env;
use std::fs;
use std::process;

fn print_usage(program: &str) {
    eprintln!(
        "Globomantics Fleet Telemetry CLI v{}",
        env!("CARGO_PKG_VERSION")
    );
    eprintln!();
    eprintln!("Usage:");
    eprintln!("  {program} decode <telemetry.json>    Decode raw telemetry file");
    eprintln!("  {program} health <telemetry.json>    Run fleet health analysis");
    eprintln!("  {program} report <telemetry.json>    Generate fleet status report");
    eprintln!("  {program} sample                     Print sample telemetry JSON");
}

fn main() {
    let args: Vec<String> = env::args().collect();

    if args.len() < 2 {
        print_usage(&args[0]);
        process::exit(1);
    }

    let command = args[1].as_str();

    match command {
        "sample" => {
            let sample = telemetry::generate_sample_telemetry();
            match serde_json::to_string_pretty(&sample) {
                Ok(json) => println!("{json}"),
                Err(e) => {
                    eprintln!("Error serializing sample data: {e}");
                    process::exit(1);
                }
            }
        }
        "decode" | "health" | "report" => {
            if args.len() < 3 {
                eprintln!("Error: missing <telemetry.json> argument");
                print_usage(&args[0]);
                process::exit(1);
            }

            let file_path = &args[2];
            let content = match fs::read_to_string(file_path) {
                Ok(c) => c,
                Err(e) => {
                    eprintln!("Error reading file '{file_path}': {e}");
                    process::exit(1);
                }
            };

            let readings: Vec<telemetry::TelemetryReading> = match serde_json::from_str(&content)
            {
                Ok(r) => r,
                Err(e) => {
                    eprintln!("Error parsing telemetry JSON: {e}");
                    process::exit(1);
                }
            };

            match command {
                "decode" => {
                    println!("Decoded {} telemetry readings:\n", readings.len());
                    for reading in &readings {
                        telemetry::print_reading(reading);
                    }
                }
                "health" => {
                    let analysis = fleet::analyze_fleet_health(&readings);
                    fleet::print_health_analysis(&analysis);
                }
                "report" => {
                    let analysis = fleet::analyze_fleet_health(&readings);
                    let report_text = report::generate_text_report(&readings, &analysis);
                    println!("{report_text}");
                }
                _ => unreachable!(),
            }
        }
        _ => {
            eprintln!("Unknown command: {command}");
            print_usage(&args[0]);
            process::exit(1);
        }
    }
}
