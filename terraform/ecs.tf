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

      # 🔑 REQUIRED ENVIRONMENT VARIABLES FOR STRAPI
      environment = [
        { name = "NODE_ENV", value = "production" },

        # REQUIRED – fixes "Missing admin.auth.secret"
        { name = "ADMIN_JWT_SECRET", value = "supersecretadminjwt_1234567890" },

        # Optional (API auth)
        { name = "JWT_SECRET", value = "jwtsecret123" },

        # Forces new revision (remove later if needed)
        { name = "FORCE_NEW_REVISION", value = "true" }
      ]

      # CloudWatch Logs
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

  # Used only during initial creation
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

