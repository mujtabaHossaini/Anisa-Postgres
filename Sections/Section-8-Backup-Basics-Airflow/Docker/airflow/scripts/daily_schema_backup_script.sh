#!/bin/bash

export PGPASSWORD='postgres123'

# Get the current date in the format YYYY-MM-DD
current_date=$(date +"%Y-%m-%d_%H-%M")

# Run pg_dumpall with schema-only option and append the date to the filename
pg_dumpall -U postgres -h postgres -p 5432 --schema-only -w -f "/backups/all_schema_${current_date}.sql"