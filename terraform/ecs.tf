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
# ECS TASK DEFINITION
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

      # Image pulled from ECR
      image = "${aws_ecr_repository.this.repository_url}:latest"

      portMappings = [
        {
          containerPort = 1337
          protocol      = "tcp"
        }
      ]

      ####################################
      # REQUIRED STRAPI PRODUCTION SECRETS
      ####################################
      environment = [
        { name = "NODE_ENV", value = "production" },

        # Admin authentication (MANDATORY)
        { name = "ADMIN_JWT_SECRET", value = "admin_jwt_secret_32chars_long_xxxx" },

        # Admin API tokens (MANDATORY)
        { name = "API_TOKEN_SALT", value = "api_token_salt_32chars_long_xxxx" },

        # Content transfer (MANDATORY)
        { name = "TRANSFER_TOKEN_SALT", value = "transfer_token_salt_32chars_xxxx" },

        # Encryption (MANDATORY)
        { name = "ENCRYPTION_KEY", value = "encryption_key_32chars_xxxx" },

        # App keys (MANDATORY in production)
        { name = "APP_KEYS", value = "key1,key2,key3,key4" },

        # Optional API JWT
        { name = "JWT_SECRET", value = "jwt_secret_optional_xxxx" },

        # Force new task definition revision
        { name = "FORCE_NEW_REVISION", value = "true" }
      ]

      ####################################
      # CloudWatch Logs
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
# ECS SERVICE (CODEDEPLOY / BLUE-GREEN)
########################################
resource "aws_ecs_service" "this" {
  name    = "${var.project_name}-service"
  cluster = aws_ecs_cluster.this.id

  # Used only for initial creation
  task_definition = aws_ecs_task_definition.this.arn

  desired_count = 1

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  launch_type = "FARGATE"

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

  # REQUIRED FOR CODEDEPLOY BLUE/GREEN
  lifecycle {
    ignore_changes = [
      task_definition
    ]
  }

  depends_on = [
    aws_lb_listener.http
  ]
}

