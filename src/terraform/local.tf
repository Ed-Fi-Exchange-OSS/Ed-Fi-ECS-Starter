locals {
  tags = {
    Name = var.project_name
  }

  suffixZones              = [for name in data.aws_availability_zones.available.names : reverse(split("-", join("", [name])))[0]]
  api_url                  = "api-${var.app_environment}.${var.domain}"
  adminapp_url             = "adminapp-${var.app_environment}.${var.domain}"
  swagger_url              = "swagger-${var.app_environment}.${var.domain}"
  rds_db_name              = "${var.project_name}${var.app_environment}postgresdb"
  account_id               = data.aws_caller_identity.current.account_id
  aws_region               = data.aws_region.current.name
  db_admin_container       = "${var.project_name}_${var.app_environment}_db_ods_container"
  db_ods_container         = "${var.project_name}_${var.app_environment}_db_ods_container"
  api_container            = "${var.project_name}_${var.app_environment}_api_container"
  adminapp_container       = "${var.project_name}_${var.app_environment}_adminapp_container"
  swagger_container        = "${var.project_name}_${var.app_environment}_swagger_container"
  db_ods_task_definition   = "${var.project_name}_${var.app_environment}_db_ods_task_definition"
  db_admin_task_definition = "${var.project_name}_${var.app_environment}_db_admin_task_definition"
  api_task_definition      = "${var.project_name}_${var.app_environment}_api_task_definition"
  adminapp_task_definition = "${var.project_name}_${var.app_environment}_adminapp_task_definition"
  swagger_task_definition  = "${var.project_name}_${var.app_environment}_swagger_task_definition"

  aws_registry = "${local.account_id}.dkr.ecr.${local.aws_region}.amazonaws.com" # ECR docker registry URI
  commands_buildimages = [for img in var.docker_images : replace(join("", [
    " aws ecr get-login-password --region ${local.aws_region} | docker login --username AWS --password-stdin ${local.aws_registry}",
    " && docker build -t ${img.repository_name}  -f ${img.dockerfile_path}Dockerfile ${img.dockerfile_path}",
    " && docker tag ${img.repository_name}:${var.image_tag} ${local.aws_registry}/${img.repository_name}:${var.image_tag}",
    " && docker push ${local.aws_registry}/${img.repository_name}:${var.image_tag}"
  ]), "\r\n", " ")]



}

# output "suffixZones" {
#   value = [for name in local.suffixZones : "${name} is the sufixx"]
# }
