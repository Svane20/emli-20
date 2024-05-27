#!/bin/bash

DEFAULT_BASE_DIR="/home/emli/camera"

# Log directory
LOG_DIR="/home/emli/logs"
LOG_FILE="$LOG_DIR/take_photo.log"
mkdir -p "$LOG_DIR"

# Function to log events
log_event() {
    local event_message="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [TAKE-PHOTO] $event_message" >> "$LOG_FILE"
}

# Create directory with the current date
DATE_DIR=$(date +"%Y-%m-%d")
TARGET_DIR="${2:-$DEFAULT_BASE_DIR/$DATE_DIR}"
mkdir -p "$TARGET_DIR"

# Filename based on local summer time
FILENAME=$(date +"%H%M%S_%3N.jpg")
FULLPATH="$TARGET_DIR/$FILENAME"

# Trigger type based on input
TRIGGER_TYPE="${1:-Time}"

log_event "Taking photo with trigger: $TRIGGER_TYPE"

# Take a photo
rpicam-still -t 0.01 -o "$FULLPATH"

# Save metadata as sidecar
EXIFDATA=$(exiftool "$FULLPATH")
CREATION_DATE=$(date +"%Y-%m-%d %H:%M:%S.%3N%:z")
EPOCH=$(date +%s.%3N)

# Parsing EXIF data
ISO=$(echo "$EXIFDATA" | grep "ISO" | grep -oP "\d+")
EXPOSURE_TIME=$(echo "$EXIFDATA" | grep "Exposure Time" | grep -oP "\d+/\d+")
SUBJECT_DISTANCE=$(echo "$EXIFDATA" | grep "Subject Distance" | grep -oP "\d+(\.\d+)?")

# Create JSON metadata file
cat <<EOF >"${FULLPATH%.jpg}.json"
{
  "File Name": "$FILENAME",
  "Create Date": "$CREATION_DATE",
  "Create Seconds Epoch": "$EPOCH",
  "Trigger": "$TRIGGER_TYPE",
  "Subject Distance": "$SUBJECT_DISTANCE",
  "Exposure Time": "$EXPOSURE_TIME",
  "ISO": "$ISO"
}
EOF

log_event "Photo taken and metadata saved: $FULLPATH"

# Return the full path of the photo taken
echo "$FULLPATH"
