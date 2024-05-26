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

# Function to send a command to the Pico
wipe_lens_command() {
  echo "{\"wiper_angle\": $1}" > $PORT
}

# Publish MQTT message
publish_mqtt() {
  mosquitto_pub -h $MQTT_SERVER -t $MQTT_PUB_TOPIC -m "$1"
}

# Subscribe to MQTT topic and listen for messages
subscribe_mqtt() {
  mosquitto_sub -h $MQTT_SERVER -t $MQTT_SUB_TOPIC | while read -r msg; do
    echo "Received MQTT message: $msg"
    wiper_angle=$(echo "$msg" | jq -r '.wiper_angle')
    if [ -n "$wiper_angle" ]; then
      wipe_lens_command "$wiper_angle"
    fi
  done &
}

# Initialize and start listening on Serial Port
exec 3<$PORT

# Start MQTT subscription in the background
subscribe_mqtt

while read -r line <&3; do
  if echo "$line" | grep -q '"rain_detect": 1'; then
    echo "Rain detected, requesting lens wipe."

    # Publish rain detection message via MQTT
    publish_mqtt '{"rain_detect": 1}'
  fi
done

# Clean up before exit
cleanup() {
  exec 3<&-  # Close file descriptor 3
  echo "Stopped listening on $PORT"
}
trap cleanup EXIT