variable "project" {
  type        = string
  description = "Project name for tagging and resource naming"
}

variable "environment" {
  type        = string
  description = "Environment name (dev/stage/prod)"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR range for VPC"
}

variable "az_count" {
  type        = number
  description = "Number of AZs to use"
  default     = 3
}

variable "cluster_version" {
  type        = string
  description = "EKS version"
  default     = "1.30"
}

variable "node_instance_types" {
  type        = list(string)
  description = "Instance types for baseline EKS managed node group"
  default     = ["m6i.large"]
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 6
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags"
}
