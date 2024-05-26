#!/bin/bash

# Create directory with the current date
DATE=$(date +"%Y-%m-%d")
mkdir -p "/home/emli/camera/$DATE"

# Filename based on local summer time
FILENAME=$(date +"%H%M%S_%3N.jpg")
FULLPATH="/home/emli/camera/$DATE/$FILENAME"

# Trigger type based on input
TRIGGER_TYPE="$1" # Time, Motion, External

# Take a photo
rpicam-still -t 0.01 -o "$FULLPATH"

# Save metadata as sidecar
EXIFDATA=$(exiftool "$FULLPATH")
CREATION_DATE=$(date +"%Y-%m-%d %H:%M:%S.%3N%:z")
EPOCH=$(date +%s.%3N)

# Parsing EXIF data
ISO=$(echo "$EXIFDATA" | grep "ISO" | grep -oP "\d+")
EXPOSURE_TIME=$(echo "$EXIFDATA" | grep "Exposure Time" | grep -oP "\d+/\d+")
SUBJECT_DISTANCE=$(echo "$EXIFDATA" | grep "Subject Distance" | grep -oP "\d+.*$")


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
