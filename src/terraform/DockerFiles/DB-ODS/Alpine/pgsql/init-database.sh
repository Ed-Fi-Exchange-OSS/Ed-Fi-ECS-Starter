#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

set -e
set +x

if [[ -z "$POSTGRES_PORT" ]]; then
  export POSTGRES_PORT=5432
fi

export MINIMAL_BACKUP=EdFi_Ods_Minimal_Template.sql

if [[ "$TPDM_ENABLED" = true ]]; then
  export MINIMAL_BACKUP=EdFi_Ods_Minimal_Template_TPDM_Core.sql
fi

if [[ -z "$ODS_DB" ]]; then
  export ODS_DB="EdFi_Ods"
fi

echo "LOGIN WITH RDS_USER AND CREATE USER AND TABLES "
export PGPASSWORD="$RDS_PASSWORD"
psql --host "$POSTGRES_HOSTNAME" --username "$RDS_USER"  --port $POSTGRES_PORT --dbname "$RDS_DB"  <<-EOSQL
  CREATE ROLE $POSTGRES_USER WITH PASSWORD '$POSTGRES_PASSWORD' CREATEDB CREATEROLE LOGIN;
	GRANT rds_superuser  TO $POSTGRES_USER;
	CREATE DATABASE $POSTGRES_DB;	
  GRANT ALL PRIVILEGES ON DATABASE "$POSTGRES_DB" TO $POSTGRES_USER;
EOSQL

export PGPASSWORD="$POSTGRES_PASSWORD"
psql --host "$POSTGRES_HOSTNAME" --username "$POSTGRES_USER" --port $POSTGRES_PORT --dbname "$POSTGRES_DB" <<-EOSQL 
    CREATE DATABASE "EdFi_Ods_Minimal_Template" TEMPLATE template0;
    GRANT ALL PRIVILEGES ON DATABASE "EdFi_Ods_Minimal_Template" TO $POSTGRES_USER;
EOSQL

echo "Loading Minimal Template Database from backup..."
psql --no-password --host "$POSTGRES_HOSTNAME" --username "$POSTGRES_USER" --port $POSTGRES_PORT --dbname "EdFi_Ods_Minimal_Template" --file /tmp/EdFi_Ods_Minimal_Template.sql  1> /dev/null

psql --host "$POSTGRES_HOSTNAME" --username "$POSTGRES_USER" --port $POSTGRES_PORT --dbname "$POSTGRES_DB" <<-EOSQL
    UPDATE pg_database SET datistemplate='true', datallowconn='false' WHERE datname in ('EdFi_Ods_Minimal_Template');
    CREATE DATABASE "EdFi_Ods" TEMPLATE 'EdFi_Ods_Minimal_Template';
    GRANT ALL PRIVILEGES ON DATABASE "EdFi_Ods" TO $POSTGRES_USER;
EOSQL
