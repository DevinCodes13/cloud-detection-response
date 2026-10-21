# S3's address list, used by the gateway endpoint
data "aws_prefix_list" "s3" {
  name = "com.amazonaws.${local.region}.s3"
}

resource "aws_security_group" "public_web" {
  name        = "${var.project}-public-web-zt"
  description = "Public web tier - no inbound; HTTPS out only (access via Session Manager)"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "HTTPS out (Session Manager, OS updates)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-public-web-sg" }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "private_app" {
  name        = "${var.project}-private-app-zt"
  description = "Private app tier - no inbound; HTTPS out to VPC endpoints and S3 only"
  vpc_id      = aws_vpc.main.id

  egress {
    description     = "HTTPS to Session Manager endpoints"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.endpoints.id]
  }

  egress {
    description     = "HTTPS to S3 via gateway endpoint (OS updates)"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [data.aws_prefix_list.s3.id]
  }

  tags = { Name = "${var.project}-private-app-sg" }

  lifecycle {
    create_before_destroy = true
  }
}
