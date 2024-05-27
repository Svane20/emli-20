#!/bin/bash

# Create the virtual environment if it doesn't exist
if [ ! -d "/home/emli/server/myenv" ]; then
    python3 -m venv /home/emli/server/myenv
fi

# Activate the virtual environment
source /home/emli/server/myenv/bin/activate

# Install Flask if not already installed
pip show flask &>/dev/null || pip install flask

# Run the Flask application
python3 /home/emli/server/server.py