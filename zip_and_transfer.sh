#!/bin/bash

################################################################################
# Script Name : zip_and_transfer.sh
# Description : Compresses a specified number of unprocessed files from the
#               source directory, transfers the ZIP archive to a destination
#               folder, extracts it, changes ownership to 'cft', and cleans up.
#
# Usage       : ./zip_and_transfer.sh <number_of_files_to_zip>
# Example     : ./zip_and_transfer.sh 10000
#
# Log File    : /net/si0vm09097/fs0/script/zip_and_transfer.log
# Processed DB: /net/si0vm09097/fs0/script/processed_files.txt
################################################################################

# Check input
if [ -z "$1" ]; then
    echo "Usage: $0 <number_of_files_to_zip>"
    exit 1
fi

BATCH_SIZE=$1

# Paths
SOURCE_DIR="/mule_local_exchange/API/S3/CSDOC-2"
ZIP_DIR="$SOURCE_DIR/zips"
DEST_DIR="/opt/axway/cft/runtime/cronjob"
LOG_FILE="/net/si0vm09097/fs0/script/zip_and_transfer.log"
PROCESSED_LIST="/net/si0vm09097/fs0/script/processed_files.txt"

# Ensure paths exist
mkdir -p "$ZIP_DIR"
touch "$LOG_FILE"
touch "$PROCESSED_LIST"

cd "$SOURCE_DIR" || { echo "Source directory not found"; exit 1; }

# Collect unprocessed files
AVAILABLE_FILES=()
for FILE in *; do
    if [[ -f "$FILE" ]] && ! grep -Fxq "$FILE" "$PROCESSED_LIST"; then
        AVAILABLE_FILES+=("$FILE")
        [[ ${#AVAILABLE_FILES[@]} -eq $BATCH_SIZE ]] && break
    fi
done

if [ ${#AVAILABLE_FILES[@]} -eq 0 ]; then
    echo "[$(date)] No new files to zip." | tee -a "$LOG_FILE"
    exit 0
fi

# Create zip
ZIP_NAME=$(date +"batch_%Y%m%d_%H%M%S.zip")
ZIP_PATH="$ZIP_DIR/$ZIP_NAME"
zip -q "$ZIP_PATH" "${AVAILABLE_FILES[@]}"

if [[ $? -eq 0 ]]; then
    echo "[$(date)] Created ZIP: $ZIP_NAME with ${#AVAILABLE_FILES[@]} files" | tee -a "$LOG_FILE"

    # Copy to destination and chown to cft
    cp "$ZIP_PATH" "$DEST_DIR/"
    chown cft:cft "$DEST_DIR/$ZIP_NAME"

    if [[ $? -eq 0 ]]; then
        echo "[$(date)] ZIP moved and chowned to cft." | tee -a "$LOG_FILE"

        # Unzip at destination
        unzip -q "$DEST_DIR/$ZIP_NAME" -d "$DEST_DIR"
        if [[ $? -eq 0 ]]; then
            echo "[$(date)] ZIP extracted successfully to $DEST_DIR" | tee -a "$LOG_FILE"

            # Set ownership of extracted files
            chown -R cft:cft "$DEST_DIR"
            echo "[$(date)] Ownership of extracted files set to cft:cft" | tee -a "$LOG_FILE"

            # Clean up zip at destination
            rm -f "$DEST_DIR/$ZIP_NAME"
            echo "[$(date)] ZIP file deleted from destination: $ZIP_NAME" | tee -a "$LOG_FILE"
        else
            echo "[$(date)] ERROR: Failed to unzip $ZIP_NAME at destination." | tee -a "$LOG_FILE"
        fi

        # Delete source zip
        rm -f "$ZIP_PATH"
        echo "[$(date)] ZIP deleted from source: $ZIP_NAME" | tee -a "$LOG_FILE"

        # Record processed files
        printf "%s\n" "${AVAILABLE_FILES[@]}" >> "$PROCESSED_LIST"
    else
        echo "[$(date)] ERROR: Failed to chown or copy $ZIP_NAME" | tee -a "$LOG_FILE"
    fi
else
    echo "[$(date)] ERROR: Failed to create ZIP: $ZIP_NAME" | tee -a "$LOG_FILE"
    exit 1
fi
