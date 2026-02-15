use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TelemetryReading {
    pub robot_id: String,
    pub robot_name: String,
    pub timestamp: String,
    pub battery_level: f64,
    pub cpu_temp_celsius: f64,
    pub signal_strength_dbm: i32,
    pub status: RobotStatus,
    pub location: Location,
    pub task: Option<String>,
    pub error_codes: Vec<u32>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum RobotStatus {
    Active,
    Idle,
    Charging,
    Maintenance,
    Error,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Location {
    pub zone: String,
    pub x: f64,
    pub y: f64,
}

impl std::fmt::Display for RobotStatus {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            RobotStatus::Active => write!(f, "ACTIVE"),
            RobotStatus::Idle => write!(f, "IDLE"),
            RobotStatus::Charging => write!(f, "CHARGING"),
            RobotStatus::Maintenance => write!(f, "MAINTENANCE"),
            RobotStatus::Error => write!(f, "ERROR"),
        }
    }
}

pub fn print_reading(reading: &TelemetryReading) {
    println!("  Robot: {} ({})", reading.robot_name, reading.robot_id);
    println!("  Timestamp:  {}", reading.timestamp);
    println!("  Status:     {}", reading.status);
    println!("  Battery:    {:.1}%", reading.battery_level);
    println!("  CPU Temp:   {:.1}°C", reading.cpu_temp_celsius);
    println!("  Signal:     {} dBm", reading.signal_strength_dbm);
    println!(
        "  Location:   zone {} ({:.1}, {:.1})",
        reading.location.zone, reading.location.x, reading.location.y
    );

    if let Some(task) = &reading.task {
        println!("  Task:       {task}");
    }

    if !reading.error_codes.is_empty() {
        let codes: Vec<String> = reading.error_codes.iter().map(|c| format!("E{c:04}")).collect();
        println!("  Errors:     {}", codes.join(", "));
    }

    println!();
}

pub fn generate_sample_telemetry() -> Vec<TelemetryReading> {
    vec![
        TelemetryReading {
            robot_id: "RBT-001".into(),
            robot_name: "Atlas".into(),
            timestamp: "2025-06-15T10:30:00Z".into(),
            battery_level: 87.5,
            cpu_temp_celsius: 42.3,
            signal_strength_dbm: -45,
            status: RobotStatus::Active,
            location: Location {
                zone: "A1".into(),
                x: 12.5,
                y: 34.8,
            },
            task: Some("package_sorting".into()),
            error_codes: vec![],
        },
        TelemetryReading {
            robot_id: "RBT-002".into(),
            robot_name: "Bolt".into(),
            timestamp: "2025-06-15T10:30:00Z".into(),
            battery_level: 23.1,
            cpu_temp_celsius: 68.9,
            signal_strength_dbm: -72,
            status: RobotStatus::Charging,
            location: Location {
                zone: "C3".into(),
                x: 5.0,
                y: 10.2,
            },
            task: None,
            error_codes: vec![],
        },
        TelemetryReading {
            robot_id: "RBT-003".into(),
            robot_name: "Cog".into(),
            timestamp: "2025-06-15T10:30:00Z".into(),
            battery_level: 55.0,
            cpu_temp_celsius: 91.2,
            signal_strength_dbm: -88,
            status: RobotStatus::Error,
            location: Location {
                zone: "B2".into(),
                x: 22.1,
                y: 7.4,
            },
            task: Some("inventory_scan".into()),
            error_codes: vec![1012, 2048],
        },
    ]
}
