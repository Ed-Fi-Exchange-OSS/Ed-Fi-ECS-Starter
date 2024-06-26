# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

# Tag postgres:13-alpine
FROM postgres@sha256:fc3670fa23119159394dfdb98eee89b30ef5a506791aea6ff7d8a4e73a8cd4a4
LABEL maintainer="Ed-Fi Alliance, LLC and Contributors <techsupport@ed-fi.org>"

ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
ENV POSTGRES_HOSTNAME=${POSTGRES_HOSTNAME}
ENV POSTGRES_DB=postgres
ENV API_MODE=SharedInstance

ENV ADMIN_VERSION="6.1.45"
ENV SECURITY_VERSION="6.1.56"
ENV ADMINAPP_DATABASE_VERSION="3.1.1"

COPY init-database.sh /docker-entrypoint-initdb.d/1-init-database.sh
COPY run-adminapp-migrations.sh /docker-entrypoint-initdb.d/2-run-adminapp-migrations.sh

RUN sed -i "s/echo 'PostgreSQL init process complete; ready for start up.'/echo 'PostgreSQL ready. Shutting down server' \&\& exit 0/" \
      /usr/local/bin/docker-entrypoint.sh
RUN sed -i "s/echo 'PostgreSQL Database directory appears to contain a database; Skipping initialization'/echo 'PostgreSQL is already initialized. Shutting down server' \&\& exit 0/" \
      /usr/local/bin/docker-entrypoint.sh

RUN apk --no-cache add dos2unix=~7 unzip=~6 && \
    wget -O /tmp/EdFi_Admin.zip https://pkgs.dev.azure.com/ed-fi-alliance/Ed-Fi-Alliance-OSS/_apis/packaging/feeds/EdFi/nuget/packages/EdFi.Database.Admin.PostgreSQL/versions/${ADMIN_VERSION}/content && \
    wget -O /tmp/EdFi_Security.zip https://pkgs.dev.azure.com/ed-fi-alliance/Ed-Fi-Alliance-OSS/_apis/packaging/feeds/EdFi/nuget/packages/EdFi.Database.Security.PostgreSQL/versions/${SECURITY_VERSION}/content && \
    wget -O /tmp/EdFi_AdminApp_Scripts.zip https://pkgs.dev.azure.com/ed-fi-alliance/Ed-Fi-Alliance-OSS/_apis/packaging/feeds/EdFi/nuget/packages/EdFi.Suite3.ODS.AdminApp.Database/versions/${ADMINAPP_DATABASE_VERSION}/content && \
    unzip -p /tmp/EdFi_Admin.zip EdFi_Admin.sql > /tmp/EdFi_Admin.sql && \
    unzip -p /tmp/EdFi_Security.zip EdFi_Security.sql > /tmp/EdFi_Security.sql && \
    unzip /tmp/EdFi_AdminApp_Scripts.zip PgSql/* -d /tmp/AdminAppScripts/ && \
    dos2unix /docker-entrypoint-initdb.d/1-init-database.sh && \
    dos2unix /docker-entrypoint-initdb.d/2-run-adminapp-migrations.sh && \
    dos2unix /tmp/EdFi_Admin.sql && \
    dos2unix /tmp/EdFi_Security.sql && \
    dos2unix /tmp/AdminAppScripts/PgSql/* && \
    chmod -R 777 /tmp/AdminAppScripts/PgSql

EXPOSE 5432

CMD ["docker-entrypoint.sh", "postgres"]
