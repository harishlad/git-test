provider "aws"
{
	access_key = "${var.access_key}"
	secret_key = "${var.secret_key}"
	region = "${var.region}"
}

resource "aws_vpc" "myvpc"
{
	cidr_block = "10.10.0.0/16"
	tags
	{
		Name = "myvpc"
	}
}

resource "aws_subnet" "mypubsub"
{
	cidr_block = "10.10.1.0/24"
	availability_zone = "${var.region}a"
	vpc_id = "${aws_vpc.myvpc.id}"
	map_public_ip_on_launch = true
	tags
		{
			Name = "mypubsub"
		}
}

resource "aws_subnet" "myprisub"
{
	cidr_block = "10.10.2.0/24"
	availability_zone = "${var.region}b"
	vpc_id = "${aws_vpc.myvpc.id}"
	map_public_ip_on_launch = true
	tags
		{
			Name = "myprisub"
		}
}
resource "aws_internet_gateway" "mygw"
{
	vpc_id = "${aws_vpc.myvpc.id}"
	tags
		{
			Name = "mygw"
		}
}
resource "aws_route_table" "mypubrt"
{
	vpc_id = "${aws_vpc.myvpc.id}"
	route {
			cidr_block = "0.0.0.0/0"
			gateway_id = "${aws_internet_gateway.mygw.id}"
			}
		tags
			{
				Name = "mypubrt"
			}
}
resource "aws_route_table" "myprirt"
{
	vpc_id = "${aws_vpc.myvpc.id}"
	tags
		{
			Name = "myprirt"
		}
}
resource "aws_route_table_association" "mypubrtasso"
{
		subnet_id = "${aws_subnet.mypubsub.id}"
		route_table_id = "${aws_route_table.mypubrt.id}"
}
resource "aws_route_table_association" "myprirtasso"
{
	subnet_id = "${aws_subnet.myprisub.id}"
	route_table_id = "${aws_route_table.myprirt.id}"
}
resource "aws_security_group" "elbsg"
{
	name = "elbsg"
	vpc_id = "${aws_vpc.myvpc.id}"
	ingress
			{
				from_port = 80
				to_port = 80
				protocol = "tcp"
				cidr_blocks = ["0.0.0.0/0"]
			}
	egress
			{
				from_port = 0
				to_port = 0
				protocol = "-1"
			}
}
resource "aws_security_group" "elbsg2"
{
	name = "elbsg2"
	vpc_id = "${aws_vpc.myvpc.id}"
	ingress
			{
				from_port = 80
				to_port = 80
				protocol = "tcp"
				cidr_blocks = ["0.0.0.0/0"]
			}
	egress
			{
				from_port = 0
				to_port = 0
				protocol = "-1"
			}
}	
resource "aws_elb" "myelb"
{
	name = "myelb"
	subnets = ["${aws_subnet.mypubsub.id}"]
	security_groups = ["${aws_security_group.elbsg.id}"]
	instances = ["${aws_instance.demo1.id}"]
	connection_draining = true
	listener
		{
			instance_port = 80
			instance_protocol = "http"
			lb_port = 80
			lb_protocol = "http"
		}
	health_check
		{
			healthy_threshold = 2
			unhealthy_threshold = 2
			timeout = 3
			target = "HTTP:80/index.html"
			interval = 30
		}
}
resource "aws_key_pair" "mykey"
{
	key_name = "mykey"
	public_key = "${file("/root/id_rsa.pub")}"
}
resource "aws_instance" "demo1"
{
	ami = "ami-5b673c34"
	tags {
			Name = "demo1"
		}
	instance_type = "${var.instance_type}"
	vpc_security_group_ids = ["${aws_security_group.elbsg.id}"]
	subnet_id = "${aws_subnet.mypubsub.id}"
	key_name = "${aws_key_pair.mykey.id}"
}
resource "aws_instance" "demo2"
{
	ami = "ami-5b673c34"
	tags {
			Name = "demo2"
		}
	instance_type = "${var.instance_type}"
	vpc_security_group_ids = ["${aws_security_group.elbsg.id}"]
	subnet_id = "${aws_subnet.mypubsub.id}"
	key_name = "${aws_key_pair.mykey.id}"
}	
