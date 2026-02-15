variable "aws_access_key" {
  description = "AWS Access Key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "control_plane_nodes" {
  description = "List of control plane (master) node names"
  type        = list(string)
}

variable "worker_nodes" {
  description = "List of worker node names"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instances (RHEL/CentOS). Leave empty to auto-select Ubuntu 22.04 LTS."
  type        = string
}

variable "admin_password" {
  description = "Admin password for SSH access"
  type        = string
  sensitive   = true
}

variable "admin_username" {
  description = "Admin username for SSH access"
  type        = string
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone for the subnets"
  type        = string
}

variable "cluster_name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

