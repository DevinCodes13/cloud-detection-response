# ---------- Server badge: an IAM role that can ONLY talk to Session Manager ----------
locals {
  ssm_actions = [
    "ssm:UpdateInstanceInformation", "ssm:ListAssociations",
    "ssm:ListInstanceAssociations", "ssm:DescribeAssociation",
    "ssm:GetDocument", "ssm:DescribeDocument",
    "ssm:GetDeployablePatchSnapshotForInstance", "ssm:GetManifest",
    "ssm:GetParameter", "ssm:GetParameters",
    "ssm:PutInventory", "ssm:PutComplianceItems",
    "ssm:PutConfigurePackageResult", "ssm:UpdateAssociationStatus",
    "ssm:UpdateInstanceAssociationStatus",
    "ssmmessages:CreateControlChannel", "ssmmessages:CreateDataChannel",
    "ssmmessages:OpenControlChannel", "ssmmessages:OpenDataChannel",
    "ec2messages:AcknowledgeMessage", "ec2messages:DeleteMessage",
    "ec2messages:FailMessage", "ec2messages:GetEndpoint",
    "ec2messages:GetMessages", "ec2messages:SendReply"
  ]
  ssm_services = var.enable_ssm_endpoints ? toset(["ssm", "ssmmessages", "ec2messages"]) : toset([])
}

resource "aws_iam_role" "ssm_instance" {
  name                 = "${var.project}-ssm-instance-role"
  permissions_boundary = "arn:aws:iam::${local.account_id}:policy/CDR-EC2-Boundary"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ssm_instance" {
  name = "session-manager-only"
  role = aws_iam_role.ssm_instance.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "SessionManagerOnly"
      Effect   = "Allow"
      Action   = local.ssm_actions
      Resource = "*"
    }]
  })
}

resource "aws_iam_instance_profile" "ssm" {
  name = "${var.project}-ssm-instance-profile"
  role = aws_iam_role.ssm_instance.name
}

# ---------- Guard for the private hallways: HTTPS from inside the VPC only ----------
resource "aws_security_group" "endpoints" {
  name        = "${var.project}-endpoints"
  description = "VPC interface endpoints - HTTPS from inside the VPC only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from inside the VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress = []
  tags   = { Name = "${var.project}-endpoints-sg" }
}

# ---------- Private hallways to Session Manager (no internet needed) ----------
resource "aws_vpc_endpoint" "ssm" {
  for_each            = local.ssm_services
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${local.region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true
  tags                = { Name = "${var.project}-${each.key}-endpoint" }
}

# ---------- Free private hallway to S3 (lets the private server get OS updates) ----------
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${local.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]
  tags              = { Name = "${var.project}-s3-endpoint" }
}
