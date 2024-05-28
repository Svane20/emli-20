#!/bin/bash

# Directory containing photos and metadata
PHOTO_DIR="$HOME/drone_photos"

# Directory for the Git repository
GIT_REPO_DIR="/home/svane20/Desktop/emli-20/annotated_metadata"
mkdir -p "$GIT_REPO_DIR"

# Function to log errors
log_error() {
    local message="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] $message"
}

# Function to annotate a photo and update the metadata JSON file
annotate_photo() {
    local photo_path="$1"
    local json_path="${photo_path%.jpg}.json"

    echo "Processing image: $photo_path"

    # Check if the image has already been annotated
    if [ -f "$json_path" ] && jq -e '.Annotation' "$json_path" > /dev/null 2>&1; then
        echo "Image already annotated: $photo_path"
    else
        # Run Ollama to generate the annotation
        echo "Annotating image: $photo_path"
        local annotation_text
        annotation_text=$(ollama run llava:7b "describe $photo_path")
        
        # Check for successful annotation
        if [ -z "$annotation_text" ]; then
            log_error "Failed to annotate photo: $photo_path"
            return 1
        fi

        # Update the metadata JSON file with the annotation
        jq --arg annotation "$annotation_text" '.Annotation = {"Source": "Ollama:7b", "Text": $annotation}' "$json_path" > "${json_path}.tmp"
        if [ $? -ne 0 ]; then
            log_error "Failed to update JSON file: $json_path"
            rm -f "${json_path}.tmp"
            return 1
        fi
        mv "${json_path}.tmp" "$json_path"
        echo "Updated metadata for $photo_path"
    fi
}

# Function to commit updated JSON files to the Git repository
commit_to_git() {
    cd "$GIT_REPO_DIR" || { log_error "Failed to change directory to $GIT_REPO_DIR"; exit 1; }

    # Add updated JSON files to the repository
    git add .
    if [ $? -ne 0 ]; then
        log_error "Failed to add files to Git"
        return 1
    fi

    # Commit the changes with a message
    git commit -m "Annotated photos and updated metadata JSON files"
    if [ $? -ne 0 ]; then
        log_error "Failed to commit changes to Git"
        return 1
    fi

    # Pull the latest changes
    git pull
    if [ $? -ne 0 ]; then
        log_error "Failed to pull the repo"
    fi

    # Push the changes to the remote repository
    git push
    if [ $? -ne 0 ]; then
        log_error "Failed to push changes to Git repository"
        return 1
    fi
}

# Annotate each photo and update metadata
find "$PHOTO_DIR" -type f -iname "*.jpg" | while read -r photo; do
    annotate_photo "$photo" || { log_error "Annotation failed for $photo"; exit 1; }
done

# Copy updated JSON files to the Git repository directory
find "$PHOTO_DIR" -type f -iname "*.json" -exec cp {} "$GIT_REPO_DIR/" \;
if [ $? -ne 0 ]; then
    log_error "Failed to copy JSON files to Git repository directory"
    exit 1
fi

# Commit the changes to Git
commit_to_git || { log_error "Git commit failed"; exit 1; }

echo "Annotation and commit process completed."