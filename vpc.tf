resource "aws_vpc" "vpc" {
  cidr_block = var.cidr
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "public_subnet" {
  for_each          = toset(var.az)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.cidr_public[each.value]
  availability_zone = each.value
}

resource "aws_subnet" "private_subnet" {
  for_each          = toset(var.az)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.cidr_private[each.value]
  availability_zone = each.value
}

resource "aws_eip" "eip" {
  for_each = toset(var.az)

}

resource "aws_nat_gateway" "nat" {
  for_each      = toset(var.az)
  subnet_id     = aws_subnet.public_subnet[each.value].id
  allocation_id = aws_eip.eip[each.value].id
}

resource "aws_route_table" "nat" {
  for_each = toset(var.az)
  vpc_id   = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[each.value].id
  }
}

resource "aws_route_table_association" "nat" {
  for_each       = toset(var.az)
  route_table_id = aws_route_table.nat[each.value].id
  subnet_id      = aws_subnet.private_subnet[each.value].id
}

resource "aws_route_table" "igw" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "igw" {
  for_each       = toset(var.az)
  route_table_id = aws_route_table.igw.id
  subnet_id      = aws_subnet.public_subnet[each.value].id
}

resource "aws_security_group" "alb_sg" {
  name = "alb_sg"
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]

  }
}

resource "aws_security_group" "sg" {
  name = "instance_sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port       = 80
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]

  }
}