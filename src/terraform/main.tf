
resource "time_sleep" "wait_40_seconds" {
  create_duration = "40s"
}

//////////////////////////////////////////////////////////////////////////////////////////////
///////////// I  M  A  G  E  S    A N D    R  E  P  O  S  I T  O  R  I  E  S /////////////////
///////////////////////////////////////////////////////////////////////////////////////////// 


#Create multiple ECR repositories
#To create multiple repositories we loop over the edfi_repositories resource using the for_each statement.
#the map of repositories was defined in the repository_name attribute from docker_images variable
resource "aws_ecr_repository" "edfi_repositories" {
  for_each = { for img in var.docker_images: img.repository_name => img }
	  name = each.value.repository_name
    force_delete =true
	  image_scanning_configuration {
	    scan_on_push = true
	  }
}

#local-exec for build and push of docker image : We run every command for login, build, tag and push images for every repository defined in var.docker_images
resource "null_resource" "build_img_ods" {  
  depends_on = [aws_ecr_repository.edfi_repositories]
  for_each =  toset( local.commands_buildimages)
  provisioner "local-exec" {
    command =  replace( each.key, "\r\n", " ")  
  }
}

///////////////////////////////////////////////////////////////////////////////
///////////// V P C   A N D   I N T  E R N E T   G A T W A Y /////////////////  MOVE THE SUBNETS HERE
//////////////////////////////////////////////////////////////////////////////
resource "aws_vpc" "edfi_vpc" {
  cidr_block                       = var.cidr
  assign_generated_ipv6_cidr_block = false
  enable_dns_hostnames             = true
  tags = {
    Name        = "${var.project_name}_vpc"
    Environment = var.app_environment
  }  
 
}

//The internet watway is a VPC component that allows communication between your VPC and the internet
resource "aws_internet_gateway" "ed_fi_igw" {
  vpc_id = aws_vpc.edfi_vpc.id
  tags = {
    Name        = "${var.project_name}_igw"
    Environment = var.app_environment
  }
}

resource "aws_route" "edfi_default_route" {
  route_table_id          = "${aws_vpc.edfi_vpc.default_route_table_id}"
  destination_cidr_block  = "0.0.0.0/0"
  gateway_id              = "${aws_internet_gateway.ed_fi_igw.id}"
}


///////////////////////////////////////////////////////////////////////////////
///////////// E C S ///////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

# A logical grouping of tasks or services
resource "aws_ecs_cluster" "cluster" {
  name ="${var.project_name}_${var.app_environment}_cluster"
  setting {
    name  = "containerInsights"
    value = "disabled"
  }
  tags = {
    Name        = "${var.project_name}_ecs"
    Environment = var.app_environment
  }
}


#Create multiple cloudwatch log groups
#To create multiple repositories we loop over the edfi_log_applications resource using the for_each statement.
#the map of repositories was defined in the log_group attribute from docker_images variable
resource "aws_cloudwatch_log_group" "edfi_log_applications" {
  for_each = { for log in var.docker_images: log.log_group => log }
	  name ="/ecs/${var.project_name}_${var.app_environment}_${each.value.log_group}"
    tags = {
      Application = "${var.project_name}_${var.app_environment}_${each.value.log_group}" 
      Environment = var.app_environment
    }
}



//////////////////////////////////////////////////////////////////////////////////////////////
///////////// CONFIGURING THE SUBNETS FOR THE RDS,API,ADMINAPP,SWAGGER AND LOAD BALANCERS ///
/////////////////////////////////////////////////////////////////////////////////////////////
#A subnet is a range of IP addresses in your VPC
# for_each = data.aws_availability_zones.available.names
# availability_zone= each.key
resource "aws_subnet" "edfi_rds_private" {
    vpc_id                  = aws_vpc.edfi_vpc.id
    count                   = var.aws_maximun_availability_zones
    cidr_block              = cidrsubnet(var.cidr, 4, 0 + count.index) 
    map_public_ip_on_launch = false
    availability_zone       = element(data.aws_availability_zones.available.names, count.index)
    tags = {
      Name     =  "${var.project_name}_rds_private_${ local.suffixZones[count.index]}"  
    }
  depends_on = [aws_vpc.edfi_vpc]
}

///////API SUBNET///
resource "aws_subnet" "edfi_api_private" {
    vpc_id                  = aws_vpc.edfi_vpc.id
    count                    = var.aws_maximun_availability_zones
    cidr_block              = cidrsubnet(var.cidr, 4, 2 + count.index) 
    map_public_ip_on_launch = false
    availability_zone       = element(data.aws_availability_zones.available.names, count.index)
    tags = {
      Name     =  "${var.project_name}_api_private_${local.suffixZones[count.index]}"  
    }
  depends_on = [aws_vpc.edfi_vpc]
}

///////ADMIN APP SUBNET///
resource "aws_subnet" "edfi_adminapp_private" {
    vpc_id                  = aws_vpc.edfi_vpc.id
    count                    = var.aws_maximun_availability_zones
    cidr_block              = cidrsubnet(var.cidr, 4, 4 + count.index) 
    map_public_ip_on_launch = false
    availability_zone       = element(data.aws_availability_zones.available.names, count.index)
    tags = {
      Name     =  "${var.project_name}_admin_app_private_${local.suffixZones[count.index]}"  
    }
  depends_on = [aws_vpc.edfi_vpc]
}


///////SWAGGER SUBNET///
resource "aws_subnet" "edfi_swagger_private" {
    vpc_id                  = aws_vpc.edfi_vpc.id
    count                    = var.aws_maximun_availability_zones
    cidr_block              = cidrsubnet(var.cidr, 4, 6 + count.index) 
    map_public_ip_on_launch = false
    availability_zone       = element(data.aws_availability_zones.available.names, count.index)
    tags = {
      Name     =  "${var.project_name}_swagger_private_${local.suffixZones[count.index]}"  
    }
  depends_on = [aws_vpc.edfi_vpc]
}


///////SUBNET FOR API APPLICATION LOAD BALANCER///
resource "aws_subnet" "edfi_api_alb" {
    vpc_id                  = aws_vpc.edfi_vpc.id
    count                    = var.aws_maximun_availability_zones
    cidr_block               = cidrsubnet(var.cidr, 4, 8 + count.index) 
    map_public_ip_on_launch = false
    availability_zone       = element(data.aws_availability_zones.available.names, count.index)
    tags = {
      Name     =  "${var.project_name}_api_alb_public_${local.suffixZones[count.index]}"  
    }
  depends_on = [aws_vpc.edfi_vpc]
}
///////SUBNET FOR ADMIN APP APPLICATION LOAD BALANCER///
resource "aws_subnet" "edfi_adminapp_alb" {
    vpc_id                  = aws_vpc.edfi_vpc.id
    count                    = var.aws_maximun_availability_zones
    cidr_block             = cidrsubnet(var.cidr, 4, 10 + count.index) 
    map_public_ip_on_launch = false
    availability_zone       = element(data.aws_availability_zones.available.names, count.index)
    tags = {
      Name     =  "${var.project_name}_admin_app_alb_public_${local.suffixZones[count.index]}"  
    }
  depends_on = [aws_vpc.edfi_vpc]
}



///////SUBNET FOR SWAGGER APPLICATION LOAD BALANCER///
resource "aws_subnet" "edfi_swagger_alb" {
    vpc_id                  = aws_vpc.edfi_vpc.id
    count                   = var.aws_maximun_availability_zones
    cidr_block               = cidrsubnet(var.cidr, 4, 12 + count.index) 
    map_public_ip_on_launch = false
    availability_zone       = element(data.aws_availability_zones.available.names, count.index)
    tags = {
      Name     =  "${var.project_name}_swagger_alb_public_${local.suffixZones[count.index]}"  
    }
  depends_on = [aws_vpc.edfi_vpc]
}


//////////////////////////////////////////////////////////////////////////////////////////////
///////////// D B  ///////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////

#Security groups allow you Control traffic to your AWS resources 
# Security Group for RDS
resource "aws_security_group" "edfi_rds" {
  name        = "${var.project_name}_rds_security_group"
  description = "Security Group for RDS"
  vpc_id      = aws_vpc.edfi_vpc.id
  tags = {
    Name     = "Security Group for RDS"
  }
}

# Allow PostgreSQL connections from the Admin App container,Api container,RDS
resource "aws_security_group_rule" "edfi_rds_svc" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          ="tcp"
  cidr_blocks       = concat(
    [for s in aws_subnet.edfi_adminapp_private : s.cidr_block] ,
    [for s in aws_subnet.edfi_api_private : s.cidr_block],
    [for s in aws_subnet.edfi_rds_private: s.cidr_block],
    split(",", var.white_ips)
  )
  security_group_id = aws_security_group.edfi_rds.id
  description       = "Allow PostgreSQL connections to the Admin App, Api and RDS"
  depends_on = [aws_security_group.edfi_rds]
}
resource "aws_security_group_rule" "edfi_rds_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          ="tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.edfi_rds.id
  description       = "Reuiered to to pull secrets or registry auth"
  depends_on = [aws_security_group.edfi_rds]
}

resource "aws_security_group_rule" "edfi_rds_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.edfi_rds.id
  description       = "Reuiered to to pull secrets or registry auth"
  depends_on = [aws_security_group.edfi_rds]
  
}


resource "aws_db_subnet_group" "edfi_postgres_db_subnet_group" {
  subnet_ids   = [for s in aws_subnet.edfi_rds_private: s.id]  
  name       = "${var.project_name}_postgres_db_subnet_group"
  tags = {
    Name = "My DB subnet group"
  }
}

//Allow you Create a RDS Database Instance( Db postgres for this example)
resource "aws_db_instance" "edfi_postgres_db" {
  identifier             =lower("${local.rds_db_name}") 
  db_name                =lower("${local.rds_db_name}") 
  instance_class         = var.db_instance_type
  allocated_storage      = var.db_instance_storage
  engine                 = "postgres"
  engine_version         = "13.11"
  storage_type           = "gp3"
  skip_final_snapshot    = var.db_instance_skip_final_snapshot
  publicly_accessible    = "true"
  vpc_security_group_ids = [aws_security_group.edfi_rds.id]
  username               = var.rds_db_username
  password               =  var.rds_password 
  db_subnet_group_name   =  aws_db_subnet_group.edfi_postgres_db_subnet_group.name 
}

resource "aws_ecs_task_definition" "edfi_db_ods" {
  depends_on = [aws_db_instance.edfi_postgres_db,aws_cloudwatch_log_group.edfi_log_applications]
  family                   = local.db_ods_task_definition
  requires_compatibilities  = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      =  var.cpu
  memory                   =  var.memory
  container_definitions = jsonencode(
    [{

          name: "${local.db_ods_container}",
          image: "${local.aws_registry}/${var.docker_images[0].repository_name}:${var.image_tag}", # ${var.docker_images[0].existing_repository}
          cpu: 0,
          portMappings = [
                {
                  name: "${local.db_ods_container}_80_tcp",
                  containerPort: 80,
                  hostPort: 80,
                  protocol: "tcp",
                  appProtocol: "http"
                }
              ],
             essential: true,
            environment: [
                {
                    name: "RDS_PASSWORD",
                    value: "${var.rds_password}"
                },
                {
                    name: "RDS_USER",
                    value: "${var.rds_db_username}"
                },
                {
                    name: "POSTGRES_HOSTNAME",
                    value:  replace( aws_db_instance.edfi_postgres_db.endpoint, ":${5432}", "")
                },
                {
                    name: "POSTGRES_PASSWORD",
                    value: "${var.postgres_password}"
                },
                {
                    name: "POSTGRES_PORT",
                    value: "5432"
                },
                {
                    name: "RDS_DB",
                    value: "${local.rds_db_name}"
                }
            ],

            environmentFiles: [],
            mountPoints: [],
            volumesFrom: [],
            ulimits: [],
            logConfiguration: {
                logDriver: "awslogs",
                options: {
                  awslogs-create-group: "true",
                    awslogs-group:"/ecs/${var.project_name}_${var.app_environment}_${var.docker_images[0].log_group}",
                    awslogs-region: "${local.aws_region}",
                    awslogs-stream-prefix: "ecs"
                },
                secretOptions: []
            }   
           
    }]
  )  
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  execution_role_arn       = "arn:aws:iam::${local.account_id}:role/ecsTaskExecutionRole"
  task_role_arn            = "arn:aws:iam::${local.account_id}:role/ecsTaskExecutionRole"
}

resource "time_sleep" "wait_60_seconds" {
  depends_on = [aws_ecs_service.edfi_api_service]
  create_duration = "60s"
}

resource "aws_ecs_task_definition" "edfi_db_migrations" {
  depends_on = [aws_ecs_task_definition.edfi_db_ods,aws_db_instance.edfi_postgres_db,aws_cloudwatch_log_group.edfi_log_applications]
  family                   = local.db_admin_task_definition
  requires_compatibilities  = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      =  var.cpu
  memory                   =  var.memory
  container_definitions = jsonencode(
    [{

          name: "${local.db_admin_container}",
          image: "${local.aws_registry}/${var.docker_images[1].repository_name}:${var.image_tag}",
          cpu: 0,
          portMappings = [
                {
                  name: "${local.db_admin_container}_80_tcp",
                  containerPort: 80,
                  hostPort: 80,
                  protocol: "tcp",
                  appProtocol: "http"
                }
              ],
             essential: true,
            environment: [              
                {
                    name: "POSTGRES_HOSTNAME",
                    value:replace( aws_db_instance.edfi_postgres_db.endpoint, ":${5432}", "")
                },
                {
                    name: "POSTGRES_PASSWORD",
                    value: "${var.postgres_password}"
                }
            ],

            environmentFiles: [],
            mountPoints: [],
            volumesFrom: [],
            ulimits: [],
            logConfiguration: {
                logDriver: "awslogs",
                options: {
                  awslogs-create-group: "true",
                   awslogs-group:"/ecs/${var.project_name}_${var.app_environment}_${var.docker_images[1].log_group}",
                    awslogs-region: "${local.aws_region}",
                    awslogs-stream-prefix: "ecs"
                },
                secretOptions: []
            }   
           
    }]
  )  
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  execution_role_arn       = "arn:aws:iam::${local.account_id}:role/ecsTaskExecutionRole"
  task_role_arn            = "arn:aws:iam::${local.account_id}:role/ecsTaskExecutionRole"
}



//////////////////////////////////////////////////////////////////////////////////////////////
///////////// A P I   C O N F I G U R A T I O N ///
/////////////////////////////////////////////////////////////////////////////////////////////

# Security Group for API container service
resource "aws_security_group" "edfi_api_svc_sg" {
  name        = "${var.project_name}_api_security_group"
  description = "Security Group for API"
  vpc_id      = aws_vpc.edfi_vpc.id
  tags = {
    Name     = "Security Group for API"
  }
}
#Security Group for API to give access to the Api container service via http
resource "aws_security_group_rule" "edfi_api_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          ="tcp"
  cidr_blocks       = [for s in aws_subnet.edfi_api_private : s.cidr_block] 
  security_group_id = aws_security_group.edfi_api_svc_sg.id
  description       = "Allow HTTP connections to the ODS/API"
  depends_on = [aws_security_group.edfi_api_svc_sg]
}
#Security Group for API to give access to the Api container, adminapp container, swagger container  service via https
resource "aws_security_group_rule" "edfi_api_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          ="tcp"
  cidr_blocks       = concat(
    [for s in aws_subnet.edfi_adminapp_private : s.cidr_block] ,
    [for s in aws_subnet.edfi_api_private : s.cidr_block],
    [for s in aws_subnet.edfi_swagger_private: s.cidr_block]
  )

  security_group_id = aws_security_group.edfi_api_svc_sg.id
  description       = "Allow HTTPS connections to the ODS/API"
  depends_on = [aws_security_group.edfi_api_svc_sg]
}

resource "aws_security_group_rule" "edfi_api_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.edfi_api_svc_sg.id
  description       = "allow ODS/API connections anywhere"
  depends_on = [aws_security_group.edfi_api_svc_sg]
}
# resource "aws_security_group_rule" "edfi_api_ingress" {
#   type              = "ingress"
#   from_port         = 0
#   to_port           = 0
#   protocol          = "-1"
#   cidr_blocks       = ["0.0.0.0/0"]
#   security_group_id = aws_security_group.edfi_api_svc_sg.id
#   description       = "Allow all connections to the ODS/API from anywhere"
#   depends_on = [aws_security_group.edfi_api_svc_sg]  
# }


# Security Group for API application load balancer
resource "aws_security_group" "edfi_api_alb_sg" {
  name        = "${var.project_name}_api_alb_sg"
  description = "Application load balancer SG"
  vpc_id      = aws_vpc.edfi_vpc.id
  tags = {
    Name     = "API ALB SG"
  }

  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    protocol = "tcp"
    to_port = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]

  }

}


# Target Group
resource "aws_alb_target_group" "edfi_api_alb_tg" {
  name = "${var.project_name}-api-alb-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.edfi_vpc.id
  target_type = "ip"
  health_check {
    path = "/"
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Application Load Balancer
resource "aws_alb" "edfi_api_alb" {
   load_balancer_type = "application" 
  name = "${var.project_name}-api-application-lb"
  subnets =[for s in aws_subnet.edfi_api_alb : s.id]
  security_groups = [aws_security_group.edfi_api_alb_sg.id]
}

# 1st ALB Listener
resource "aws_alb_listener" "edfi_api_alb_listener"   {
  load_balancer_arn = aws_alb.edfi_api_alb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      status_code = "HTTP_301"
      protocol = "HTTPS"
      port = "443"
    }
  }
}

# Secure ALB Listener
resource "aws_alb_listener" "edfi_api_alb_secure_listener" {
  load_balancer_arn = aws_alb.edfi_api_alb.arn
  port = 443
  protocol = "HTTPS"
  certificate_arn = var.certificate_arn
  ssl_policy = var.ssl_policy
  default_action {
    type = "forward"
    target_group_arn = aws_alb_target_group.edfi_api_alb_tg.arn
  }
}


resource "aws_ecs_task_definition" "edfi_api_task" {
  depends_on = [aws_ecs_task_definition.edfi_db_migrations,
                aws_cloudwatch_log_group.edfi_log_applications]
  family                   = local.api_task_definition
  requires_compatibilities  = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      =  var.cpu
  memory                   =  var.memory
  container_definitions = jsonencode(
    [{

          name: "${local.api_container}",
          image: "${local.aws_registry}/${var.docker_images[2].repository_name}:${var.image_tag}",
          cpu: 0,
          portMappings = [
                {
                  name: "${local.api_container}_80_tcp",
                  containerPort: 80,
                  hostPort: 80,
                  protocol: "tcp",
                  appProtocol: "http"
                }
              ],
             essential: true,
            environment: [
                {
                    name: "ADMIN_POSTGRES_HOST",
                    value:replace( aws_db_instance.edfi_postgres_db.endpoint, ":${5432}", "")
                },
                {
                    name: "POSTGRES_PORT",
                    value: "5432"
                },
                {
                    name: "POSTGRES_PASSWORD",
                    value: "${var.postgres_password}"
                }
            ],

            environmentFiles: [],
            mountPoints: [],
            volumesFrom: [],
            ulimits: [],
            logConfiguration: {
                logDriver: "awslogs",
                options: {
                  awslogs-create-group: "true",
                    awslogs-group:"/ecs/${var.project_name}_${var.app_environment}_${var.docker_images[2].log_group}",
                    awslogs-region: "${local.aws_region}",
                    awslogs-stream-prefix: "ecs"
                },
                secretOptions: []
            }   
           
    }]
  )  
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  execution_role_arn       = "arn:aws:iam::${local.account_id}:role/ecsTaskExecutionRole"
  task_role_arn            = "arn:aws:iam::${local.account_id}:role/ecsTaskExecutionRole"
}



resource "null_resource" "db_ods_task_run" {
  depends_on = [
    aws_ecs_task_definition.edfi_db_ods, // to make sure that you run task only after creating the task definition
    aws_db_instance.edfi_postgres_db 
  ]
 provisioner "local-exec" {
    command = <<EOF
    aws ecs run-task --cluster ${aws_ecs_cluster.cluster.name} --task-definition ${aws_ecs_task_definition.edfi_db_ods.arn} --launch-type=FARGATE --network-configuration=awsvpcConfiguration={subnets=${jsonencode([for s in aws_subnet.edfi_rds_private : s.id])},securityGroups=[${aws_security_group.edfi_rds.id}],assignPublicIp="ENABLED"}
    EOF
  }
}
resource "null_resource" "migration_task_run" {
  depends_on = [
    aws_ecs_task_definition.edfi_db_migrations,   // to make sure that you run task only after creating the task definition
    aws_db_instance.edfi_postgres_db,
    null_resource.db_ods_task_run
  ]
 provisioner "local-exec" {
    command = <<EOF
    aws ecs run-task --cluster ${aws_ecs_cluster.cluster.name} --task-definition ${aws_ecs_task_definition.edfi_db_migrations.arn} --launch-type=FARGATE --network-configuration=awsvpcConfiguration={subnets=${jsonencode([for s in aws_subnet.edfi_rds_private : s.id])},securityGroups=[${aws_security_group.edfi_rds.id}],assignPublicIp="ENABLED"}
    EOF
  }
}


resource "aws_ecs_service" "edfi_api_service" {
  depends_on = [null_resource.migration_task_run, null_resource.db_ods_task_run, aws_ecs_task_definition.edfi_api_task]

  name            = "${var.project_name}_api_service"
  cluster         =  aws_ecs_cluster.cluster.arn
  task_definition = aws_ecs_task_definition.edfi_api_task.arn
  desired_count   = 1
  scheduling_strategy="REPLICA"
  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    base              = 1
    weight            = 100
  }
  network_configuration {
    subnets =  [for s in aws_subnet.edfi_api_private : s.id] 
    security_groups  = [ aws_security_group.edfi_api_alb_sg.id]
    assign_public_ip = true 
  }
  load_balancer {
     target_group_arn = aws_alb_target_group.edfi_api_alb_tg.arn
     container_name = "${local.api_container}"
     container_port = 80
  }
}



resource "aws_route53_record" "api_dns_record" {
   depends_on = [aws_alb.edfi_api_alb]
     zone_id = var.hosted_zone_id
     name    = local.api_url
     type    = "A"

     alias {
       name                   = "${aws_alb.edfi_api_alb.dns_name}"
       zone_id                = "${aws_alb.edfi_api_alb.zone_id}"
       evaluate_target_health = true
     }
   }
   # remove this resource
# This resource will create (at least) 60 seconds after null_resource.previous
resource "null_resource" "web_api" {
    depends_on = [ aws_ecs_service.edfi_api_service,time_sleep.wait_60_seconds]
    provisioner "local-exec" {
    command = "start ${var.favorite_browser}  ${local.api_url}"
    }
 }


//////////////////////////////////////////////////////////////////////////////////////////////
///////////// A D M I N   A P P   C O N F I G U R A T I O N /////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////


# Security Group for AdminApp container service
resource "aws_security_group" "edfi_adminapp_svc_sg" {
  name        = "${var.project_name}_adminapp_security_group"
  description = "Security Group for AdminApp"
  vpc_id      = aws_vpc.edfi_vpc.id
  tags = {
    Name     = "Security Group for AdminApp"
  }
}
#Security Group for AdminApp to give access to the AdminApp container service via http
resource "aws_security_group_rule" "edfi_AdminApp_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          ="tcp"
  cidr_blocks       = [for s in aws_subnet.edfi_adminapp_private : s.cidr_block] 
  security_group_id = aws_security_group.edfi_adminapp_svc_sg.id
  description       = "Allow HTTP connections to the ODS/AdminApp"
  depends_on = [aws_security_group.edfi_adminapp_svc_sg]
}
#Security Group for AdminApp to give access to the AdminApp container service via https
resource "aws_security_group_rule" "edfi_AdminApp_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          ="tcp"
  cidr_blocks       = [for s in aws_subnet.edfi_adminapp_private : s.cidr_block] 
  security_group_id = aws_security_group.edfi_adminapp_svc_sg.id
  description       = "Allow HTTPS connections to the ODS/AdminApp"
  depends_on = [aws_security_group.edfi_adminapp_svc_sg]
}

resource "aws_security_group_rule" "edfi_AdminApp_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.edfi_adminapp_svc_sg.id
  description       = "allow AdminApp connections anywhere "
  depends_on = [aws_security_group.edfi_adminapp_svc_sg]
}

# Security Group for AdminApp application load balancer
resource "aws_security_group" "edfi_adminapp_alb_sg" {
  name        = "${var.project_name}_admin_app_alb_sg"
  description = "Application load balancer SG"
  vpc_id      = aws_vpc.edfi_vpc.id
  tags = {
    Name     = "AdminApp ALB SG"
  }

  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    protocol = "tcp"
    to_port = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]

  }

}


# Target Group
resource "aws_alb_target_group" "edfi_adminapp_alb_tg" {
  name = "${var.project_name}-adminapp-alb-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.edfi_vpc.id
  target_type = "ip"
  health_check {
    path = "/"
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Application Load Balancer
resource "aws_alb" "edfi_adminapp_alb" {
   load_balancer_type = "application" 
  name = "${var.project_name}-adminapp-application-lb"
  subnets =[for s in aws_subnet.edfi_adminapp_alb : s.id]
  security_groups = [aws_security_group.edfi_adminapp_alb_sg.id]
}

# 1st ALB Listener
resource "aws_alb_listener" "edfi_adminapp_alb_listener"   {
  load_balancer_arn = aws_alb.edfi_adminapp_alb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      status_code = "HTTP_301"
      protocol = "HTTPS"
      port = "443"
    }
  }
}

# Secure ALB Listener
resource "aws_alb_listener" "edfi_adminapp_alb_secure_listener" {
  load_balancer_arn = aws_alb.edfi_adminapp_alb.arn
  port = 443
  protocol = "HTTPS"
  certificate_arn = var.certificate_arn
  ssl_policy = var.ssl_policy
  default_action {
    type = "forward"
    target_group_arn = aws_alb_target_group.edfi_adminapp_alb_tg.arn
  }
}



resource "aws_ecs_task_definition" "edfi_adminapp_task" {
  depends_on = [aws_ecs_task_definition.edfi_db_migrations, aws_alb.edfi_api_alb,
   null_resource.db_ods_task_run, null_resource.migration_task_run,
   aws_cloudwatch_log_group.edfi_log_applications,aws_route53_record.api_dns_record
   ]
  family                   = local.adminapp_task_definition
  requires_compatibilities  = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      =  var.cpu
  memory                   =  var.memory
  container_definitions = jsonencode(
    [{

          name: "${local.adminapp_container}",
          image: "${local.aws_registry}/${var.docker_images[3].repository_name}:${var.image_tag}",
          cpu: 0,
          portMappings = [
                {
                  name: "${local.adminapp_container}_80_tcp",
                  containerPort: 80,
                  hostPort: 80,
                  protocol: "tcp",
                  appProtocol: "http"
                }
              ],
             essential: true,
            environment: [
                  {
                    name: "API_INTERNAL_URL",
                   value: "https://${local.api_url}"
                },            
                {
                    name: "ADMIN_POSTGRES_HOST",
                    value:replace( aws_db_instance.edfi_postgres_db.endpoint, ":${5432}", "")
                },
                {
                    name: "POSTGRES_PORT",
                    value: "5432"
                },
                {
                    name: "POSTGRES_PASSWORD",
                    value: "${var.postgres_password}"
                },
                 {
                    name: "ENCRYPTION_KEY",
                    value: "${var.encryption_key}"
                },
                 {
                    name: "API_EXTERNAL_URL",
                   value: "https://${local.api_url}"
                }
            ],

            environmentFiles: [],
            mountPoints: [],
            volumesFrom: [],
            ulimits: [],
            logConfiguration: {
                logDriver: "awslogs",
                options: {
                  awslogs-create-group: "true",
                    awslogs-group:"/ecs/${var.project_name}_${var.app_environment}_${var.docker_images[3].log_group}",
                    awslogs-region: "${local.aws_region}",
                    awslogs-stream-prefix: "ecs"
                },
                secretOptions: []
            }   
           
    }]
  )  
  runtime_platform {
     operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  execution_role_arn       = "arn:aws:iam::${local.account_id}:role/ecsTaskExecutionRole"
  task_role_arn            = "arn:aws:iam::${local.account_id}:role/ecsTaskExecutionRole"
}



resource "aws_ecs_service" "edfi_adminapp_service" {
  depends_on = [null_resource.migration_task_run, null_resource.db_ods_task_run,aws_ecs_task_definition.edfi_db_migrations,
                aws_ecs_task_definition.edfi_api_task, aws_ecs_service.edfi_api_service,time_sleep.wait_60_seconds]

  name            = "${var.project_name}_adminapp_service"
  cluster         =   aws_ecs_cluster.cluster.arn
  task_definition = aws_ecs_task_definition.edfi_adminapp_task.arn
  desired_count   = 1
  scheduling_strategy="REPLICA"
  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    base              = 1
    weight            = 100
  }

  network_configuration {
    subnets =  [for s in aws_subnet.edfi_adminapp_private : s.id] 
    security_groups  = [ aws_security_group.edfi_adminapp_alb_sg.id]
    assign_public_ip = true 
  }
  load_balancer {
     target_group_arn = aws_alb_target_group.edfi_adminapp_alb_tg.arn
     container_name = "${local.adminapp_container}"
     container_port = 80
  }
}

resource "aws_route53_record" "adminapp_dns_record" {
   depends_on = [aws_alb.edfi_adminapp_alb]
     zone_id = var.hosted_zone_id
     name    = local.adminapp_url
     type    = "A"

     alias {
       name                   = "${aws_alb.edfi_adminapp_alb.dns_name}"
       zone_id                = "${aws_alb.edfi_adminapp_alb.zone_id}"
       evaluate_target_health = true
     }
   }
# This resource will create (at least) 60 seconds after null_resource.previous
resource "null_resource" "web_AdminApp" {
    depends_on = [ aws_ecs_service.edfi_adminapp_service,time_sleep.wait_60_seconds]
    provisioner "local-exec" {
    command = "start ${var.favorite_browser}  ${local.adminapp_url}"
    }
 }




//////////////////////////////////////////////////////////////////////////////////////////////
///////////// S W A G G E R   C O N F I G U R A T I O N /////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////


# Security Group for Swagger container service
resource "aws_security_group" "edfi_swagger_svc_sg" {
  name        = "${var.project_name}_swagger_security_group"
  description = "Security Group for Swagger"
  vpc_id      = aws_vpc.edfi_vpc.id
  tags = {
    Name     = "Security Group for Swagger"
  }
}
#Security Group for Swagger to give access to the Swagger container service via http
resource "aws_security_group_rule" "edfi_swagger_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          ="tcp"
  cidr_blocks       = [for s in aws_subnet.edfi_swagger_private : s.cidr_block] 
  security_group_id = aws_security_group.edfi_swagger_svc_sg.id
  description       = "Allow HTTP connections to the ODS/Swagger"
  depends_on = [aws_security_group.edfi_swagger_svc_sg]
}
#Security Group for Swagger to give access to the Swagger container service via https
resource "aws_security_group_rule" "edfi_swagger_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          ="tcp"
  cidr_blocks       = [for s in aws_subnet.edfi_swagger_private : s.cidr_block] 
  security_group_id = aws_security_group.edfi_swagger_svc_sg.id
  description       = "Allow HTTPS connections to the ODS/Swagger"
  depends_on = [aws_security_group.edfi_swagger_svc_sg]
}

resource "aws_security_group_rule" "edfi_swagger_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.edfi_swagger_svc_sg.id
  description       = "allow swagger connections anywhere"
  depends_on = [aws_security_group.edfi_swagger_svc_sg]
}

# Security Group for Swagger application load balancer
resource "aws_security_group" "edfi_swagger_alb_sg" {
  name        = "${var.project_name}_swagger_alb_sg"
  description = "Application load balancer SG"
  vpc_id      = aws_vpc.edfi_vpc.id
  tags = {
    Name     = "Swagger ALB SG"
  }

  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    protocol = "tcp"
    to_port = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]

  }

}


# Target Group
resource "aws_alb_target_group" "edfi_swagger_alb_tg" {
  name = "${var.project_name}-Swagger-alb-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.edfi_vpc.id
  target_type = "ip"
  health_check {
    path = "/"
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Application Load Balancer
resource "aws_alb" "edfi_swagger_alb" {
   load_balancer_type = "application" 
  name = "${var.project_name}-Swagger-application-lb"
  subnets =[for s in aws_subnet.edfi_swagger_alb : s.id]
  security_groups = [aws_security_group.edfi_swagger_alb_sg.id]
}

# 1st ALB Listener
resource "aws_alb_listener" "edfi_swagger_alb_listener"   {
  load_balancer_arn = aws_alb.edfi_swagger_alb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      status_code = "HTTP_301"
      protocol = "HTTPS"
      port = "443"
    }
  }
}

# Secure ALB Listener
resource "aws_alb_listener" "edfi_swagger_alb_secure_listener" {
  load_balancer_arn = aws_alb.edfi_swagger_alb.arn
  port = 443
  protocol = "HTTPS"
  certificate_arn = var.certificate_arn
  ssl_policy = var.ssl_policy
  default_action {
    type = "forward"
    target_group_arn = aws_alb_target_group.edfi_swagger_alb_tg.arn
  }
}



resource "aws_ecs_task_definition" "edfi_swagger_task" {
  depends_on = [aws_ecs_task_definition.edfi_db_migrations, aws_alb.edfi_api_alb,
   null_resource.db_ods_task_run, null_resource.migration_task_run,
   aws_cloudwatch_log_group.edfi_log_applications,aws_route53_record.api_dns_record
   ]
  family                   = local.swagger_task_definition
  requires_compatibilities  = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      =  var.cpu
  memory                   =  var.memory
  container_definitions = jsonencode(
    [{

          name: "${local.swagger_container}",
          image: "${local.aws_registry}/${var.docker_images[4].repository_name}:${var.image_tag}",
          cpu: 0,
          portMappings = [
                {
                  name: "${local.swagger_container}_80_tcp",
                  containerPort: 80,
                  hostPort: 80,
                  protocol: "tcp",
                  appProtocol: "http"
                }
              ],
             essential: true,
            environment: [
               {
                    name: "POSTGRES_HOSTNAME",
                    value:replace( aws_db_instance.edfi_postgres_db.endpoint, ":${5432}", "")
                },
                {
                    name: "WebApiVersionUrl",
                   value: "https://${local.api_url}"
                }
            ],

            environmentFiles: [],
            mountPoints: [],
            volumesFrom: [],
            ulimits: [],
            logConfiguration: {
                logDriver: "awslogs",
                options: {
                  awslogs-create-group: "true",
                    awslogs-group:"/ecs/${var.project_name}_${var.app_environment}_${var.docker_images[4].log_group}",
                    awslogs-region: "${local.aws_region}",
                    awslogs-stream-prefix: "ecs"
                },
                secretOptions: []
            }   
           
    }]
  )  
  runtime_platform {
     operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  execution_role_arn       = "arn:aws:iam::${local.account_id}:role/ecsTaskExecutionRole"
  task_role_arn            = "arn:aws:iam::${local.account_id}:role/ecsTaskExecutionRole"
}



resource "aws_ecs_service" "edfi_swagger_service" {
  depends_on = [null_resource.migration_task_run, null_resource.db_ods_task_run,aws_ecs_task_definition.edfi_db_migrations, aws_ecs_task_definition.edfi_api_task, aws_ecs_service.edfi_api_service]

  name            = "${var.project_name}_swagger_service"
  cluster         =   aws_ecs_cluster.cluster.arn # var.arn_cluster
  task_definition = aws_ecs_task_definition.edfi_swagger_task.arn
  desired_count   = 1
  scheduling_strategy="REPLICA"
  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    base              = 1
    weight            = 100
  }

  network_configuration {
    subnets =  [for s in aws_subnet.edfi_swagger_private : s.id] 
    security_groups  = [ aws_security_group.edfi_swagger_alb_sg.id]
    assign_public_ip = true 
  }
  load_balancer {
     target_group_arn = aws_alb_target_group.edfi_swagger_alb_tg.arn
     container_name = "${local.swagger_container}"
     container_port = 80
  }
}

resource "aws_route53_record" "swagger_dns_record" {
   depends_on = [aws_alb.edfi_swagger_alb]
     zone_id = var.hosted_zone_id
     name    = local.swagger_url
     type    = "A"

     alias {
       name                   = "${aws_alb.edfi_swagger_alb.dns_name}"
       zone_id                = "${aws_alb.edfi_swagger_alb.zone_id}"
       evaluate_target_health = true
     }
   }
# This resource will create (at least) 60 seconds after null_resource.previous
resource "null_resource" "web_Swagger" {
    depends_on = [ aws_ecs_service.edfi_swagger_service,time_sleep.wait_60_seconds]
    provisioner "local-exec" {
    command = "start ${var.favorite_browser}  ${local.swagger_url}"
    }
 }



//////////////////////////////////////////////////////////////////////////////////////////////
///////////// W E B   A P P L I C A T I O N   F I R E W A L L ////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////


resource "aws_wafv2_ip_set" "allowed_ips" {
  name = "whitelist_ips"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses = split(",", var.white_ips)
}

resource "aws_wafv2_web_acl" "firewall" {
  name = "firewall"
  scope = "REGIONAL"
  default_action {
    block {}
  }

  rule {
    name     = "allowed_ips"
    priority = 1

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.allowed_ips.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "allowed_ips"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "blocked"
    sampled_requests_enabled   = true
  }
}
resource "aws_wafv2_web_acl_association" "waf_alb_adminapp_alb" {
     depends_on = [
        aws_alb.edfi_adminapp_alb,
        aws_wafv2_web_acl.firewall,
        null_resource.web_AdminApp
    ]
  resource_arn = aws_alb.edfi_adminapp_alb.arn
  web_acl_arn   = aws_wafv2_web_acl.firewall.arn
}