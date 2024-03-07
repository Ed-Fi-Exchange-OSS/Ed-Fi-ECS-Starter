variable "aws_region" {
  description = "The geographic area for the installation"
}
variable "aws_maximun_availability_zones" {
  default = 2
}
variable "project_name" {
  description = "The name of your project. This  will be used as a prefix to the name of some resources"
  default     = "edfi"
}
variable "rds_password" {
  description = "Password for aws database instance."
  type        = string
}
variable "rds_db_username" {
  description = "Username for aws database instance."
  type        = string
  default     = "edfi_postgrs_usr"
}

variable "db_instance_type" {
  description = "The DB instance determines the computation and memory capacity of your DB instance."
  type        = string
  default     = "db.t3.small"
}

variable "db_instance_storage" {
  description = "The amount of allocated storage in GB"
  type        = string
  default     = "21"
}

#hard code false
variable "db_instance_skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted, true to omit the snapshot"
  type        = string
  default     = "true"
}

variable "postgres_password" {
  description = "The password for the user postgres."
  type        = string
  default     = "ekzTKhnn5O4FDQP01"
}

variable "cidr" {
  description = "The Ip addresess collection that will share your VPC ."
  type        = string
  default     = "172.31.0.0/20"
}

#Rocomendation remove from terraform
variable "docker_images" {
  description = "To store a list of Repository names,docker file paths and log groups that will be used when the docker images are created"
  type = list(object({
    repository_name = string
    dockerfile_path = string
    log_group       = string
  }))
}

#Rocomendation remove from terraform
variable "image_tag" {
  description = "The version of the docker image to identify it as unique."
  type        = string
  default     = "latest"
}

# depends of the Images
variable "aws_profile" {
  description = "To get the credentials from the configured profile in order to run a command against the AWS cloud."
  type        = string
  default     = "default"
}


# memory depends of the application (swagger/api/adminapp)
variable "cpu" {
  type        = number
  description = "The limit for CPU resource. 1024 CPU units is the equivalent of 1 vCPU, 2048 CPU units is equal to 2 vCP"
  default     = 2048
}
variable "memory" {
  type        = number
  description = "The  limit of memory (in MiB) to present to the task, This value has to be compatible with the CPU."
  default     = 4096
}
variable "app_environment" {
  default = "dev" #development,dev,prod/production,stage
}
variable "certificate_arn" {
  type        = string
  description = "It is assumed that a certificate exists, if not , create a cerficate : AWS Certificate Manager >> Certificates >> Request certificate"
}
# hard code with the correct policy
variable "ssl_policy" {
  type        = string
  description = "The predefined security policies for Load Balancers"
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "hosted_zone_id" {
  type        = string
  description = "To route internet traffic for your domain or to route traffic within your VPCs when you use Route 53.  It is assumed that a certHosted zone exists, if not , create a Hosted zone:  Route 53 >> Hosted zones >> Create hosted zone"
}

variable "favorite_browser" {
  type        = string
  description = "The browser common you use to open web applications."
  default     = "chrome"
}

#computed with the domain <api-environment.domain ,  adminapp-environment.domain,swagger >
variable "domain" {
  type        = string
  description = "The name of your  domain will be associated with the IP address of the server hosting your applications."
  default     = "cst.ed-fi.org"
}


variable "encryption_key" {
  type        = string
  description = "The encryption key "
  default     = "C7JxLUnPkSRpfd+PCLj5pqk5SOf+q3+K2i/f/J0L1nI="
}

# variable "populated_key" {
#   description = "The key to be Authenticated in Swagger, After the Admin App has been created you can create An application to get the Key"
#   type=string
# }
# variable "populated_secret" {
#   description = "The secret to be Authenticated in Swagger, After the Admin App has been created you can create An application to get the Secret"
#   type=string
# }
# allow ips, change the loginc to allow only the ips list
variable "white_ips" {
  description = "The list of this IPs will be allowed to acces to the Admin App, example 177.x.x.x/32,188.x.x.x/32"
  type        = string
  default     = "73.56.126.51/32"
}


