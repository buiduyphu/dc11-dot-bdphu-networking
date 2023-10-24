terraform {
  required_providers {
    aws = {
      source  = "local/hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
  required_version = ">= 0.13"
}

provider "aws" {
  region  = "ap-southeast-1"
}

resource "aws_vpc" "networking-VPC" {
 cidr_block = "10.0.0.0/16"
 
 tags = {
   Name = "dc11-networking-VPC"
 }
}

resource "aws_subnet" "public_subnets" {
 count      = length(var.public_subnet_cidrs)
 vpc_id     = aws_vpc.networking-VPC.id
 cidr_block = element(var.public_subnet_cidrs, count.index)
 availability_zone = element(var.azs, count.index)
 
 tags = {
   Name = "Public Subnet ${count.index + 1}"
 }
}

resource "aws_subnet" "private_subnets" {
 count      = length(var.private_subnet_cidrs)
 vpc_id     = aws_vpc.networking-VPC.id
 cidr_block = element(var.private_subnet_cidrs, count.index)
 availability_zone = element(var.azs, count.index)
 
 tags = {
   Name = "Private Subnet ${count.index + 1}"
 }
}

resource "aws_internet_gateway" "gw" {
 vpc_id = aws_vpc.networking-VPC.id
 
 tags = {
   Name = "networking-VPC-IG"
 }
}

resource "aws_egress_only_internet_gateway" "eigw" {
  vpc_id = aws_vpc.networking-VPC.id

  tags = {
   Name = "networking-VPC-Egress-IG"
 }
}

resource "aws_route_table" "public_route_table" {
 vpc_id = aws_vpc.networking-VPC.id
 
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.gw.id
 }
 
 tags = {
   Name = "Public Route Table"
 }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.networking-VPC.id

  route {
    ipv6_cidr_block = "2406:da18:dcc:1500::/56"
    egress_only_gateway_id = aws_egress_only_internet_gateway.eigw.id
  }

tags = {
   Name = "Private Route Table"
 }
}

resource "aws_route" "egress_only_gateway_route" {
  route_table_id = aws_route_table.private_route_table.id
  destination_ipv6_cidr_block = "2406:da18:dcc:1500::/56"
  egress_only_gateway_id = aws_egress_only_internet_gateway.eigw.id
}

resource "aws_route_table_association" "public_subnet_association" {
 count = length(var.public_subnet_cidrs)
 subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
 route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_subnet_association" {
  count = length(var.private_subnet_cidrs)
  subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
  route_table_id = aws_route_table.private_route_table.id
}
