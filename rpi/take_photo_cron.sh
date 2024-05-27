#!/bin/bash

# Lock file
LOCK_FILE="/tmp/camera.lock"

# Log directory
LOG_DIR="/home/emli/logs"
LOG_FILE="$LOG_DIR/take_photo_cron.log"
mkdir -p "$LOG_DIR"

# Function to log events
log_event() {
    local event_message="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [TAKE-PHOTO-CRON] $event_message" >> "$LOG_FILE"
}

# Use flock to acquire the lock in a blocking mode
{
    flock -x 9  # Use exclusive lock

    log_event "5 minutes have passed, taking photo"

    # Call the take_photo.sh script with the appropriate trigger
    /home/emli/scripts/take_photo.sh "Time"

    log_event "Photo taken with Trigger: 'Time'"
} 9>"$LOCK_FILE"