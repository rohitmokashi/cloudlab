variable "public_subnet_id" {
  description = "List of subnet IDs where instances will be launched"
  type        = string
}

variable "private_subnet_id" {
  description = "List of subnet IDs where instances will be launched"
  type        = string
}

variable "control_plane_sg_id" {
  description = "Security group ID to assign to EC2 instances"
  type        = string
}

variable "node_sg_id" {
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