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
# (Used ONLY for initial service creation)
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
      image = var.image_uri

      portMappings = [
        {
          containerPort = 1337
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "NODE_ENV", value = "production" },
        { name = "JWT_SECRET", value = "jwtsecret123" }
      ]

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
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.this.id

  # Required ONLY for first creation
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

  # 🔥 CRITICAL FOR CODEDEPLOY
  lifecycle {
    ignore_changes = [
      task_definition
    ]
  }

  depends_on = [
    aws_lb_listener.http
  ]
}

