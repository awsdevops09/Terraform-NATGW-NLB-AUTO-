# create VPC
resource "aws_vpc" "proj_vpc" {
  cidr_block           = "${var.myaws_vpc_cidr}"
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.myaws_vpc_name}"
    Environment = "${var.myaws_environment-tag}"
  }
}

#create internet gateway
resource "aws_internet_gateway" "proj_igw" {
  vpc_id = "${aws_vpc.proj_vpc.id}"

  tags = {
    Name        = "IGW-${var.myaws_vpc_name}"
    Environment = "${var.myaws_environment-tag}"
  }
}

#create public subnets
resource "aws_subnet" "proj_public_subnet" {
  count             = "${length(var.myaws_pub_subnet_cidr)}"
  vpc_id            = "${aws_vpc.proj_vpc.id}"
  cidr_block        = "${element(var.myaws_pub_subnet_cidr,count.index)}"
  availability_zone = "${element(var.myaws_pub_subnet_AZ,count.index)}"

  #setting public ip for testing purpose
  map_public_ip_on_launch = true

  tags = {
    Name        = "Public Subnet-${count.index+1}-${var.myaws_vpc_name}"
    Environment = "${var.myaws_environment-tag}"
  }
}

#create a private subnet
resource "aws_subnet" "proj_private_subnet" {
  count             = "${length(var.myaws_pvt_subnet_cidr)}"
  vpc_id            = "${aws_vpc.proj_vpc.id}"
  cidr_block        = "${element(var.myaws_pvt_subnet_cidr,count.index)}"
  availability_zone = "${element(var.myaws_pvt_subnet_AZ,count.index)}"

  #setting public ip for testing purpose
  map_public_ip_on_launch = true

  tags = {
    Name        = "Private Subnet-${count.index+1}-${var.myaws_vpc_name}"
    Environment = "${var.myaws_environment-tag}"
  }
}

#create a public route table attach it to internet gateway and associate subnet(Web Servers).
resource "aws_route_table" "proj_public_route_table" {
  vpc_id = "${aws_vpc.proj_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.proj_igw.id}"
  }

  tags = {
    Name        = "Public R Table-${var.myaws_vpc_name}"
    Environment = "${var.myaws_environment-tag}"
  }
}

resource "aws_route_table_association" "proj_public_route_tabl_assoc" {
  count          = "${length(var.myaws_pub_subnet_cidr)}"
  subnet_id      = "${element(aws_subnet.proj_public_subnet.*.id,count.index)}"
  route_table_id = "${aws_route_table.proj_public_route_table.id}"
}

#create a NAT gateway with elastic ip in first public subnet.
resource "aws_eip" "proj_eip_nat" {
  count = "${var.myaws_create_pvtsubnet ? 1 : 0}"
  vpc   = true

  tags = {
    Name        = "elastic IP-${var.myaws_vpc_name}"
    Environment = "${var.myaws_environment-tag}"
  }
}

resource "aws_nat_gateway" "proj_nat_gw" {
  count         = "${var.myaws_create_pvtsubnet ? 1 : 0}"
  allocation_id = "${aws_eip.proj_eip_nat.id}"
  subnet_id     = "${aws_subnet.proj_public_subnet.0.id}"

  tags = {
    Name        = "NAT GW-${var.myaws_vpc_name}"
    Environment = "${var.myaws_environment-tag}"
  }
}

#create a private route table and associate second subnet(DB Servers).
resource "aws_route_table" "proj_private_route_table" {
  count  = "${var.myaws_create_pvtsubnet ? 1 : 0}"
  vpc_id = "${aws_vpc.proj_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.proj_nat_gw.id}"
  }

  tags = {
    Name        = "Private R Table-${var.myaws_vpc_name}"
    Environment = "${var.myaws_environment-tag}"
  }
}

resource "aws_route_table_association" "proj_private_route_tabl_assoc" {
  count          = "${var.myaws_create_pvtsubnet ? 1 : 0}"
  count          = "${length(var.myaws_pvt_subnet_cidr)}"
  subnet_id      = "${element(aws_subnet.proj_private_subnet.*.id,count.index)}"
  route_table_id = "${aws_route_table.proj_private_route_table.id}"
}

# create a security group for webservers subnet.
resource "aws_security_group" "proj_sg" {
  name        = "Web-SG-Allow 80 22"
  description = "Allow HTTP inbound traffic"
  vpc_id      = "${aws_vpc.proj_vpc.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "Webservers-SG-${var.myaws_vpc_name}"
    Environment = "${var.myaws_environment-tag}"
  }
}

resource "aws_security_group" "proj_db_sg" {
  name   = "DBServers-SG -Allow 22 3306"
  vpc_id = "${aws_vpc.proj_vpc.id}"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${aws_security_group.proj_sg.id}"]
  }

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${aws_security_group.proj_sg.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "DBservers-SG-${var.myaws_vpc_name}"
    Environment = "${var.myaws_environment-tag}"
  }
}

######
output "out_vpc_id" {
  value = "${aws_vpc.proj_vpc.id}"
}

output "out_sg_id" {
  value = "${aws_security_group.proj_sg.id}"
}

output "out_sg_db_id" {
  value = "${aws_security_group.proj_db_sg.id}"
}

output "out_public_subnet_id" {
  value = "${aws_subnet.proj_public_subnet.*.id}"
}

output "out_private_subnet_id" {
  value = "${aws_subnet.proj_private_subnet.*.id}"
}

output "out_environment-tag" {
  value = "${var.myaws_environment-tag}"
}

output "out_pvt_subnet_cidr" {
  value = "${var.myaws_pvt_subnet_cidr}"
}
