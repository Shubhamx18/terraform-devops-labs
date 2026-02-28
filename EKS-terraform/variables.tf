variable "region" {
  default = "ap-south-1"
}

variable "cluster_name" {
  default = "practice-eks"
}

variable "environment" {
  default = "lab"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "azs" {
  default = ["ap-south-1a", "ap-south-1b"]
}

variable "private_subnets" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnets" {
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "intra_subnets" {
  default = ["10.0.5.0/24", "10.0.6.0/24"]
}
