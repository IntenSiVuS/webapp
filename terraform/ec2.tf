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