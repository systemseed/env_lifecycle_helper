#!/usr/bin/env bash
set -e

# Export default variables.
# Note that we're explicitly making backups using
# non-root password so that in case if master password
# will rotate we still can be making backups.
export MYSQL_PWD="$DB_PASSWORD"

###
# FULL DATABASE DUMP.
###

CURRENT_TIMESTAMP=$(date +%Y-%m-%dT%TZ)
BACKUP_FILENAME="${CURRENT_TIMESTAMP}.gzip"
echo "DEBUG: Dumping full database ${DB_NAME} into ${BACKUP_FILENAME} as a single transaction..."
mysqldump -u "${DB_USER}" --host "${DB_HOST}" --single-transaction --no-tablespaces "${DB_NAME}" | gzip -9 > "${BACKUP_FILENAME}"
echo "DEBUG: Done"

BACKUP_S3_PATH="${DB_BACKUPS_S3_FOLDER}${BACKUP_FILENAME}"
echo "DEBUG: Uploading backup to S3 path ${BACKUP_S3_PATH}..."
aws s3 cp "${BACKUP_FILENAME}" "${BACKUP_S3_PATH}"
echo "DEBUG: Done"

###
# DATABASE DUMP WITHOUT PII.
###

BACKUP_FILENAME="${CURRENT_TIMESTAMP}-without-pii.gzip"
echo "DEBUG: Starting db dump without PII..."

# Convert list of tables containing PII into an array.
TABLES_WITH_PII_ARRAY=($DB_TABLES_WITH_PII)
echo "DEBUG: Tables to dump without data (from project configs):" ${TABLES_WITH_PII_ARRAY[@]}

TABLES_TO_IGNORE=()
for TABLE in "${TABLES_WITH_PII_ARRAY[@]}"
do
  # If the table name has wildcard char "%" then we load all tables
  # matching this wildcard table name.
  if [[ "$TABLE" == *"%"* ]]; then
    mapfile MATCHING_TABLES < <(mysql -u "${DB_USER}" --host "${DB_HOST}" "${DB_NAME}" -e "SHOW TABLES LIKE '$TABLE'")

    # Note: the first array element is NOT a table name but a generic
    # mysql string (table header). Therefore we should remove it.
    unset MATCHING_TABLES[0]

    # Merge tables into the list of all tables which should be exported
    # without data.
    TABLES_TO_IGNORE+=("${MATCHING_TABLES[@]}")
  else
    # Adding table to the list of tables to ignore. In theory the table may not exist, but it does not
    # affect anything, so the check if the table exists was not added here.
    TABLES_TO_IGNORE+=($TABLE)
  fi
done

echo "DEBUG: Tables to dump without data (processed):" ${TABLES_TO_IGNORE[@]}

# Build a string for mysqldump command to exclude listed tables.
TABLES_TO_IGNORE_STRING=''
for TABLE in "${TABLES_TO_IGNORE[@]}"
do :
   TABLES_TO_IGNORE_STRING+="--ignore-table=${DB_NAME}.${TABLE} "
done

echo "DEBUG: Dumping database structure without data..."
mysqldump -u "${DB_USER}" --host "${DB_HOST}" --single-transaction --no-tablespaces --no-data --routines "${DB_NAME}" > "${BACKUP_FILENAME}.tmp"

echo "DEBUG: Dumping database content for all tables apart from ignored tables..."
mysqldump -u "${DB_USER}" --host "${DB_HOST}" --single-transaction --no-tablespaces --no-create-info --skip-triggers $TABLES_TO_IGNORE_STRING "${DB_NAME}" >> "${BACKUP_FILENAME}.tmp"

echo "DEBUG: Gzipping the database dump without PII..."
cat "${BACKUP_FILENAME}.tmp" | gzip -9 > "${BACKUP_FILENAME}"

BACKUP_S3_PATH="${DB_BACKUPS_S3_FOLDER}${BACKUP_FILENAME}"
echo "DEBUG: Uploading backup to S3 path ${BACKUP_S3_PATH}..."
aws s3 cp "${BACKUP_FILENAME}" "${BACKUP_S3_PATH}"

rm "${BACKUP_FILENAME}.tmp"
echo "DEBUG: Done"
