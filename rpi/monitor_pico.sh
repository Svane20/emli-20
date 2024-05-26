#!/bin/bash

# Serial Port settings
PORT="/dev/ttyACM0"
BAUDRATE="115200"

# Configure Serial Port
stty -F $PORT cs8 $BAUDRATE ignbrk -brkint -imaxbel -opost -onlcr -isig -icanon -iexten -echo -echoe -echok -echoctl -echoke noflsh -ixon -crtscts

# Function to send a command to the Pico
wipe_lens_command() {
  echo "{\"wiper_angle\": $1}" > $PORT
}

# Initialize and start listening on Serial Port
exec 3<$PORT
while read -r line <&3; do
  if echo "$line" | grep -q '"rain_detect": 1'; then
    echo "Rain detected, requesting lens wipe."
    
    # Sequence of 0, 180 and 0 to wipe the lens
    wipe_lens_command 0
    sleep 2
    wipe_lens_command 180
    sleep 2
    wipe_lens_command 0
    sleep 2  
  fi
done

# Clean up before exit
cleanup() {
  exec 3<&-  # Close file descriptor 3
  echo "Stopped listening on $PORT"
}
trap cleanup EXIT
