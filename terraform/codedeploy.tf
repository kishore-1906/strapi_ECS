########################################
# CODEDEPLOY APPLICATION
########################################
resource "aws_codedeploy_app" "ecs" {
  name             = "${var.project_name}-codedeploy"
  compute_platform = "ECS"
}

########################################
# CODEDEPLOY DEPLOYMENT GROUP
########################################
resource "aws_codedeploy_deployment_group" "ecs" {
  app_name              = aws_codedeploy_app.ecs.name
  deployment_group_name = "${var.project_name}-dg"
  service_role_arn      = aws_iam_role.codedeploy.arn

  deployment_config_name = "CodeDeployDefault.ECSCanary10Percent5Minutes"

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.this.name
    service_name = aws_ecs_service.this.name
  }

  load_balancer_info {
    target_group_pair_info {
      target_group {
        name = aws_lb_target_group.blue.name
      }

      target_group {
        name = aws_lb_target_group.green.name
      }

      prod_traffic_route {
        listener_arns = [data.aws_lb_listener.http.arn]
      }
    }
  }
}

