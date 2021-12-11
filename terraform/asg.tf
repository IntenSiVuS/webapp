# creating launch configuration
resource "aws_launch_configuration" "webapp" {
  image_id               = local.ami
  instance_type          = "t2.micro"
  security_groups        = [aws_security_group.webapp_ec2.id]
  user_data              = file("userdata.sh")
  lifecycle {
    create_before_destroy = true
  }
}

# creating auto-scaling group
resource "aws_autoscaling_group" "webapp" {
  name                        = "webapp-autoscaling-group"
  launch_configuration = aws_launch_configuration.webapp.id
  #count                   = "${length(var.azs)}"
  availability_zones       = local.azs
  target_group_arns = [aws_alb_target_group.webapp-tg.arn]
  #vpc_zone_identifier = ["${element(aws_subnet.private.*.id, count.index)}"]
  #load_balancers = [aws_alb.webapp_alb.name]

  #availability_zones       = "[${var.azs.*}]"
  #vpc_zone_identifier       = ["${aws_subnet.private.*.id}"]

  desired_capacity = 2
  max_size = 3
  min_size = 1

  health_check_type = "ELB"
  tag {
    key = "Name"
    value = "webapp-asg"
    propagate_at_launch = true
  }

   instance_refresh {
    strategy = "Rolling"
    preferences {
      // You probably want more than 50% healthy depending on how much headroom you have
      min_healthy_percentage = 50
    }
  }
}
