#!/bin/bash

LOCK_FILE="/tmp/camera.lock"
TAKE_PHOTO_PATH="/home/emli/scripts/take_photo.sh"

# Use flock to acquire the lock in a blocking mode
{
    flock -x 9  # Use exclusive lock

    # Call the take_photo.sh script with the trigger Time
    $TAKE_PHOTO_PATH "Time"
} 9>"$LOCK_FILE"
