# security group for EC2 instances
resource "aws_security_group" "webapp_ec2" {
  name        = "webapp-ec2"
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
}

# # EC2 instances, one per availability zone
# resource "aws_instance" "webapp" {
#   ami                         = local.ami
#   associate_public_ip_address = true
#   #count                       = "${length(var.azs)}"
#   //depends_on                  = ["aws_subnet.private"]
#   instance_type               = "t2.micro"
#   subnet_id                   = element(local.subnets, 0)
#   user_data                   = file("userdata.sh")

#   # references security group created above
#   vpc_security_group_ids = [aws_security_group.webapp_ec2.id]

#   tags = {
#     Name = "webapp-instance"//-${count.index}"
#     Environment = var.environment
#   }
# }