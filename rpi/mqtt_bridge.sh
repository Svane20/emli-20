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
LOCK_FILE="/tmp/camera.lock"

# Function to handle messages
handle_message() {
    local topic=$1
    local message=$2

    if [ "$topic" = "$MQTT_EXTERNAL_TOPIC" ]; then
        if [ "$message" -eq 1 ] 2>/dev/null; then
            echo "External trigger detected, attempting to take photo"

            # Use flock to acquire the lock in a blocking mode
            {
                flock -x 9  # Use exclusive lock

                # Take the photo
                PHOTO_PATH=$($TAKE_PHOTO_SCRIPT "External")
                if [ $? -eq 0 ]; then
                    echo "Photo taken successfully: $PHOTO_PATH"
                else
                    echo "Failed to take photo"
                fi
            } 9>"$LOCK_FILE"
        fi
    elif [ "$topic" = "$MQTT_RAIN_TOPIC" ]; then
        if echo "$message" | grep -q '"rain_detect": 1'; then
            echo "Rain detected, requesting lens wipe."
            echo "Sending sequence 0, 180, 0 to MQTT topic: $MQTT_WIPE_LENS_TOPIC"

            # Sequence of 0, 180 and 0 to wipe the lens
            mosquitto_pub -h $MQTT_SERVER -u $MQTT_USERNAME -P $MQTT_PASSWORD -t $MQTT_WIPE_LENS_TOPIC -m '{"wiper_angle": 0}'
            sleep 2
            mosquitto_pub -h $MQTT_SERVER -u $MQTT_USERNAME -P $MQTT_PASSWORD -t $MQTT_WIPE_LENS_TOPIC -m '{"wiper_angle": 180}'
            sleep 2
            mosquitto_pub -h $MQTT_SERVER -u $MQTT_USERNAME -P $MQTT_PASSWORD -t $MQTT_WIPE_LENS_TOPIC -m '{"wiper_angle": 0}'
            sleep 2
        fi
    fi
}

# Subscribe to topics and handle messages
mosquitto_sub -h $MQTT_SERVER -u $MQTT_USERNAME -P $MQTT_PASSWORD -v -t $MQTT_EXTERNAL_TOPIC -t $MQTT_RAIN_TOPIC | while read -r line; do
    # Extract the topic and message from the line
    topic=$(echo "$line" | cut -d ' ' -f 1)
    message=$(echo "$line" | cut -d ' ' -f 2- | sed 's/^ *//;s/ *$//')

    echo "Received message on topic $topic: $message"
    handle_message "$topic" "$message"
done