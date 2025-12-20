# ----------------------------
# ECS CLUSTER (Spot Enabled)
# ----------------------------
resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-cluster"

  capacity_providers = [
    "FARGATE",
    "FARGATE_SPOT"
  ]
}

# ----------------------------
# Existing CloudWatch Log Group
# ----------------------------
data "aws_cloudwatch_log_group" "this" {
  name = "/ecs/${var.project_name}"
}

# ----------------------------
# Security Group
# ----------------------------
data "aws_security_group" "ecs" {
  name   = "${var.project_name}-ecs-sg"
  vpc_id = data.aws_vpc.default.id
}

# ----------------------------
# ECS TASK DEFINITION
# ----------------------------
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
      image = var.image_uri

      portMappings = [
        {
          containerPort = 1337
        }
      ]

      environment = [
        { name = "NODE_ENV", value = "production" },
        { name = "ADMIN_JWT_SECRET", value = "adminjwtsecret123" },
        { name = "JWT_SECRET", value = "jwtsecret123" },
        { name = "APP_KEYS", value = "appkey1,appkey2,appkey3" },
        { name = "API_TOKEN_SALT", value = "apitokensalt123456" },
        { name = "TRANSFER_TOKEN_SALT", value = "transfertokensalt123456" },
        { name = "ENCRYPTION_KEY", value = "encryptionkey1234567890" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = data.aws_cloudwatch_log_group.this.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs/strapi"
        }
      }
    }
  ])
}

# ----------------------------
# ECS SERVICE (Fargate Spot)
# ----------------------------
resource "aws_ecs_service" "this" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1

  # ✅ Fargate Spot (primary)
  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 2
  }

  # ✅ Normal Fargate (fallback)
  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }

  force_new_deployment = true

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [data.aws_security_group.ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = "strapi"
    container_port   = 1337
  }

  depends_on = [aws_lb_listener.this]
}

