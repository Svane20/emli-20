#!/bin/bash

# Base directory for storing photos
BASE_DIR="/home/emli/camera"
LOCK_FILE="/tmp/camera.lock"

# Path to motion_detect.py
MOTION_DETECT_PATH="/home/emli/scripts/motion_detect.py"
TAKE_PHOTO_PATH="/home/emli/scripts/take_photo.sh"

# Temporary directory for storing photos
TEMP_DIR="/home/emli/camera/temp"
mkdir -p "$TEMP_DIR"

# Log directory
LOG_DIR="/home/emli/logs"
LOG_FILE="$LOG_DIR/motion_detect.log"
mkdir -p "$LOG_DIR"

# Function to log events
log_event() {
    local event_message="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [MOTION-DETECT] $event_message" >> "$LOG_FILE"
}

# Function to take photos
take_photo() {
    # Call take_photo.sh with the trigger type "Time" and temporary directory
    PHOTO_PATH=$("$TAKE_PHOTO_PATH" "Time" "$TEMP_DIR")
    # Return the path to the photo taken
    echo "$PHOTO_PATH"
}

# Main loop
while true; do
    # Use flock to acquire the lock in a blocking mode
    {
        flock -x 9  # Use exclusive lock

        # Take the first photo
        PHOTO1=$(take_photo)

        # Ensure there is a brief delay between taking photos
        sleep 1

        # Take the second photo
        PHOTO2=$(take_photo)

        # Check for motion between the two photos
        DETECT_OUTPUT=$(python3 "$MOTION_DETECT_PATH" "$PHOTO1" "$PHOTO2")
        if echo "$DETECT_OUTPUT" | grep -q "Motion detected"; then
            echo "Motion detected"
            log_event "Motion was detected, saving latest image with Trigger: 'Motion'"

            # Extract the JSON filepath
            JSON_FILE2="${PHOTO2%.jpg}.json"

            # Update the JSON metadata file with "Trigger": "Motion"
            jq '.Trigger = "Motion"' "$JSON_FILE2" > "${JSON_FILE2}.tmp" && mv "${JSON_FILE2}.tmp" "$JSON_FILE2"

            # Create the date directory if it doesn't exist
            DATE_DIR=$(date +"%Y-%m-%d")
            DEST_DIR="$BASE_DIR/$DATE_DIR"
            mkdir -p "$DEST_DIR"

            # Move the photo and its JSON file to the final directory
            mv "$PHOTO2" "$DEST_DIR/"
            mv "$JSON_FILE2" "$DEST_DIR/"

            # Remove the motion_detect.png
            rm -f "/home/emli/scripts/motion_detect.png"
        else
            echo "No motion detected."
        fi

        # Remove the first photo and its JSON metadata file
        rm -f "$PHOTO1" "${PHOTO1%.jpg}.json"

        # Remove the second photo and its JSON metadata file if it wasn't moved
        if [ -f "$PHOTO2" ]; then
            rm -f "$PHOTO2" "${PHOTO2%.jpg}.json"
        fi

        # Ensure the temporary directory is empty
        rm -f "$TEMP_DIR"/*
    } 9>"$LOCK_FILE"

    # Brief sleep to avoid constant looping
    sleep 1
done