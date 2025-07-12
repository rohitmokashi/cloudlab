variable "public_subnet_id" {
  description = "List of subnet IDs where instances will be launched"
  type        = string
}

variable "private_subnet_id" {
  description = "List of subnet IDs where instances will be launched"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID to assign to EC2 instances"
  type        = string
}

variable "control_plane_count" {
  type        = number
}

variable "node_count" {
  type        = number
}

variable "ami_id" {
  type        = string
}

variable "instance_type" {
  type        = string
}

resource "aws_instance" "control_plane" {
  count                     = var.control_plane_count
  ami                       = var.ami_id
  instance_type             = var.instance_type
  subnet_id                 = var.public_subnet_id
  vpc_security_group_ids    = [var.security_group_id]
  associate_public_ip_address = true
  key_name = "pegasus"
  tags = {
    Name = "k8s-control-plane-${count.index}"
  }
}

resource "aws_instance" "node" {
  count                     = var.node_count
  ami                       = var.ami_id
  instance_type             = var.instance_type
  subnet_id                 = var.private_subnet_id
  vpc_security_group_ids    = [var.security_group_id]
  associate_public_ip_address = false
  key_name = "pegasus"
  tags = {
    Name = "k8s-node-${count.index}"
  }
}

output "instance_ids" {
  value = aws_instance.control_plane[*].id
}
