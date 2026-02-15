use crate::fleet::FleetHealthAnalysis;
use crate::telemetry::TelemetryReading;

pub fn generate_text_report(
    readings: &[TelemetryReading],
    analysis: &FleetHealthAnalysis,
) -> String {
    let mut lines: Vec<String> = Vec::new();

    lines.push("╔════════════════════════════════════════════╗".into());
    lines.push("║   GLOBOMANTICS FLEET STATUS REPORT         ║".into());
    lines.push("╚════════════════════════════════════════════╝".into());
    lines.push(String::new());

    lines.push(format!("Fleet Size: {} robots", analysis.total_robots));
    lines.push(format!(
        "Operational: {} | Down: {}",
        analysis.active_count + analysis.idle_count + analysis.charging_count,
        analysis.maintenance_count + analysis.error_count
    ));
    lines.push(String::new());

    lines.push("─── Robot Details ───".into());
    for reading in readings {
        let status_indicator = match reading.status {
            crate::telemetry::RobotStatus::Active => "[+]",
            crate::telemetry::RobotStatus::Idle => "[~]",
            crate::telemetry::RobotStatus::Charging => "[*]",
            crate::telemetry::RobotStatus::Maintenance => "[!]",
            crate::telemetry::RobotStatus::Error => "[X]",
        };

        lines.push(format!(
            "  {} {} ({}) — {} | Bat: {:.0}% | Temp: {:.0}°C",
            status_indicator,
            reading.robot_name,
            reading.robot_id,
            reading.status,
            reading.battery_level,
            reading.cpu_temp_celsius,
        ));

        if !reading.error_codes.is_empty() {
            let codes: Vec<String> = reading
                .error_codes
                .iter()
                .map(|c| format!("E{c:04}"))
                .collect();
            lines.push(format!("      Errors: {}", codes.join(", ")));
        }
    }
    lines.push(String::new());

    if !analysis.alerts.is_empty() {
        lines.push(format!("─── Alerts ({}) ───", analysis.alerts.len()));
        for alert in &analysis.alerts {
            lines.push(format!(
                "  [{}] {} — {}",
                alert.severity, alert.robot_id, alert.message
            ));
        }
        lines.push(String::new());
    }

    lines.push("─── Fleet Averages ───".into());
    lines.push(format!("  Battery:  {:.1}%", analysis.avg_battery));
    lines.push(format!("  CPU Temp: {:.1}°C", analysis.avg_cpu_temp));
    lines.push(format!("  Signal:   {:.1} dBm", analysis.avg_signal));

    lines.join("\n")
}
