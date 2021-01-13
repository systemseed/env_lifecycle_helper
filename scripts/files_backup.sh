#!/usr/bin/env bash
set -e

echo "DEBUG: Starting public files backup from $FILES_PUBLIC_FOLDER to $FILES_PUBLIC_BACKUPS_S3_FOLDER..."
aws s3 sync --delete "$FILES_PUBLIC_FOLDER" "$FILES_PUBLIC_BACKUPS_S3_FOLDER"
echo "DEBUG: Done"

echo "DEBUG: Starting private files backup from $FILES_PRIVATE_FOLDER to $FILES_PRIVATE_BACKUPS_S3_FOLDER..."
aws s3 sync --delete "$FILES_PRIVATE_FOLDER" "$FILES_PRIVATE_BACKUPS_S3_FOLDER"
echo "DEBUG: Done"
