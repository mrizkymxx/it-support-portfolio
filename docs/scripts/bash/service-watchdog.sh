#!/usr/bin/env bash
#
# service-watchdog.sh - Autonomous daemon watchdog and self-healing restarter
# Usage: ./service-watchdog.sh [service_name]
# Example: ./service-watchdog.sh nginx
#

set -euo pipefail

SERVICE_NAME="${1:-nginx}"
LOG_FILE="/var/log/service-watchdog.log"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

log_msg() {
    echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
}

# Check if service is active
if systemctl is-active --quiet "$SERVICE_NAME"; then
    # Service is healthy
    exit 0
else
    log_msg "ALERT: Service '$SERVICE_NAME' is DOWN! Attempting automatic recovery..."

    # Attempt restart
    if systemctl restart "$SERVICE_NAME"; then
        sleep 2
        if systemctl is-active --quiet "$SERVICE_NAME"; then
            log_msg "RECOVERY: Service '$SERVICE_NAME' successfully restarted."
            # Optional: send webhook/alert to Slack or Telegram
        else
            log_msg "CRITICAL: Service '$SERVICE_NAME' restart command succeeded, but process is still dead."
            exit 2
        fi
    else
        log_msg "CRITICAL: Failed to execute restart on service '$SERVICE_NAME'."
        exit 1
    fi
fi
