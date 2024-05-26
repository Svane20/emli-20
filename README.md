# emli-20

# Raspberry PI

## take_photo.sh
- Added the script to crontab to run this script every 5 minutes with Trigger Time
- Added the necessary information in the script to output the format as expected

## mqtt_bridge.sh
- Added the script as a service (systemd) to ensure this process will run in the background and on startup
- This will read from the my_user/count topic from the ESP32 and take a photo using the take_photo.sh script with the Trigger External
- This will read from the my_user/rain if rain was detected through MQTT from the rain_detect.sh and then the sequence of 0, 180, 0 to my_user/wipe_lens topic

## rain_detect.sh
- Added the script as a service (systemd) to ensure this process will run in the background and on startup
- This will send messages when the boostel button is pressed on the Pico and send a mqtt message to the my_user/rain
- When a message is received from rain_detect.sh it will write to the serial port on the Pico to rotate the servo based on the defined angle