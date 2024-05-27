#!/bin/bash

# Drone ID
DRONE_ID="WILDDRONE-001"

# Camera SSID
CAMERA_SSID="EMLI-TEAM-20"

# Current WIFI interface
WIFI_INTERFACE="ens33" # Different because of VM

# Directory to store copied photos and metadata
CAMERA_PHOTO_DIR="/home/emli/camera"
DRONE_PHOTO_DIR="$HOME/drone_photos"
mkdir -p "$DRONE_PHOTO_DIR"

# SQLite database for logging
LOG_DB="$HOME/drone_flight_log.db"

# IP address of Raspberry Pi
RPI_USER="emli" 
RPI_IP="10.0.0.10"

# Log file on Raspberry Pi
RPI_LOG_FILE="/home/emli/logs/wildlife_camera.log"


# Function to scan for the camera
scan_for_camera() {
    local found_ssid=$(nmcli -t -f SSID dev wifi | grep "$CAMERA_SSID")
    echo "$found_ssid"
}

# Function to synchronize time with the wildlife camera
sync_time() {
    log_event "Synchronizing time with the drone"
    local current_time=$(date -u +"%Y-%m-%d %H:%M:%S")
    ssh $RPI_USER@$RPI_IP "sudo date -u -s '$current_time'"
    if [ $? -eq 0 ]; then
        log_event "Time synchronized successfully."
    else
        log_event "Failed to synchronize time."
    fi
}

# Function to copy photos and metadata from the Raspberry Pi to the drone
copy_photos() {
    log_event "Copying photos and metadata from the Raspberry Pi"
    rsync -avz --exclude='temp/' --log-file=$RSYNC_LOG_FILE $RPI_USER@$RPI_IP:$CAMERA_PHOTO_DIR/ $DRONE_PHOTO_DIR/
    if [ $? -eq 0 ]; then
        log_event "Photos and metadata copied successfully."
        
        # Update metadata JSON files on the Raspberry Pi based on copied files
        update_metadata_on_rpi
    else
        log_event "Failed to copy photos and metadata."
    fi
}

# Function to update metadata JSON files on the Raspberry Pi
update_metadata_on_rpi() {
    echo "Started updating metadata"
    log_event "Updating metadata JSON files with drone copy info"
    for dir in $DRONE_PHOTO_DIR/*/; do
        for file in $dir/*.json; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                filepath=$(dirname "$file")
                rpi_filepath="$CAMERA_PHOTO_DIR/${filepath##*/}/$filename"
                ssh $RPI_USER@$RPI_IP "jq --arg drone_id '$DRONE_ID' --argjson epoch $(date +%s.%N) '.\"Drone Copy\" = {\"Drone ID\": \$drone_id, \"Seconds Epoch\": \$epoch}' $rpi_filepath > /home/emli/tmp.$$.json && mv /home/emli/tmp.$$.json $rpi_filepath"
                if [ $? -eq 0 ]; then
                    log_event "Updated metadata: $rpi_filepath"
                else
                    log_event "Failed to update metadata: $rpi_filepath"
                fi
            else
                log_event "Metadata file not found: $file"
            fi
        done
    done
    echo "Finished updating metadata"
    log_event "Finished updating metadata JSON files"
}

# Function to log events on the raspberry pi log file
log_event() {
    local event_message="$1"
    ssh $RPI_USER@$RPI_IP "echo \"[$(date +'%Y-%m-%d %H:%M:%S')] [DRONE-FLIGHT] $event_message\" >> $RPI_LOG_FILE"
}

# Function to disconnect from the internet
disconnect_internet() {
    local status=$(nmcli -t -f DEVICE,STATE dev | grep "$WIFI_INTERFACE:connected")
    if [ -n "$status" ]; then
        nmcli d disconnect "$WIFI_INTERFACE"
        echo "Disconnected from current WiFi network."
    else
        echo "Not connected to any WiFi network."
    fi
}

disconnect_internet

# Main loop
while true; do
  if [ "$(scan_for_camera)" ]; then
      echo "Found camera ssid: $CAMERA_SSID, connecting..."

      sync_time 

      copy_photos
  else
      echo "Camera not found. Scanning again..."
  fi

  sleep 30
done
