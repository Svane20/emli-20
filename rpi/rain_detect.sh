#!/bin/bash

# Serial Port settings
PORT="/dev/ttyACM0"
BAUDRATE="115200"

# Configure Serial Port
stty -F $PORT cs8 $BAUDRATE ignbrk -brkint -imaxbel -opost -onlcr -isig -icanon -iexten -echo -echoe -echok -echoctl -echoke noflsh -ixon -crtscts

# MQTT
MQTT_SERVER="localhost"
MQTT_USERNAME="my_user"
MQTT_PASSWORD="Duller12"
MQTT_PUB_TOPIC="my_user/rain"
MQTT_SUB_TOPIC="my_user/wipe_lens"

# Log directory
LOG_DIR="/home/emli/logs"
LOG_FILE="$LOG_DIR/rain_detect.log"
mkdir -p "$LOG_DIR"

# Function to log events
log_event() {
    local event_message="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [RAIN-DETECT] $event_message" >> "$LOG_FILE"
}

# Function to send a command to the Pico
wipe_lens_command() {
  log_event "Sending wiper angle command: $1"
  echo "{\"wiper_angle\": $1}" > $PORT
}

# Publish MQTT message
publish_mqtt() {
  log_event "Publishing MQTT message: $1"
  mosquitto_pub -h $MQTT_SERVER -u $MQTT_USERNAME -P $MQTT_PASSWORD -t $MQTT_PUB_TOPIC -m "$1"
}

# Subscribe to MQTT topic and listen for messages
subscribe_mqtt() {
  echo "Starting MQTT subscription to topic: $MQTT_SUB_TOPIC"
  while true; do
    mosquitto_sub -h $MQTT_SERVER -u $MQTT_USERNAME -P $MQTT_PASSWORD -t $MQTT_SUB_TOPIC | while read -r msg; do
      log_event "Received MQTT message: $msg"
      wiper_angle=$(echo "$msg" | jq -r '.wiper_angle')
      if [ -n "$wiper_angle" ]; then
        wipe_lens_command "$wiper_angle"
      else
        log_event "Invalid message format or missing wiper_angle"
      fi
    done
    echo "Connection lost. Retrying in 5 seconds..."
    sleep 5
  done
}

# Initialize and start listening on Serial Port
exec 3<$PORT

# Start MQTT subscription in the background
subscribe_mqtt &

while read -r line <&3; do
  if echo "$line" | grep -q '"rain_detect": 1'; then
    log_event "Rain detected, requesting lens wipe."

    # Publish rain detection message via MQTT
    publish_mqtt '{"rain_detect": 1}'
  fi
done

# Clean up before exit
cleanup() {
  exec 3<&-  # Close file descriptor 3
  log_event "Stopped listening on $PORT"
}
trap cleanup EXIT

wait
