#!/bin/bash

# Base directory for storing photos
BASE_DIR="/home/emli/camera"
LOCK_FILE="/tmp/camera.lock"

# Path to motion_detect.py
MOTION_DETECT_PATH="/home/emli/scripts/motion_detect.py"

# Temporary directory for storing photos
TEMP_DIR="/home/emli/camera/temp"
mkdir -p "$TEMP_DIR"

# Function to take photos
take_photo() {
    # Call take_photo.sh with the trigger type "Time" and temporary directory
    PHOTO_PATH=$(./take_photo.sh "Time" "$TEMP_DIR")
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
        echo "First photo taken at: $PHOTO1"

        # Ensure there is a brief delay between taking photos
        sleep 1

        # Take the second photo
        PHOTO2=$(take_photo)
        echo "Second photo taken at: $PHOTO2"

        # Check for motion between the two photos
        DETECT_OUTPUT=$(python3 "$MOTION_DETECT_PATH" "$PHOTO1" "$PHOTO2")
        echo "$DETECT_OUTPUT"
        if echo "$DETECT_OUTPUT" | grep -q "Motion detected"; then
            echo "Motion was detected, saving latest image..."

            # Extract the JSON filepath
            JSON_FILE2="${PHOTO2%.jpg}.json"

            # Update the JSON metadata file with "Trigger": "Motion"
            jq '.Trigger = "Motion"' "$JSON_FILE2" > "${JSON_FILE2}.tmp" && mv "${JSON_FILE2}.tmp" "$JSON_FILE2"

            # Create the date directory if it doesn't exist
            DATE_DIR=$(date +"%Y-%m-%d")
            DEST_DIR="$BASE_DIR/$DATE_DIR"
            mkdir -p "$DEST_DIR"

            # Move the photo, its JSON file, and motion_detect.png to the final directory
            mv "$PHOTO2" "$DEST_DIR/"
            mv "$JSON_FILE2" "$DEST_DIR/"

            # Remove the motion detect png
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
    } 9>"$LOCK_FILE"

    # Brief sleep to avoid constant looping
    sleep 1
done