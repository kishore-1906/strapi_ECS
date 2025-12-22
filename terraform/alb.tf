########################################
# EXISTING APPLICATION LOAD BALANCER
########################################
data "aws_lb" "this" {
  name = "${var.project_name}-alb"
}

########################################
# TARGET GROUPS (BLUE & GREEN)
########################################
resource "aws_lb_target_group" "blue" {
  name        = "${var.project_name}-blue-tg"
  port        = 1337
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"
}

resource "aws_lb_target_group" "green" {
  name        = "${var.project_name}-green-tg"
  port        = 1337
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"
}

########################################
# CREATE ALB LISTENER (HTTP :80)
########################################
resource "aws_lb_listener" "http" {
  load_balancer_arn = data.aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }
}

