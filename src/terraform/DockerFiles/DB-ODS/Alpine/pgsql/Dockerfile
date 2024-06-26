# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

# Tag postgres:13-alpine
FROM postgres@sha256:fc3670fa23119159394dfdb98eee89b30ef5a506791aea6ff7d8a4e73a8cd4a4

LABEL maintainer="Ed-Fi Alliance, LLC and Contributors <techsupport@ed-fi.org>"

ENV MINVERSION="6.1.176"
ENV MINTPDMVERSION="6.1.135"

ENV RDS_USER=${RDS_USER}
ENV RDS_PASSWORD=${RDS_PASSWORD}
ENV RDS_DB=${RDS_DB}

ENV POSTGRES_HOSTNAME=${POSTGRES_HOSTNAME}
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
ENV POSTGRES_DB=postgres
ENV POSTGRES_PORT=${POSTGRES_PORT}

COPY init-database.sh /docker-entrypoint-initdb.d/init-database.sh

RUN sed -i "s/echo 'PostgreSQL init process complete; ready for start up.'/echo 'PostgreSQL ready. Shutting down server' \&\& exit 0/" \
      /usr/local/bin/docker-entrypoint.sh
RUN sed -i "s/echo 'PostgreSQL Database directory appears to contain a database; Skipping initialization'/echo 'PostgreSQL is already initialized. Shutting down server' \&\& exit 0/" \
      /usr/local/bin/docker-entrypoint.sh

RUN apk --no-cache add unzip=~6 dos2unix=~7 && \
    # Download and extract Minimal Template for core Ed-Fi Data Model
    wget -O /tmp/OdsMinimalDatabase.zip https://pkgs.dev.azure.com/ed-fi-alliance/Ed-Fi-Alliance-OSS/_apis/packaging/feeds/EdFi/nuget/packages/EdFi.Suite3.Ods.Minimal.Template.PostgreSQL/versions/${MINVERSION}/content && \
    unzip -p /tmp/OdsMinimalDatabase.zip EdFi.Ods.Minimal.Template.sql > /tmp/EdFi_Ods_Minimal_Template.sql && \
    # Download and extract Minimal Template for Teacher Prep Data Model (TPDM)
    wget -O /tmp/TPDMOdsMinimalDatabase.zip https://pkgs.dev.azure.com/ed-fi-alliance/Ed-Fi-Alliance-OSS/_apis/packaging/feeds/EdFi/nuget/packages/EdFi.Suite3.Ods.Minimal.Template.TPDM.Core.PostgreSQL/versions/${MINTPDMVERSION}/content && \
    unzip -p /tmp/TPDMOdsMinimalDatabase.zip EdFi.Ods.Minimal.Template.TPDM.Core.sql > /tmp/EdFi_Ods_Minimal_Template_TPDM_Core.sql && \
    rm -f /tmp/*.zip && \
    dos2unix /docker-entrypoint-initdb.d/init-database.sh && \
    dos2unix /tmp/*.sql

EXPOSE 5432

CMD ["docker-entrypoint.sh", "postgres"]
