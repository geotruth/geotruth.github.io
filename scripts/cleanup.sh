#!/bin/bash
# Script to clean up temporary files

# Define the directory containing the temporary files
TEMP_DIR="/Users/rashaelnimeiry/Library/Mobile Documents/com~apple~CloudDocs/geotruth/geotruthwebsite/geotruth.github.io/"

# Navigate to the directory
cd "$TEMP_DIR" || exit

# Find and remove directories matching the pattern
find . -maxdepth 1 -type d -name '[a-f0-9]*' -exec rm -rf {} +

echo "Cleanup complete."
