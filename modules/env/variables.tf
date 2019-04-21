variable "myaws_vpc_name" {}

variable "myaws_vpc_cidr" {}

variable "myaws_pub_subnet_cidr" {
  type = "list"
}

variable "myaws_pvt_subnet_cidr" {
  type = "list"
}

variable "myaws_pub_subnet_AZ" {
  type = "list"
}

variable "myaws_pvt_subnet_AZ" {
  type = "list"
}

variable "myaws_create_pvtsubnet" {
  description = "This flag will allow to create private subnet and NAT gateway,otherwise both subnets will be public"
  default     = "false"
}

variable "myaws_environment-tag" {
  default = "Testing"
}
