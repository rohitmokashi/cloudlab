variable "vpc_id" {
  description = "Security group ID to assign to EC2 instances"
  type        = string
}

resource "aws_security_group" "node_sg" {
  name   = "k8s-node-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "node_sg_id" {
  value = aws_security_group.node_sg.id
}
