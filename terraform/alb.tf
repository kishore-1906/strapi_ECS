########################################
# EXISTING ALB SECURITY GROUP (DATA)
########################################
data "aws_security_group" "alb" {
  name   = "${var.project_name}-alb-sg"
  vpc_id = data.aws_vpc.default.id
}

########################################
# EXISTING APPLICATION LOAD BALANCER (DATA)
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
# EXISTING ALB LISTENER (DATA)
########################################
data "aws_lb_listener" "http" {
  load_balancer_arn = data.aws_lb.this.arn
  port              = 80
}

