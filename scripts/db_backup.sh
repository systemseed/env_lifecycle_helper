#!/usr/bin/env bash
set -e

# Export default variables.
# Note that we're explicitly making backups using
# non-root password so that in case if master password
# will rotate we still can be making backups.
export MYSQL_PWD="$DB_PASSWORD"

CURRENT_TIMESTAMP=$(date +%Y-%m-%dT%TZ)
BACKUP_FILENAME="${CURRENT_TIMESTAMP}.gzip"
echo "DEBUG: Dumping database ${DB_NAME} into ${BACKUP_FILENAME} as a single transaction..."
mysqldump -u "${DB_USER}" --host "${DB_HOST}" --single-transaction=TRUE --no-tablespaces "${DB_NAME}" | gzip -9 > "${BACKUP_FILENAME}"
echo "DEBUG: Done"

BACKUP_S3_PATH="${DB_BACKUPS_S3_FOLDER}${BACKUP_FILENAME}"
echo "DEBUG: Uploading backup to S3 path ${BACKUP_S3_PATH}..."
aws s3 cp "${BACKUP_FILENAME}" "${BACKUP_S3_PATH}"
echo "DEBUG: Done"
