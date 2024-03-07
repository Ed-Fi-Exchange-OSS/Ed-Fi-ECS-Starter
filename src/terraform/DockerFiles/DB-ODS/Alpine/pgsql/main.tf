resource "aws_ecr_repository" "edfi_db_ods_repository" {
	  name = "dev-edfi/edfi-db-ods-repository"
	  image_scanning_configuration {
	    scan_on_push = true
	  }
}

# resource "aws_ecr_lifecycle_policy" "default_policy" {
#   repository = aws_ecr_repository.edfi_db_ods_repository.name
	

# 	  policy = <<EOF
# 	{
# 	    "rules": [
# 	        {
# 	            "rulePriority": 1,
# 	            "description": "Keep only the last ${var.untagged_images} untagged images.",
# 	            "selection": {
# 	                "tagStatus": "untagged",
# 	                "countType": "imageCountMoreThan",
# 	                "countNumber": ${var.untagged_images}
# 	            },
# 	            "action": {
# 	                "type": "expire"
# 	            }
# 	        }
# 	    ]
# 	}
# 	EOF
	

# }


# resource "null_resource" "docker_packaging" {
	
# 	  provisioner "local-exec" {
# 	    command = <<EOF
#         aws ecr get-login-password --region us-west-1 | docker login --username AWS --password-stdin 055640809004.dkr.ecr.us-west-1.amazonaws.com
# 		docker build -t dev-edfi/edfi-db-ods-repository .
# 		docker login -u mjimdev
# 		docker tag dev-edfi/edfi-db-ods-repository:latest 055640809004.dkr.ecr.us-west-1.amazonaws.com/dev-edfi/edfi-db-ods-repository:latest
# 		docker push 055640809004.dkr.ecr.us-west-1.amazonaws.com/dev-edfi/edfi-db-ods-repository:latest
# 	    EOF
# 	  }
# 	triggers = {
#     "run_at" = timestamp()
#   }

# 	  depends_on = [
# 	    aws_ecr_repository.edfi_db_ods_repository,
# 	  ]
# }



terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region  = local.aws_region
  profile = local.aws_profile

}

locals {

//////////////////////////////////////////////////////////////////////////////////////////////
/////////////  Substitute below values to match your AWS account, region & profile //////////////////////////////////////////////////////////////////////////////////////////////
  aws_account = "055640809004"   # AWS account
  aws_region  = "us-west-1"      # AWS region
  aws_profile = "default" # AWS profile
 ///////////////////////////////////////////////////////////////////////////////////////////// 
  ecr_reg   = "${local.aws_account}.dkr.ecr.${local.aws_region}.amazonaws.com" # ECR docker registry URI
  ecr_repo  = "dev-edfi/edfi-db-ods-repository"                                                           # ECR repo name
  image_tag = "latest"                                                         # image tag

  dkr_img_src_path = "${path.module}"
 // dkr_img_src_sha256 = sha256(join("", [for f in fileset(".", "${local.dkr_img_src_path}/**") : filebase64(f)]))

  # dkr_build_cmd = <<-EOT
  #       docker build -t ${local.ecr_reg}/${local.ecr_repo}:${local.image_tag} \

  #       aws --profile ${local.aws_profile} ecr get-login-password --region ${local.aws_region} | \
  #           docker login --username AWS --payesssword-stdin ${local.ecr_reg}

  #       docker push ${local.ecr_reg}/${local.ecr_repo}:${local.image_tag}
  #   EOT


  

   dkr_build_cmd = <<-EOT
        docker build -t ${local.ecr_repo}  -f  Dockerfile .
        
        aws --profile ${local.aws_profile} ecr get-login-password --region ${local.aws_region} | docker login --username AWS --password-stdin ${local.ecr_reg}
       EOT

        dkr_build_cmdTag = <<-EOT
              docker tag ${local.ecr_repo}:latest ${local.ecr_reg}/${local.ecr_repo}:latest
       EOT

  dkr_build_cmPush = <<-EOT
              docker push ${local.ecr_reg}/${local.ecr_repo}:latest
       EOT
}

variable "force_image_rebuild" {
  type    = bool
  default = false
}



# local-exec for build and push of docker image
resource "null_resource" "build_push_dkr_img" {
  # triggers = {
  #   detect_docker_source_changes = var.force_image_rebuild == true ? timestamp() : local.dkr_img_src_sha256
  # }
  provisioner "local-exec" {
    command = local.dkr_build_cmd
  }
}

resource "null_resource" "build_push_dkr_img_tag" {
  provisioner "local-exec" {
    command = local.dkr_build_cmdTag
  }
}

resource "null_resource" "build_push_dkr_img_push" {
  provisioner "local-exec" {
    command = local.dkr_build_cmPush
  }
}

output "trigged_by" {
  value = null_resource.build_push_dkr_img.triggers
}