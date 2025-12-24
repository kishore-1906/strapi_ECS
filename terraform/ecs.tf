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

      # 🔥 STRAPI REQUIRED ENV VARS (THIS IS THE REAL FIX)
      environment = [
        { name = "NODE_ENV", value = "production" },

        # Admin panel JWT (MUST)
        { name = "ADMIN_JWT_SECRET", value = "adminjwtsecret_123456789012345678901234567890" },
        { name = "STRAPI_ADMIN_JWT_SECRET", value = "adminjwtsecret_123456789012345678901234567890" },

        # API + Transfer tokens
        { name = "API_TOKEN_SALT", value = "apitokensalt_123456789012345678901234567890" },
        { name = "TRANSFER_TOKEN_SALT", value = "transfertokensalt_123456789012345678901234567890" },

        # JWT for users
        { name = "JWT_SECRET", value = "jwtsecret_123456789012345678901234567890" },

        # App keys (MUST be comma-separated)
        { name = "APP_KEYS", value = "key1,key2,key3,key4" }
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

