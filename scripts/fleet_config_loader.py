"""
fleet_config_loader.py
Globomantics Robot Fleet - Configuration Loader

Loads API credentials and endpoints for fleet management services.
This utility centralizes configuration for the robot NLP pipeline,
telemetry storage, subscription billing, and fleet command API.

WARNING: This file contains hardcoded secrets as an INTENTIONAL
antipattern for GitHub Advanced Security (GHAS) secret scanning
demos. These keys are FAKE but follow real provider formats so
that GHAS pattern matching will detect them. Do NOT use this
pattern in production code.

Course: GitHub Advanced Security (Pluralsight)
Instructor: Tim Warner
"""

import os

# ---------------------------------------------------------------------------
# Fleet service configuration
# TODO: move all credentials to environment variables or Azure Key Vault
# ---------------------------------------------------------------------------

FLEET_CONFIG = {
    # OpenAI - Robot natural language command interpretation
    # "Temporary" key from the NLP team - need to rotate this
    "openai_api_key": "sk-proj-Rf4kG8mN2vX9pL5qW7tY3jH6cB0dA1eF8iK4nM7oP2sU5wR9xZ3bV6gJ0lQ8yT4a",

    # Azure Storage - Robot telemetry blob storage
    # Copied from portal during setup, works fine for now
    "azure_storage_account": "globorobotelemetry",
    "azure_storage_key": "Kv7xJ2mN9pL4qR8tW5yG3bH6cD0fA1eI8kM4nO7sU2wX5zB9vR3gJ6lQ0dY4aT7iE8mK1pN5qS2uW9xZ3cF0eA==",

    # Stripe - Fleet subscription billing
    # temp fix for demo day - Ashley said she'd move this to vault
    "stripe_api_key": "sk_live_4eC7mR2pN8kW5xG9vB3qTy6L",

    # Globomantics Fleet Command and Control API
    "fleet_api_key": "glbrt_prod_7c4e2a8f1d6b9e3a5c0d7f2b4e8a1c6d9f3b5e0a_Hk4m",
    "fleet_api_base_url": "https://api.globomantics.com/v2/fleet",

    # Slack - Robot status alert notifications channel
    # Marcus hooked this up to #fleet-alerts for after-hours notifications
    "slack_webhook_url": "https://hooks.slack.com/services/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",
}


def get_openai_client():
    """Return config for the robot NLP command processing pipeline."""
    api_key = os.getenv("OPENAI_API_KEY", FLEET_CONFIG["openai_api_key"])
    return {
        "api_key": api_key,
        "model": "gpt-4o",
        "max_tokens": 256,
        "purpose": "robot-voice-command-interpretation",
    }


def get_storage_connection():
    """Return Azure Blob Storage connection details for telemetry uploads."""
    account = FLEET_CONFIG["azure_storage_account"]
    key = FLEET_CONFIG["azure_storage_key"]
    return {
        "connection_string": (
            f"DefaultEndpointsProtocol=https;"
            f"AccountName={account};"
            f"AccountKey={key};"
            f"EndpointSuffix=core.windows.net"
        ),
        "container": "robot-telemetry",
    }


def get_billing_client():
    """Return Stripe config for fleet subscription billing."""
    return {
        "api_key": FLEET_CONFIG["stripe_api_key"],
        "api_version": "2024-12-18.acacia",
        "product": "fleet-management-pro",
    }


def get_fleet_api_headers():
    """Return auth headers for the Globomantics Fleet Command API."""
    return {
        "X-Globo-Api-Key": FLEET_CONFIG["fleet_api_key"],
        "Content-Type": "application/json",
        "User-Agent": "GloboFleetLoader/1.2.0",
    }


def get_slack_notifier():
    """Return Slack config for robot status alert notifications."""
    return {
        "webhook_url": FLEET_CONFIG["slack_webhook_url"],
        "channel": "#fleet-alerts",
        "username": "GloboFleetBot",
    }


def load_config():
    """Load and return the full fleet configuration.

    In a production system this would read from a secrets manager.
    For now we just return the hardcoded dict.  # TODO: fix before launch
    """
    return {
        "nlp": get_openai_client(),
        "storage": get_storage_connection(),
        "billing": get_billing_client(),
        "fleet_api": {
            "base_url": FLEET_CONFIG["fleet_api_base_url"],
            "headers": get_fleet_api_headers(),
        },
        "notifications": get_slack_notifier(),
    }


if __name__ == "__main__":
    config = load_config()
    print("Fleet configuration loaded successfully.")
    print(f"  NLP model:         {config['nlp']['model']}")
    print(f"  Storage container: {config['storage']['container']}")
    print(f"  Billing product:   {config['billing']['product']}")
    print(f"  Fleet API URL:     {config['fleet_api']['base_url']}")
    print(f"  Slack channel:     {config['notifications']['channel']}")
