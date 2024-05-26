#!/bin/bash

# MQTT
MQTT_SERVER="localhost"
MQTT_USERNAME="my_user"
MQTT_PASSWORD="Duller12"
MQTT_RAIN_TOPIC="my_user/rain"
MQTT_WIPE_LENS_TOPIC="my_user/wipe_lens"
MQTT_EXTERNAL_TOPIC="my_user/count"

# SCRIPTS
TAKE_PHOTO_SCRIPT="/home/emli/scripts/take_photo.sh"

mosquitto_sub -h $MQTT_SERVER -u $MQTT_USERNAME -P $MQTT_PASSWORD -t $MQTT_EXTERNAL_TOPIC -t $MQTT_WIPE_LENS_TOPIC | while read -r message; do
  echo "Received message: $message"

  if [ "$message" -eq 1 ]; then
    echo "External trigger detected, taking photo"
    $TAKE_PHOTO_SCRIPT "External"
  elif echo "$message" | grep -q '"rain_detect": 1'; then
    echo "Rain detected, requesting lens wipe."

    # Sequence of 0, 180 and 0 to wipe the lens
    mosquitto_pub -h $MQTT_SERVER -u $MQTT_USERNAME -P $MQTT_PASSWORD -t $MQTT_WIPE_LENS_TOPIC -m '{"wiper_angle": 0}'
    sleep 2
    mosquitto_pub -h $MQTT_SERVER -u $MQTT_USERNAME -P $MQTT_PASSWORD -t $MQTT_WIPE_LENS_TOPIC -m '{"wiper_angle": 180}'
    sleep 2
    mosquitto_pub -h $MQTT_SERVER -u $MQTT_USERNAME -P $MQTT_PASSWORD -t $MQTT_WIPE_LENS_TOPIC -m '{"wiper_angle": 0}'
    sleep 2
  fi

done