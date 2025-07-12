variable "region" {
  default = "ap-south-1"
}

variable "control_plane_count" {
  default = 1
}

variable "node_count" {
  default = 2
}

variable "instance_type" {
  default = "t3.medium"
}

variable "ami_id" {
  description = "Amazon Linux or Ubuntu AMI for your region"
  default     = "ami-08abeca95324c9c91"
}
