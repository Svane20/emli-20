# emli-20

## General Information

## Race Conditions
Since the motion_detect.sh scripts is running continuously, a race condition will acris when the take_photo_cron.sh and mqtt_bridge.sh also needs access to 
the camera. This is solved by a locking mechanism in all three scripts using flock to ensure that only one script can access the camera at a time.
When the lock is released, the next script in line will be able to access the camera.

# Raspberry PI

## take_photo.sh
- Added the script to crontab to run this script every 5 minutes with Trigger Time
- Added the necessary information in the script to output the format as expected

## take_photo_cron.sh
- filler

## mqtt_bridge.sh
- Added the script as a service (systemd) to ensure this process will run in the background and on startup
- This will read from the my_user/count topic from the ESP32 and take a photo using the take_photo.sh script with the Trigger External
- This will read from the my_user/rain if rain was detected through MQTT from the rain_detect.sh and then the sequence of 0, 180, 0 to my_user/wipe_lens topic

## rain_detect.sh
- Added the script as a service (systemd) to ensure this process will run in the background and on startup
- This will send messages when the BOOTSEL button is pressed on the Pico and send a mqtt message to the my_user/rain
- When a message is received from rain_detect.sh it will write to the serial port on the Pico to rotate the servo based on the defined angle

## motion_detect.sh
- filler

## run_server.sh
- This script creates (if it does not already exist) and activates the virtual environment with Flask.

# Ubuntu Desktop

## drone_flight.sh
- filler

## annotate_and_commit.sh
- filler

