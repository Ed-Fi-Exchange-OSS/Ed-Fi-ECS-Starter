project_name    = "edfi"
aws_region      = "us-east-2"
certificate_arn = "arn:aws:acm:us-east-2:************:certificate/c9a2a5ee-5948-47a8-be25-541c58b11111"
white_ips       = "x.x.x.x/32"
hosted_zone_id  = "************"
rds_db_username = "edfi_postgrs_usr"
rds_password    = "ekzTKhnn5O4FDQP01"
docker_images = [
  {
    repository_name = "dev-edfi/edfi-db-ods"
    dockerfile_path = "./DockerFiles/DB-ODS/Alpine/pgsql/"
    log_group       = "db-ods"
  },
  {
    repository_name = "dev-edfi/edfi-db-admin"
    dockerfile_path = "./DockerFiles/DB-Admin/Alpine/pgsql/"
    log_group       = "db-admin"
  },
  {
    repository_name = "dev-edfi/edfi-webapi"
    dockerfile_path = "./DockerFiles/Web-Ods-Api/Alpine/pgsql/"
    log_group       = "webapi"
  },
  {
    repository_name = "dev-edfi/edfi-adminapp"
    dockerfile_path = "./DockerFiles/Web-Ods-AdminApp/Alpine/pgsql/"
    log_group       = "adminapp"
  },
  {
    repository_name = "dev-edfi/edfi-swagger"
    dockerfile_path = "./DockerFiles/Web-SwaggerUI/Alpine/"
    log_group       = "swagger"
  }
]
