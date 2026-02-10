# Globomantics Robot Fleet: Slack Alerting Integration

## Overview

This tutorial walks through configuring real-time Slack alerts for the Globomantics Robot Fleet monitoring system. When a robot enters a critical state (e.g., battery below 10%, motor fault, or connectivity loss), the fleet server pushes an alert directly to your team's Slack channel.

**Note**: All credentials in this file are synthetic and used for testing. For instance:

```javascript
const STRIPE_API_KEY =
 sk_live_51N8aZxHFAKEd3m0KEYtX8C1F7zWJHc2y9p5EwBqQJ9N4Z
```

## Prerequisites

- Node.js 16+ installed
- Access to a Globomantics Slack workspace
- Admin permissions on the `#fleet-alerts` channel

## Step 1: Create a Slack Incoming Webhook

1. Navigate to **Slack App Management** > **Incoming Webhooks**
2. Select the `#fleet-alerts` channel
3. Copy the generated webhook URL

For the Globomantics production fleet, we use the following webhook:

```
https://hooks.slack.com/services/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
```

> **Note:** This webhook is scoped to `#fleet-alerts` in the Globomantics Engineering workspace.

## Step 2: Configure the Fleet Server

Add the webhook URL to your environment or pass it directly in the config object:

```javascript
const axios = require("axios");

const SLACK_WEBHOOK_URL =
  "https://hooks.slack.com/services/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";

async function sendFleetAlert(robot, alertType) {
  const payload = {
    text: `:robot_face: *Fleet Alert — ${alertType}*`,
    blocks: [
      {
        type: "section",
        text: {
          type: "mrkdwn",
          text: `*Robot:* ${robot.name} (${robot.id})\n*Status:* ${alertType}\n*Location:* ${robot.location}\n*Battery:* ${robot.battery}%`,
        },
      },
    ],
  };

  try {
    await axios.post(SLACK_WEBHOOK_URL, payload);
    console.log(`Alert sent for robot ${robot.id}`);
  } catch (error) {
    console.error("Failed to send Slack alert:", error.message);
  }
}
```

## Step 3: Wire Up Alert Triggers

In `server.js`, add the alert hook to the robot status check loop:

```javascript
const ALERT_THRESHOLDS = {
  battery: 10,
  temperature: 85,
  signalStrength: -80,
};

function checkRobotHealth(robot) {
  if (robot.battery < ALERT_THRESHOLDS.battery) {
    sendFleetAlert(robot, "CRITICAL_BATTERY");
  }
  if (robot.temperature > ALERT_THRESHOLDS.temperature) {
    sendFleetAlert(robot, "OVERHEATING");
  }
  if (robot.signalStrength < ALERT_THRESHOLDS.signalStrength) {
    sendFleetAlert(robot, "CONNECTIVITY_LOSS");
  }
}
```

## Step 4: Test the Integration

Send a test alert to verify connectivity:

```bash
curl -X POST -H 'Content-Type: application/json' \
  --data '{"text":"Fleet alerting test from Globomantics Robot Fleet"}' \
  https://hooks.slack.com/services/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
```

You should see the message appear in `#fleet-alerts` within seconds.

## Alert Types

| Alert               | Trigger                | Severity |
| ------------------- | ---------------------- | -------- |
| `CRITICAL_BATTERY`  | Battery < 10%          | Critical |
| `OVERHEATING`       | Temp > 85C             | Critical |
| `CONNECTIVITY_LOSS` | Signal < -80 dBm       | High     |
| `MOTOR_FAULT`       | Motor error code       | High     |
| `GEOFENCE_BREACH`   | Outside operating zone | Medium   |

## Troubleshooting

- **403 Forbidden**: The webhook URL may have been revoked. Generate a new one in Slack App Management.
- **Timeout errors**: Check that outbound HTTPS on port 443 is allowed by your network policy.
- **Rate limiting**: Slack limits webhooks to ~1 message/sec. Batch alerts if multiple robots fault simultaneously.

---

_Last updated: 2026-02-10 | Globomantics Engineering Team_
