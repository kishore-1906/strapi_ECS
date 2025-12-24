########################################
# VPC & SUBNETS (DEFAULT)
########################################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

########################################
# EXISTING ECS SECURITY GROUP
########################################
data "aws_security_group" "ecs" {
  name   = "${var.project_name}-ecs-sg"
  vpc_id = data.aws_vpc.default.id
}

########################################
# ECS CLUSTER
########################################
resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-cluster"
}

########################################
# ECS TASK DEFINITION (STRAPI – FINAL FIX)
########################################
resource "aws_ecs_task_definition" "this" {
  family                   = "${var.project_name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"

  execution_role_arn = data.aws_iam_role.ecs_execution.arn
  task_role_arn      = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "strapi"
      image = "${aws_ecr_repository.this.repository_url}:latest"

      portMappings = [
        {
          containerPort = 1337
          protocol      = "tcp"
        }
      ]

      ####################################
      # STRAPI ENV VARS
      ####################################
      environment = [
        { name = "NODE_ENV", value = "production" },
        { name = "ADMIN_AUTH_SECRET", value = "adminauthsecret_123456789012345678901234567890" },
        { name = "API_TOKEN_SALT", value = "apitokensalt_123456789012345678901234567890" },
        { name = "TRANSFER_TOKEN_SALT", value = "transfertokensalt_123456789012345678901234567890" },
        { name = "JWT_SECRET", value = "jwtsecret_123456789012345678901234567890" },
        { name = "APP_KEYS", value = "key1,key2,key3,key4" }
      ]

      ####################################
      # CLOUDWATCH LOGS
      ####################################
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.project_name}"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

########################################
# ECS SERVICE (TEMPORARY – NO CODEDEPLOY)
########################################
resource "aws_ecs_service" "this" {
  name    = "${var.project_name}-service"
  cluster = aws_ecs_cluster.this.id

  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [data.aws_security_group.ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blue.arn
    container_name   = "strapi"
    container_port   = 1337
  }

  depends_on = [
    aws_lb_listener.http
  ]
}

