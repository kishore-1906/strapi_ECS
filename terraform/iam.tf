########################################
# ECS EXECUTION ROLE (DATA)
########################################
data "aws_iam_role" "ecs_execution" {
  name = "${var.project_name}-ecs-execution-role"
}

########################################
# ECS TASK ROLE
########################################
resource "aws_iam_role" "ecs_task" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

########################################
# CODEDEPLOY ROLE
########################################
resource "aws_iam_role" "codedeploy" {
  name = "${var.project_name}-codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

########################################
# AWS MANAGED POLICY FOR CODEDEPLOY (REQUIRED)
########################################
resource "aws_iam_role_policy_attachment" "codedeploy_managed" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

########################################
# EXTRA INLINE POLICY (THIS FIXES YOUR ISSUE)
########################################
resource "aws_iam_role_policy" "codedeploy_extra" {
  name = "${var.project_name}-codedeploy-extra"
  role = aws_iam_role.codedeploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      ################################
      # ECS TASK SET OPERATIONS
      ################################
      {
        Effect = "Allow"
        Action = [
          "ecs:CreateTaskSet",
          "ecs:UpdateServicePrimaryTaskSet",
          "ecs:DeleteTaskSet",
          "ecs:DescribeServices",
          "ecs:DescribeTaskSets",
          "ecs:DescribeTasks"
        ]
        Resource = "*"
      },

      ################################
      # ALB TARGET GROUP OPERATIONS
      ################################
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeRules"
        ]
        Resource = "*"
      },

      ################################
      # PASS ECS ROLES (CRITICAL)
      ################################
      {
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = [
          data.aws_iam_role.ecs_execution.arn,
          aws_iam_role.ecs_task.arn
        ]
      }
    ]
  })
}

