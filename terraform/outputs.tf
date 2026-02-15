output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.k8s_vpc.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.k8s_vpc.cidr_block
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public_subnet.id
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = aws_subnet.private_subnet.id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.k8s_igw.id
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = aws_nat_gateway.k8s_nat.id
}

output "nat_gateway_public_ip" {
  description = "NAT Gateway public IP"
  value       = aws_eip.nat_eip.public_ip
}

output "instance_private_ips" {
  description = "Private IP addresses of all deployed EC2 instances"
  value = {
    for node_name in local.all_nodes :
    node_name => aws_instance.k8s_nodes[node_name].private_ip
  }
}

output "instance_public_ips" {
  description = "Public IP addresses of all deployed EC2 instances"
  value = {
    for node_name in local.all_nodes :
    node_name => aws_instance.k8s_nodes[node_name].public_ip
  }
}

output "control_plane_nodes" {
  description = "Control plane nodes names and IPs"
  value = {
    for node in var.control_plane_nodes :
    node => {
      private_ip = aws_instance.k8s_nodes[node].private_ip
      public_ip  = aws_instance.k8s_nodes[node].public_ip
    }
  }
}

output "primary_control_plane" {
  description = "Primary control plane node name and IP"
  value = {
    name       = local.primary_control_plane
    private_ip = aws_instance.k8s_nodes[local.primary_control_plane].private_ip
    public_ip  = aws_instance.k8s_nodes[local.primary_control_plane].public_ip
  }
}

output "worker_nodes" {
  description = "Worker nodes names and IPs"
  value = {
    for node in var.worker_nodes :
    node => {
      private_ip = aws_instance.k8s_nodes[node].private_ip
      public_ip  = aws_instance.k8s_nodes[node].public_ip
    }
  }
}

output "security_group_id" {
  description = "Security group ID for the Kubernetes cluster"
  value       = aws_security_group.k8s_sg.id
}

output "ssh_connection_command" {
  description = "SSH command to connect to the primary control plane"
  value       = "ssh ${var.admin_username}@${aws_instance.k8s_nodes[local.primary_control_plane].public_ip}"
}

output "ami_used" {
  description = "AMI ID used for the instances"
  value       = local.selected_ami
}
