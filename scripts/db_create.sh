#!/usr/bin/env bash
set -e

# Export default variables.
DB_MASTER_PASSWORD="$(aws secretsmanager get-secret-value --secret-id="$SECRET_NAME" --query SecretString --output text | jq -r ."$SECRET_MASTER_PASSWORD_KEY")"
export MYSQL_PWD="$DB_MASTER_PASSWORD"
export MYSQL_HOST="$DB_HOST"
export MYSQL_TCP_PORT="$DB_PORT"

# Create a new user or don't do anything if the user already exists.
# This is done so that in case if we want to use the same database
# for the release we can use the same username.
# In case if user already exists e want to make sure that the password
# is actually updated in case if the user existed before.
echo "DEBUG: Creating a new user ${DB_USER} if not exists..."
mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';"
mysql -e "ALTER USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';"
echo "DEBUG: Done"

# Make sure the user has full access to the database we've created.
echo "DEBUG: Granting user ${DB_USER} access to the database ${DB_NAME}..."
mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';"
echo "DEBUG: Done"

echo "DEBUG: Checking if the database ${DB_NAME} already exists..."
DB_EXISTS=$(mysql -e "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '${DB_NAME}'")
if [[ -n $DB_EXISTS ]];
then
  if [[ -n $DB_RECREATE_IF_EXISTS ]];
  then
    echo "DEBUG: Database ${DB_NAME} already exists and should be recreated. Deleting the existing one..."
    mysql -e "DROP DATABASE IF EXISTS ${DB_NAME};"
    echo "DEBUG: Done"
  else
    echo "DEBUG: Database ${DB_NAME} already exists and should NOT be recreated. Using the existing one."
    exit;
  fi
else
  echo "DEBUG: Database does not exist and will be created."
fi

echo "DEBUG: Creating database ${DB_NAME}..."
mysql -e "CREATE DATABASE ${DB_NAME};"
echo "DEBUG: Done"

# Depending on the mode selected, database might be created using backup with or without PII.
if [[ -n $DB_CREATE_WITHOUT_PII ]];
then
  echo "DEBUG: Database will be created without PII (personal identifiable information)..."
  BACKUP_FILENAME_SUFFIX="without-pii"
else
  echo "DEBUG: Database will be created with PII (personal identifiable information)..."
  BACKUP_FILENAME_SUFFIX="full"
fi

echo "DEBUG: Figuring out the latest database backup from ${DB_BACKUPS_S3_FOLDER}..."
# Finds 10 latest database backups, then check which of them has the appropriate suffix (with or without PII), then
# take only the one latest. Technically we could have checked only 2 latest backups and not 10, but it was done for
# extra assurance that within 10 latest backups at least one should almost definitely have the right suffix.
BACKUP_FILENAME=$(aws s3 ls "${DB_BACKUPS_S3_FOLDER}" | sort | tail -n 10 | awk '{print $4}' | grep -w ".*-${BACKUP_FILENAME_SUFFIX}.gzip" | tail -n 1)
BACKUP_S3_PATH="${DB_BACKUPS_S3_FOLDER}${BACKUP_FILENAME}"
echo "DEBUG: Selected S3 URI for the backup is $BACKUP_S3_PATH"
echo "DEBUG: Done"

echo "DEBUG: Pulling backup from ${BACKUP_S3_PATH}..."
aws s3 cp "${BACKUP_S3_PATH}" ./dump.sql.gz
gunzip -f ./dump.sql.gz
echo "DEBUG: Done"

echo "DEBUG: Importing dump into database..."
mysql "${DB_NAME}" < ./dump.sql
echo "DEBUG: Done"
