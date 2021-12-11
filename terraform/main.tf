provider "aws" {
  region = var.region
}

data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = ["default"]
  }
}

locals {
  subnets = ["subnet-0ef5cd66", "subnet-f2a7e288"]
  ami     = "ami-0e8f6957a4eb67446"
  azs     = ["eu-central-1a", "eu-central-1b"]
}

# module "asg" {
#   source  = "terraform-aws-modules/autoscaling/aws"
#   version = "~> 4.0"

#   # Autoscaling group
#   name = "webapp-asg"

#   min_size                  = 0
#   max_size                  = 2
#   desired_capacity          = 1
#   wait_for_capacity_timeout = 0
#   health_check_type         = "EC2"
#   vpc_zone_identifier       = [
#       "subnet-0ef5cd66", # AZ eu-central-1a 
#       "subnet-f2a7e288"  # AZ eu-central-1b 
#       ]

#   initial_lifecycle_hooks = [
#     {
#       name                  = "ExampleStartupLifeCycleHook"
#       default_result        = "CONTINUE"
#       heartbeat_timeout     = 60
#       lifecycle_transition  = "autoscaling:EC2_INSTANCE_LAUNCHING"
#       notification_metadata = jsonencode({ "hello" = "world" })
#     },
#     {
#       name                  = "ExampleTerminationLifeCycleHook"
#       default_result        = "CONTINUE"
#       heartbeat_timeout     = 180
#       lifecycle_transition  = "autoscaling:EC2_INSTANCE_TERMINATING"
#       notification_metadata = jsonencode({ "goodbye" = "world" })
#     }
#   ]

#   instance_refresh = {
#     strategy = "Rolling"
#     preferences = {
#       min_healthy_percentage = 50
#     }
#     triggers = ["tag"]
#   }

#   # Launch template
#   lt_name                = "webapp-asg"
#   description            = "Launch template for webapp"
#   update_default_version = true

#   use_lt    = true
#   create_lt = true

#   # Using latest ECS optimized AMI 
#   image_id          = "ami-0e8f6957a4eb67446"
#   instance_type     = "t2.micro"
#   ebs_optimized     = true
#   enable_monitoring = true

#   block_device_mappings = [
#     {
#       # Root volume
#       device_name = "/dev/xvda"
#       no_device   = 0
#       ebs = {
#         delete_on_termination = true
#         encrypted             = true
#         volume_size           = 20
#         volume_type           = "gp2"
#       }
#     }, 
#     # {
#     #   device_name = "/dev/sda1"
#     #   no_device   = 1
#     #   ebs = {
#     #     delete_on_termination = true
#     #     encrypted             = true
#     #     volume_size           = 30
#     #     volume_type           = "gp2"
#     #   }
#     # }
#   ]

# #   capacity_reservation_specification = {
# #     capacity_reservation_preference = "open"
# #   }

# #   cpu_options = {
# #     core_count       = 1
# #     threads_per_core = 1
# #   }

# #   credit_specification = {
# #     cpu_credits = "standard"
# #   }

# #   instance_market_options = {
# #     market_type = "spot"
# #     spot_options = {
# #       block_duration_minutes = 60
# #     }
# #   }

#   metadata_options = {
#     http_endpoint               = "enabled"
#     http_tokens                 = "required"
#     http_put_response_hop_limit = 32
#   }

#   network_interfaces = [
#     {
#       delete_on_termination = true
#       description           = "eth0"
#       device_index          = 0
#       security_groups       = ["sg-12345678"]
#     }
#   ]

# #   placement = {
# #     availability_zone = "us-west-1b"
# #   }

# #   tag_specifications = [
# #     {
# #       resource_type = "instance"
# #       tags          = { WhatAmI = "Instance" }
# #     },
# #     {
# #       resource_type = "volume"
# #       tags          = { WhatAmI = "Volume" }
# #     },
# #     {
# #       resource_type = "spot-instances-request"
# #       tags          = { WhatAmI = "SpotInstanceRequest" }
# #     }
# #   ]

#   tags = [
#     {
#       key                 = "Environment"
#       value               = "dev"
#       propagate_at_launch = true
#     },
#     {
#       key                 = "Project"
#       value               = "webapp"
#       propagate_at_launch = true
#     },
#   ]

# #   tags_as_map = {
# #     extra_tag1 = "extra_value1"
# #     extra_tag2 = "extra_value2"
# #   }
# }

# data "aws_ami" "latest_ecs" {
#   most_recent = true
#   owners      = ["amazon"] # AWS

#   filter {
#     name   = "name"
#     values = ["amzn2-ami-ecs-hvm-*-ebs"]
#   }

#   filter {
#     name   = "architecture"
#     values = ["x86_64"]
#   }
# }

# resource "aws_launch_configuration" "ecs-launch-configuration" {
#   name_prefix          = "webapp"
#   image_id             = data.aws_ami.latest_ecs.*.image_id[0]
#   instance_type        = var.service_instance_type
#   iam_instance_profile = aws_iam_instance_profile.instance-profile.id

#   spot_price           = (var.spot_price != "" && var.environment == "production") ? "" : var.spot_price

#   root_block_device {
#     volume_type           = "standard"
#     volume_size           = var.root_ebs_volume_size
#     delete_on_termination = true
#   }

#   lifecycle {
#     create_before_destroy = true
#   }

#   security_groups = [
#     module.aws_ecs_sg.this_security_group_id,
#     module.aws_service_td_sg.this_security_group_id
#   ]
#   key_name  = var.ecs_key_pair_name
#   user_data = data.template_cloudinit_config.userdata.rendered
# }

# data "template_cloudinit_config" "userdata" {
#   part {
#     content = var.node_exporter_user_data
#   }

#   part {
#     content = <<EOF
#                                   #!/bin/bash
#                                   echo ECS_CLUSTER=${var.service_name}-${var.environment} >> /etc/ecs/ecs.config
#                                   echo ECS_AVAILABLE_LOGGING_DRIVERS=${var.ecs_logging} >> /etc/ecs/ecs.config
#                                   echo *.* @@${var.fluentd_host}:42185 >> /etc/rsyslog.d/00-forward_logs.conf
#                                   service rsyslog restart
# EOF
#   }
# }

# resource "aws_autoscaling_group" "ecs-autoscaling-group" {
#   name_prefix           = "${aws_launch_configuration.ecs-launch-configuration.name}-asg-"
#   max_size              = var.service_cluster_max_size
#   min_size              = var.service_cluster_min_size
#   desired_capacity      = var.service_cluster_desired_size
#   wait_for_elb_capacity = 1
#   vpc_zone_identifier   = var.private_subnets
#   launch_configuration  = aws_launch_configuration.ecs-launch-configuration.name
#   health_check_type     = "ELB"

#   target_group_arns = [aws_alb_target_group.target-group.arn]

#   lifecycle {
#     create_before_destroy = true
#   }

#   tags = flatten([
#     data.null_data_source.asg-tags.*.outputs,
#     {
#       key = "Name"
#       value = "${var.service_name}-${var.environment}-instance"
#       propagate_at_launch = true
#     },
#     {
#       key = "Environment"
#       value = var.environment
#       propagate_at_launch = true
#     },
#   ])
# }