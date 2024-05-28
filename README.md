# emli-20

## General Information

## Race Conditions
Since the motion_detect.sh scripts is running continuously, a race condition will arise when the take_photo_cron.sh and mqtt_bridge.sh also needs access to 
the camera. This is solved by a locking mechanism in all three scripts using flock to ensure that only one script can access the camera at a time.
When the lock is released, the next script in line will be able to access the camera.

# Raspberry PI

## take_photo.sh
- Added the script to crontab to run this script every 5 minutes with Trigger Time
- Added the necessary information in the script to output the format as expected

## take_photo_cron.sh
- Periodically takes a photo and logs the events
- Calls the external script "take_photo.sh" to take a photo with the Trigger "Time"
- A flock is used to prevent multiple instances of the script from running simultanously

## mqtt_bridge.sh
- Added the script as a service (systemd) to ensure this process will run in the background and on startup
- This will read from the my_user/count topic from the ESP32 and take a photo using the take_photo.sh script with the Trigger External
- This will read from the my_user/rain if rain was detected through MQTT from the rain_detect.sh and then the sequence of 0, 180, 0 to my_user/wipe_lens topic

## rain_detect.sh
- Added the script as a service (systemd) to ensure this process will run in the background and on startup
- This will send messages when the BOOTSEL button is pressed on the Pico and send a mqtt message to the my_user/rain
- When a message is received from rain_detect.sh it will write to the serial port on the Pico to rotate the servo based on the defined angle

## motion_detect.sh
- Captures two consecutive photos and checks for motion between the two photos using a Python script.
- If motion is detected, the event is logged, and the metadata is updated with a "Motion" trigger, which moves the photos and metadata to a directory.
- Unnecessary files are also removed to manage storage.
- A lock file is included, which only runs one instance of the script at a time, preventing race conditions.

## run_server.sh
- This script creates (if it does not already exist) and activates the virtual environment with Flask.

# Ubuntu Desktop

## drone_flight.sh
- Scans for the camera's SSID and connects to it. The script runs continiously and scans for the camera every 30 seconds.
- If the camera is located, a disconnection from current network occurs, and a connection to the camera's network is established.
- This results in a synchronization between the drone's system time and the Raspberry Pi, ensuring accurate timestamps.
- Photos and metadata are copied from the Raspberry Pi to the drone.
- Metadata files on the Raspberry Pi are updated to include a Drone Copy Event.
- Also logs other events, such as time synchronization, photo copying and metadata updates.
- Monitors and logs WiFi signal quality to an SQLite database.

## annotate_and_commit.sh
- By applying a continious processing for all JPEG photos in the directory, Ollama can annotate each photo.
- On annotation, the JSON metadata file for the photo is updated and any errors encountered during the process is logged.
- All changed JSON metadata files are commited to the GitHub repository.
