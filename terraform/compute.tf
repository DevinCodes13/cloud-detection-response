# Find the latest Amazon Linux 2023 image
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_key_pair" "admin" {
  key_name   = "${var.project}-admin-key-rsa"
  public_key = file(pathexpand("~/.ssh/cdr-key-rsa.pub"))
}

resource "aws_instance" "public_web" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.public_web.id]
  key_name                    = aws_key_pair.admin.key_name
  associate_public_ip_address = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type = "gp3"
    encrypted   = true
  }

  tags = { Name = "${var.project}-public-web", Tier = "web" }

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_instance" "private_app" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private.id
  vpc_security_group_ids      = [aws_security_group.private_app.id]
  key_name                    = aws_key_pair.admin.key_name
  associate_public_ip_address = false

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type = "gp3"
    encrypted   = true
  }

  tags = { Name = "${var.project}-private-app", Tier = "app" }

  lifecycle {
    ignore_changes = [ami]
  }
}
