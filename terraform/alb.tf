
# security group for application load balancer
resource "aws_security_group" "webapp_alb_sg" {
  name        = "webapp-alb-sg"
  description = "allow incoming HTTP traffic only"
  vpc_id      = data.aws_vpc.this.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "alb-security-group-webapp",
    Environment = var.environment
  }
}

# using ALB - instances in private subnets
resource "aws_alb" "webapp_alb" {
  name                      = "webapp-alb"
  security_groups           = [aws_security_group.webapp_alb_sg.id]
  subnets                   = local.subnets
  tags = {
    Name = "webapp-alb"
  }
}

# alb target group
resource "aws_alb_target_group" "webapp-tg" {
  name     = "webapp-alb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.this.id
  health_check {
    path = "/"
    port = 80
  }
}

# listener
resource "aws_alb_listener" "http_listener" {
  load_balancer_arn = aws_alb.webapp_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.webapp-tg.arn
    type             = "forward"
  }
}