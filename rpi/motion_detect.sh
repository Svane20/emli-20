#!/bin/bash

# Base directory for storing photos
BASE_DIR="/home/emli/camera"

# Path to motion_detection.py
MOTION_DETECT_PATH="/home/emli/scripts/motion_detection.py"

# Temporary directory for storing photos
TEMP_DIR="/home/emli/camera/temp"
mkdir -p "$TEMP_DIR"

# Main loop
while true; do
    # Take the first photo using take_photo.sh with "Time" trigger
    PHOTO1=$(./take_photo.sh "Time" "$TEMP_DIR")

    # Take the second photo using take_photo.sh with "Time" trigger
    PHOTO2=$(./take_photo.sh "Time" "$TEMP_DIR")

    # Check for motion between the two photos
    python3 $MOTION_DETECT_PATH "$PHOTO1" "$PHOTO2"
    if [ $? -eq 0 ]; then
        echo "Motion was detected, saving latest image..."

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
    fi

    # Remove the first photo and its JSON metadata file
    rm -f "$PHOTO1" "${PHOTO1%.jpg}.json"

    # Remove the second photo and its JSON metadata file if it wasn't moved
    if [ -f "$PHOTO2" ]; then
        rm -f "$PHOTO2" "${PHOTO2%.jpg}.json"
    fi

    # Ensure the temporary directory is empty
    rm -f "$TEMP_DIR"/*
done
