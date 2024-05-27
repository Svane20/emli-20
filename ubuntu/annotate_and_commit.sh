#!/bin/bash

# Directory containing photos and metadata
PHOTO_DIR="$HOME/drone_photos"

# Directory for the Git repository
GIT_REPO_DIR="$HOME/svane20/Desktop/emli-20"
mkdir -p "$GIT_REPO_DIR"

# Function to annotate a photo and update the metadata JSON file
annotate_photo() {
    local photo_path=$1
    local json_path=${photo_path%.jpg}.json

    # Use Ollama to generate the annotation
    annotation=$(ollama run llava:7b "describe $photo_path")

    # Update the metadata JSON file with the annotation
    jq --arg annotation "$annotation" '.Annotation = {"Source": "Ollama:7b", "Text": $annotation}' "$json_path" > tmp.json && mv tmp.json "$json_path"

    echo "Updated metadata for $photo_path"
}

# Function to commit updated JSON files to the Git repository
commit_to_git() {
    cd "$GIT_REPO_DIR" || exit

    # Add updated JSON files to the repository
    git add .

    # Commit the changes with a message
    git commit -m "Annotated photos and updated metadata JSON files"

    # Push the changes to the remote repository
    git push
}

# Annotate each photo and update metadata
for photo in "$PHOTO_DIR"/*.jpg; do
    annotate_photo "$photo"
done

# Copy updated JSON files to the Git repository directory
cp "$PHOTO_DIR"/*.json "$GIT_REPO_DIR/"

# Commit the changes to Git
# commit_to_git

echo "Annotation and commit process completed."