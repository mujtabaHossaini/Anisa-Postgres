#!/bin/bash

export PGPASSWORD='postgres123'

# Get the current date in the format YYYY-MM-DD
current_date=$(date +"%Y-%m-%d_%H-%M")

# Run pg_dumpall with schema-only option and append the date to the filename
pg_dump -U postgres -h postgres -p 5432 -d northwind --data-only -w -f "/backups/northwind_data_${current_date}.sql"