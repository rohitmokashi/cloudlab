resource "aws_instance" "control_plane" {
  count                     = var.control_plane_count
  ami                       = var.ami_id
  instance_type             = var.instance_type
  subnet_id                 = var.public_subnet_id
  vpc_security_group_ids    = [var.control_plane_sg_id]
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
  vpc_security_group_ids    = [var.node_sg_id]
  associate_public_ip_address = false
  key_name = "pegasus"
  tags = {
    Name = "k8s-node-${count.index}"
  }
}

output "control_plane_ips" {
  value = aws_instance.control_plane[*].public_ip
}

output "node_ips" {
  value = aws_instance.node[*].private_ip
}