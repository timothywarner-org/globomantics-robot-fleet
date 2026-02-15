use crate::telemetry::{RobotStatus, TelemetryReading};

#[derive(Debug)]
pub struct FleetHealthAnalysis {
    pub total_robots: usize,
    pub active_count: usize,
    pub idle_count: usize,
    pub charging_count: usize,
    pub maintenance_count: usize,
    pub error_count: usize,
    pub avg_battery: f64,
    pub avg_cpu_temp: f64,
    pub avg_signal: f64,
    pub alerts: Vec<HealthAlert>,
}

#[derive(Debug)]
pub struct HealthAlert {
    pub severity: AlertSeverity,
    pub robot_id: String,
    pub message: String,
}

#[derive(Debug)]
pub enum AlertSeverity {
    Warning,
    Critical,
}

impl std::fmt::Display for AlertSeverity {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            AlertSeverity::Warning => write!(f, "WARN"),
            AlertSeverity::Critical => write!(f, "CRIT"),
        }
    }
}

const BATTERY_LOW_THRESHOLD: f64 = 20.0;
const BATTERY_CRITICAL_THRESHOLD: f64 = 10.0;
const CPU_TEMP_WARN_THRESHOLD: f64 = 75.0;
const CPU_TEMP_CRITICAL_THRESHOLD: f64 = 90.0;
const SIGNAL_WEAK_THRESHOLD: i32 = -80;

pub fn analyze_fleet_health(readings: &[TelemetryReading]) -> FleetHealthAnalysis {
    let total_robots = readings.len();

    let active_count = readings
        .iter()
        .filter(|r| r.status == RobotStatus::Active)
        .count();
    let idle_count = readings
        .iter()
        .filter(|r| r.status == RobotStatus::Idle)
        .count();
    let charging_count = readings
        .iter()
        .filter(|r| r.status == RobotStatus::Charging)
        .count();
    let maintenance_count = readings
        .iter()
        .filter(|r| r.status == RobotStatus::Maintenance)
        .count();
    let error_count = readings
        .iter()
        .filter(|r| r.status == RobotStatus::Error)
        .count();

    let avg_battery = if total_robots > 0 {
        readings.iter().map(|r| r.battery_level).sum::<f64>() / total_robots as f64
    } else {
        0.0
    };

    let avg_cpu_temp = if total_robots > 0 {
        readings.iter().map(|r| r.cpu_temp_celsius).sum::<f64>() / total_robots as f64
    } else {
        0.0
    };

    let avg_signal = if total_robots > 0 {
        readings
            .iter()
            .map(|r| r.signal_strength_dbm as f64)
            .sum::<f64>()
            / total_robots as f64
    } else {
        0.0
    };

    let mut alerts = Vec::new();

    for reading in readings {
        if reading.battery_level < BATTERY_CRITICAL_THRESHOLD {
            alerts.push(HealthAlert {
                severity: AlertSeverity::Critical,
                robot_id: reading.robot_id.clone(),
                message: format!("Battery critically low: {:.1}%", reading.battery_level),
            });
        } else if reading.battery_level < BATTERY_LOW_THRESHOLD {
            alerts.push(HealthAlert {
                severity: AlertSeverity::Warning,
                robot_id: reading.robot_id.clone(),
                message: format!("Battery low: {:.1}%", reading.battery_level),
            });
        }

        if reading.cpu_temp_celsius > CPU_TEMP_CRITICAL_THRESHOLD {
            alerts.push(HealthAlert {
                severity: AlertSeverity::Critical,
                robot_id: reading.robot_id.clone(),
                message: format!("CPU overheating: {:.1}°C", reading.cpu_temp_celsius),
            });
        } else if reading.cpu_temp_celsius > CPU_TEMP_WARN_THRESHOLD {
            alerts.push(HealthAlert {
                severity: AlertSeverity::Warning,
                robot_id: reading.robot_id.clone(),
                message: format!("CPU temp elevated: {:.1}°C", reading.cpu_temp_celsius),
            });
        }

        if reading.signal_strength_dbm < SIGNAL_WEAK_THRESHOLD {
            alerts.push(HealthAlert {
                severity: AlertSeverity::Warning,
                robot_id: reading.robot_id.clone(),
                message: format!("Weak signal: {} dBm", reading.signal_strength_dbm),
            });
        }

        if reading.status == RobotStatus::Error {
            alerts.push(HealthAlert {
                severity: AlertSeverity::Critical,
                robot_id: reading.robot_id.clone(),
                message: format!(
                    "Robot in error state with {} error code(s)",
                    reading.error_codes.len()
                ),
            });
        }
    }

    FleetHealthAnalysis {
        total_robots,
        active_count,
        idle_count,
        charging_count,
        maintenance_count,
        error_count,
        avg_battery,
        avg_cpu_temp,
        avg_signal,
        alerts,
    }
}

pub fn print_health_analysis(analysis: &FleetHealthAnalysis) {
    println!("=== Globomantics Fleet Health Analysis ===\n");
    println!("Fleet Size:    {} robots", analysis.total_robots);
    println!("  Active:      {}", analysis.active_count);
    println!("  Idle:        {}", analysis.idle_count);
    println!("  Charging:    {}", analysis.charging_count);
    println!("  Maintenance: {}", analysis.maintenance_count);
    println!("  Error:       {}", analysis.error_count);
    println!();
    println!("Averages:");
    println!("  Battery:     {:.1}%", analysis.avg_battery);
    println!("  CPU Temp:    {:.1}°C", analysis.avg_cpu_temp);
    println!("  Signal:      {:.1} dBm", analysis.avg_signal);
    println!();

    if analysis.alerts.is_empty() {
        println!("No alerts. Fleet is healthy.");
    } else {
        println!("Alerts ({}):", analysis.alerts.len());
        for alert in &analysis.alerts {
            println!(
                "  [{}] {} — {}",
                alert.severity, alert.robot_id, alert.message
            );
        }
    }
}
