# emli-20

# Raspberry PI

## take_photo.sh

- Added the script to crontab to run this script every 5 minutes with Trigger Time
- Added the necessary information in the script to output the format as expected

## mqtt_bridge.sh
- Added the script as a service (systemd) to ensure this process will run in the background and on startup
- This will read from the my_user/count topic from the ESP32 and take a photo using the take_photo.sh script with the Trigger External