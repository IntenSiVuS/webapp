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
  availability_zones       = local.azs
  target_group_arns = [aws_alb_target_group.webapp-tg.arn]
  
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
      min_healthy_percentage = 50
    }
  }
}
