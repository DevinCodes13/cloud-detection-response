# ---------- Quarantine room: no traffic in or out ----------
resource "aws_security_group" "quarantine" {
  name        = "${var.project}-quarantine"
  description = "Isolation SG - no inbound or outbound traffic"
  vpc_id      = aws_vpc.main.id
  ingress     = []
  egress      = []
  tags        = { Name = "${var.project}-quarantine-sg" }
}

# ---------- Alarm email ----------
resource "aws_sns_topic" "alerts" {
  name = "${var.project}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ---------- Robot: isolate EC2 ----------
data "archive_file" "isolate_ec2" {
  type        = "zip"
  source_file = "${path.module}/../lambda/isolate_ec2.py"
  output_path = "${path.module}/build/isolate_ec2.zip"
}

resource "aws_iam_role" "isolate_ec2" {
  name                 = "${var.project}-isolate-ec2-role"
  permissions_boundary = "arn:aws:iam::${local.account_id}:policy/CDR-Lambda-Boundary"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "isolate_ec2" {
  name = "isolate-ec2"
  role = aws_iam_role.isolate_ec2.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "Describe"
        Effect   = "Allow"
        Action   = ["ec2:DescribeInstances", "ec2:DescribeIamInstanceProfileAssociations"]
        Resource = "*"
      },
      {
        Sid      = "QuarantineOnlyProjectInstances"
        Effect   = "Allow"
        Action   = ["ec2:ModifyInstanceAttribute", "ec2:DisassociateIamInstanceProfile"]
        Resource = "*"
        Condition = {
          StringEquals = { "aws:ResourceTag/Project" = "cloud-detection-response" }
        }
      },
      {
        Sid      = "Evidence"
        Effect   = "Allow"
        Action   = ["ec2:CreateSnapshot", "ec2:CreateTags"]
        Resource = "*"
      },
      {
        Sid      = "Alert"
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = aws_sns_topic.alerts.arn
      },
      {
        Sid      = "Logs"
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "${aws_cloudwatch_log_group.isolate_ec2.arn}:*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "isolate_ec2" {
  name              = "/aws/lambda/${var.project}-isolate-ec2"
  retention_in_days = 14
}

resource "aws_lambda_function" "isolate_ec2" {
  function_name    = "${var.project}-isolate-ec2"
  role             = aws_iam_role.isolate_ec2.arn
  runtime          = "python3.12"
  handler          = "isolate_ec2.handler"
  filename         = data.archive_file.isolate_ec2.output_path
  source_code_hash = data.archive_file.isolate_ec2.output_base64sha256
  timeout          = 60

  environment {
    variables = {
      QUARANTINE_SG_ID = aws_security_group.quarantine.id
      SNS_TOPIC_ARN    = aws_sns_topic.alerts.arn
    }
  }

  depends_on = [aws_cloudwatch_log_group.isolate_ec2, aws_iam_role_policy.isolate_ec2]
}

# ---------- Radio: GuardDuty EC2 findings (severity 4+) wake the robot ----------
resource "aws_cloudwatch_event_rule" "guardduty_ec2" {
  name        = "${var.project}-guardduty-ec2"
  description = "GuardDuty EC2 findings, medium severity and above"
  event_pattern = jsonencode({
    source        = ["aws.guardduty"]
    "detail-type" = ["GuardDuty Finding"]
    detail = {
      resource = { resourceType = ["Instance"] }
      severity = [{ numeric = [">=", 4] }]
    }
  })
}

resource "aws_cloudwatch_event_target" "guardduty_ec2" {
  rule = aws_cloudwatch_event_rule.guardduty_ec2.name
  arn  = aws_lambda_function.isolate_ec2.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.isolate_ec2.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty_ec2.arn
}
