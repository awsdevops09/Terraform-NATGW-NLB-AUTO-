provider "aws" {
  region = "${var.myaws_region}"
}

module "proj_module_env" {
  source         = "../modules/env"
  myaws_vpc_name = "DEV VPC"

  myaws_vpc_cidr = "10.10.0.0/16"

  myaws_pub_subnet_cidr = ["10.10.10.0/24", "10.10.20.0/24"]

  myaws_pvt_subnet_cidr = ["10.10.50.0/24"]

  myaws_pub_subnet_AZ = ["us-east-1a", "us-east-1b"]
  myaws_pvt_subnet_AZ = ["us-east-1a", "us-east-1b"]

  #This flag will allow to create private route table and NAT gateway
  myaws_create_pvtsubnet = true

  myaws_environment-tag = "Development"
}

module "proj_module_ec2" {
  source                   = "../modules/ec2"
  myaws_region             = "us-east-1"
  myaws_instance_type      = "t2.micro"
  myaws_key_name           = "MYLAB"
  myaws_env_tag            = "${module.proj_module_env.out_environment-tag}"
  myaws_sg_id              = "${module.proj_module_env.out_sg_id}"
  myaws_sg_db_id           = "${module.proj_module_env.out_sg_db_id}"
  myaws_pub_subnet_id      = "${module.proj_module_env.out_public_subnet_id}"
  myaws_pvt_subnet_id      = "${module.proj_module_env.out_private_subnet_id}"
  myaws_vpc_id             = "${module.proj_module_env.out_vpc_id}"
  myaws_pvt_cidr           = "${module.proj_module_env.out_pvt_subnet_cidr}"
  myaws_autoscale_capacity = 3
  myaws_autoscale_max      = 4
  myaws_autoscale_min      = 2
}
