resource "aws_security_group" "public_web" {
  name        = "${var.project}-public-web"
  description = "Public web tier - SSH from admin IP only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from admin home IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
  }

  egress {
    description = "Allow outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-public-web-sg" }
}

resource "aws_security_group" "private_app" {
  name        = "${var.project}-private-app"
  description = "Private app tier - SSH only from public web tier"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "SSH from public web tier only"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public_web.id]
  }

  egress {
    description = "Outbound within VPC only"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = { Name = "${var.project}-private-app-sg" }
}
