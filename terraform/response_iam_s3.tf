locals {
  lambda_boundary = "arn:aws:iam::${local.account_id}:policy/CDR-Lambda-Boundary"
  lambda_trust = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# ======================= Robot 2: disable leaked keys =======================
data "archive_file" "disable_keys" {
  type        = "zip"
  source_file = "${path.module}/../lambda/disable_keys.py"
  output_path = "${path.module}/build/disable_keys.zip"
}

resource "aws_iam_role" "disable_keys" {
  name                 = "${var.project}-disable-keys-role"
  permissions_boundary = local.lambda_boundary
  assume_role_policy   = local.lambda_trust
}

resource "aws_iam_role_policy" "disable_keys" {
  name = "disable-keys"
  role = aws_iam_role.disable_keys.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DisableOnlyCdrUserKeys"
        Effect   = "Allow"
        Action   = ["iam:UpdateAccessKey", "iam:ListAccessKeys"]
        Resource = "arn:aws:iam::${local.account_id}:user/cdr-*"
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
        Resource = "${aws_cloudwatch_log_group.disable_keys.arn}:*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "disable_keys" {
  name              = "/aws/lambda/${var.project}-disable-keys"
  retention_in_days = 14
}

resource "aws_lambda_function" "disable_keys" {
  function_name    = "${var.project}-disable-keys"
  role             = aws_iam_role.disable_keys.arn
  runtime          = "python3.12"
  handler          = "disable_keys.handler"
  filename         = data.archive_file.disable_keys.output_path
  source_code_hash = data.archive_file.disable_keys.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      SNS_TOPIC_ARN       = aws_sns_topic.alerts.arn
      ALLOWED_USER_PREFIX = "cdr-"
    }
  }

  depends_on = [aws_cloudwatch_log_group.disable_keys, aws_iam_role_policy.disable_keys]
}

resource "aws_cloudwatch_event_rule" "guardduty_iam" {
  name        = "${var.project}-guardduty-iam"
  description = "GuardDuty access key findings, medium severity and above"
  event_pattern = jsonencode({
    source        = ["aws.guardduty"]
    "detail-type" = ["GuardDuty Finding"]
    detail = {
      resource = { resourceType = ["AccessKey"] }
      type     = [{ "anything-but" = { prefix = "Policy:S3/" } }]
      severity = [{ numeric = [">=", 4] }]
    }
  })
}

resource "aws_cloudwatch_event_target" "guardduty_iam" {
  rule = aws_cloudwatch_event_rule.guardduty_iam.name
  arn  = aws_lambda_function.disable_keys.arn
}

resource "aws_lambda_permission" "disable_keys_eventbridge" {
  statement_id  = "AllowEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.disable_keys.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty_iam.arn
}

# ======================= Robot 3: re-lock public S3 =======================
data "archive_file" "lock_s3" {
  type        = "zip"
  source_file = "${path.module}/../lambda/lock_s3.py"
  output_path = "${path.module}/build/lock_s3.zip"
}

resource "aws_iam_role" "lock_s3" {
  name                 = "${var.project}-lock-s3-role"
  permissions_boundary = local.lambda_boundary
  assume_role_policy   = local.lambda_trust
}

resource "aws_iam_role_policy" "lock_s3" {
  name = "lock-s3"
  role = aws_iam_role.lock_s3.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "RelockOnlyCdrBuckets"
        Effect   = "Allow"
        Action   = ["s3:GetBucketPublicAccessBlock", "s3:PutBucketPublicAccessBlock"]
        Resource = "arn:aws:s3:::cdr-*"
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
        Resource = "${aws_cloudwatch_log_group.lock_s3.arn}:*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "lock_s3" {
  name              = "/aws/lambda/${var.project}-lock-s3"
  retention_in_days = 14
}

resource "aws_lambda_function" "lock_s3" {
  function_name    = "${var.project}-lock-s3"
  role             = aws_iam_role.lock_s3.arn
  runtime          = "python3.12"
  handler          = "lock_s3.handler"
  filename         = data.archive_file.lock_s3.output_path
  source_code_hash = data.archive_file.lock_s3.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      SNS_TOPIC_ARN         = aws_sns_topic.alerts.arn
      ALLOWED_BUCKET_PREFIX = "cdr-"
    }
  }

  depends_on = [aws_cloudwatch_log_group.lock_s3, aws_iam_role_policy.lock_s3]
}

# S3 "Policy" findings (public access changes) are often LOW severity,
# so this rule matches by finding type instead of severity.
resource "aws_cloudwatch_event_rule" "guardduty_s3" {
  name        = "${var.project}-guardduty-s3"
  description = "GuardDuty S3 public-access policy findings, any severity"
  event_pattern = jsonencode({
    source        = ["aws.guardduty"]
    "detail-type" = ["GuardDuty Finding"]
    detail = {
      type = [{ prefix = "Policy:S3/" }]
    }
  })
}

resource "aws_cloudwatch_event_target" "guardduty_s3" {
  rule = aws_cloudwatch_event_rule.guardduty_s3.name
  arn  = aws_lambda_function.lock_s3.arn
}

resource "aws_lambda_permission" "lock_s3_eventbridge" {
  statement_id  = "AllowEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lock_s3.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty_s3.arn
}

# ---------- Test target for robot 3 (empty, locked bucket) ----------
resource "aws_s3_bucket" "test_public" {
  bucket        = "${var.project}-test-public-${local.account_id}"
  force_destroy = true
  tags          = { Name = "${var.project}-test-public", Purpose = "robot-3-test-target" }
}

resource "aws_s3_bucket_public_access_block" "test_public" {
  bucket                  = aws_s3_bucket.test_public.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
