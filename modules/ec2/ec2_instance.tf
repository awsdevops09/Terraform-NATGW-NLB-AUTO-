resource "aws_instance" "DBInstance" {
  #count         = "${length(var.myaws_pvt_cidr)}"
  ami           = "${lookup(var.myaws_ami_id,var.myaws_region)}"
  instance_type = "${var.myaws_instance_type}"
  key_name      = "${var.myaws_key_name}"

  vpc_security_group_ids = ["${var.myaws_sg_db_id}"]

  # Launching DB instance into private subnet
  subnet_id = "${element( "${var.myaws_pvt_subnet_id}",count.index)}"

  tags {
    Name        = "DBServer-${count.index+1}"
    Environment = "${var.myaws_env_tag}"
  }
}

resource "aws_lb" "proj_nlb" {
  name                             = "TF-NLB"
  load_balancer_type               = "network"
  subnets                          = ["${var.myaws_pub_subnet_id}"]
  internal                         = false
  enable_cross_zone_load_balancing = true

  tags {
    Name        = "TF-NLB-Proj"
    Environment = "${var.myaws_env_tag}"
  }
}

resource "aws_lb_target_group" "proj_nlb_target_group" {
  name     = "TF-NLB-TG"
  port     = "80"
  protocol = "TCP"
  vpc_id   = "${var.myaws_vpc_id}"

  tags {
    Name        = "TF-NLB-TG-Proj"
    Environment = "${var.myaws_env_tag}"
  }
}

resource "aws_lb_listener" "proj_nlb_listener" {
  load_balancer_arn = "${aws_lb.proj_nlb.arn}"
  port              = 80
  protocol          = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.proj_nlb_target_group.arn}"
    type             = "forward"
  }
}

resource "aws_launch_configuration" "proj_autoscale_launch" {
  image_id        = "${lookup(var.myaws_ami_id,var.myaws_region)}"
  instance_type   = "${var.myaws_instance_type}"
  security_groups = ["${var.myaws_sg_id}"]
  key_name        = "${var.myaws_key_name}"

  #  associate_public_ip_address = true
  user_data = "${base64encode(file("install_nginx.sh"))}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "proj_autoscale_group" {
  launch_configuration = "${aws_launch_configuration.proj_autoscale_launch.id}"
  vpc_zone_identifier  = ["${var.myaws_pub_subnet_id}"]
  desired_capacity     = "${var.myaws_autoscale_capacity}"
  min_size             = "${var.myaws_autoscale_min}"
  max_size             = "${var.myaws_autoscale_max}"

  tag {
    key                 = "Name"
    value               = "TF-NLB-AUTOSCALE-TG-Proj"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_attachment" "proj_nlb_autoscale" {
  alb_target_group_arn   = "${aws_lb_target_group.proj_nlb_target_group.arn}"
  autoscaling_group_name = "${aws_autoscaling_group.proj_autoscale_group.id}"
}
