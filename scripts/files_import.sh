#!/usr/bin/env bash
set -e

### Public files.

echo "DEBUG: Starting import of public files from $FILES_PUBLIC_BACKUPS_S3_FOLDER to $FILES_PUBLIC_FOLDER..."
time aws s3cmd sync --delete-removed "$FILES_PUBLIC_BACKUPS_S3_FOLDER" "$FILES_PUBLIC_FOLDER"
echo "DEBUG: Done"

echo "DEBUG: Changing owner of public files to ${OWNER_UID}:${OWNER_GID}..."
time chown -R "$OWNER_UID":"$OWNER_GID" "$FILES_PUBLIC_FOLDER"
echo "DEBUG: Done"

echo "DEBUG: Changing permissions of public files to 775..."
time chmod -R ug=rwx,o=rx "$FILES_PUBLIC_FOLDER"
echo "DEBUG: Done"

### Private files.

echo "DEBUG: Starting import of private files from $FILES_PRIVATE_BACKUPS_S3_FOLDER to $FILES_PRIVATE_FOLDER..."
time aws s3cmd sync --delete-removed "$FILES_PRIVATE_BACKUPS_S3_FOLDER" "$FILES_PRIVATE_FOLDER"
echo "DEBUG: Done"

echo "DEBUG: Changing owner of private files to ${OWNER_UID}:${OWNER_GID}..."
time chown -R "$OWNER_UID":"$OWNER_GID" "$FILES_PRIVATE_FOLDER"
echo "DEBUG: Done"

echo "DEBUG: Changing permissions of private files to 775..."
time chmod -R ug=rwx,o=rx "$FILES_PRIVATE_FOLDER"
echo "DEBUG: Done"
