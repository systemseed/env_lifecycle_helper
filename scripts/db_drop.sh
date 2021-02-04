#!/usr/bin/env bash
set -e

# Export default variables.
export MYSQL_PWD="$DB_MASTER_PASSWORD"
export MYSQL_HOST="$DB_HOST"
export MYSQL_TCP_PORT="$DB_PORT"

# TODO: Temporary removed user deletion, because for long-name
# environments the username generated maybe the same (due to trim to 32chars)
# and removal of one env may delete user with the same name.
# This needs to be fixed before we uncomment this.
#echo "DEBUG: Deleting the user ${DB_USER} if exists..."
#mysql -e "DROP USER IF EXISTS '${DB_USER}'@'%';"
#echo "DEBUG: Done"

echo "DEBUG: Deleting the database ${DB_NAME} if exists..."
mysql -e "DROP DATABASE IF EXISTS ${DB_NAME};"
echo "DEBUG: Done"
