provider "aws" {
region = "us-east-2"
}
resource "aws_vpc" "kubernetes" {
cidr_block = var.vpc_cidr
tags = {
Name = "kubernetes"
}
}
resource "aws_internet_gateway" "kubernetes_vpc_igw" {
vpc_id = aws_vpc.kubernetes.id
tags = {
Name = "kubernetes_vpc_igw"
}
}

resource "aws_subnet" "kubernetes_subnets" {
count = length(var.subnets_cidr)
vpc_id = aws_vpc.kubernetes.id
cidr_block = element(var.subnets_cidr, count.index)
availability_zone = element(var.availability_zones, count.index)
map_public_ip_on_launch = true
tags = {
Name = "kubernetes_subnets_${count.index + 1}"
}
}

resource "aws_route_table" "kubernetes_public_route_table" {
vpc_id = aws_vpc.kubernetes.id
route {
cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.kubernetes_vpc_igw.id
}
tags = {
Name = "kubernetes_vpc_public_route_table"
}
}

resource "aws_route_table_association" "route_table_subnet_association" {
count = length(var.subnets_cidr)
subnet_id = element(aws_subnet.kubernetes_subnets.*.id, count.index)
route_table_id = aws_route_table.kubernetes_public_route_table.id
}

resource "aws_instance" "kubernetes_Servers" {
count = 1
ami = var.kubernetes_ami
instance_type = var.master_instance_type
vpc_security_group_ids = [aws_security_group.kubernetes_sg.id]
subnet_id = element(aws_subnet.kubernetes_subnets.*.id, count.index)
key_name = var.key_name

tags = {
Name = "kubernetes_Servers"
Type = "kubernetes_Master"
}
}

resource "aws_instance" "kubernetes_Workers" {
count = 2
ami = var.kubernetes_ami
instance_type = var.worker_instance_type
vpc_security_group_ids = [aws_security_group.kubernetes_sg.id]
subnet_id = element(aws_subnet.kubernetes_subnets.*.id, count.index)
key_name = var.key_name

tags = {
Name = "kubernetes_Servers"
Type = "kubernetes_Worker"
}
}
