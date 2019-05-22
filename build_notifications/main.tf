data "aws_caller_identity" "current_caller" {}
variable "project-name" {
  type = "string"
}

variable "account-prefix" {
  type = "string"
}

variable "aws-region" {
  type = "string"
}

provider "aws" {
  region = "${var.aws-region}"
}


###########################
# SNS
###########################
resource "aws_sns_topic" "build_status" {
  name = "a204309-build-completed-topic"
}

resource "aws_sns_topic_policy" "build_status_topic_policy" {
  arn = "${aws_sns_topic.build_status.arn}"
  policy = "${data.aws_iam_policy_document.cloudwatch-submit-sns.json}"
}
resource "aws_sns_topic_subscription" "build_status_lambda_subscription" {
  topic_arn = "${aws_sns_topic.build_status.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.teams_lambda_function.arn}"
}

###########################
# Lambda
###########################
data "archive_file" "teams_push" {
  type        = "zip"
  source_dir  = "teams_push"
  output_path = "teams_push.zip"
}
resource "aws_lambda_function" "teams_lambda_function" {
  role             = "${aws_iam_role.lambda_iam_role.arn}"
  runtime          = "python3.7"
  handler          = "teams_push.lambda_handler"
  function_name    = "teams_push"
  filename         = "teams_push.zip"
  source_code_hash = "${data.archive_file.teams_push.output_base64sha256}"
}
resource "aws_lambda_permission" "lambda_allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.teams_lambda_function.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.build_status.arn}"
}
###########################
# Cloudwatch Event 
###########################
resource "aws_cloudwatch_event_rule" "codebuild_trigger" {
  name        = "codebuild_trigger"
  description = "Posts the status of a build to an sns topic."
  is_enabled = true
  depends_on = [
    "aws_lambda_function.teams_lambda_function"
  ]
  role_arn = "${aws_iam_role.cloudwatch-event-iam-role.arn}"
  event_pattern = <<PATTERN
{
  "source": [
    "aws.codebuild"
  ],
  "detail-type": [
    "CodeBuild Build State Change"
  ],
  "detail": {
    "build-status": [
      "SUCCEEDED",
      "FAILED"
    ],
    "project-name" : [
      "${var.project-name}"
    ]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "sns_target" {
  rule      = "${aws_cloudwatch_event_rule.codebuild_trigger.name}"
  target_id = "SendToSNS"
  arn       = "${aws_sns_topic.build_status.arn}"
}
resource "aws_cloudwatch_event_permission" "cloudwatch_event_account_permissions" {
  principal    = "${data.aws_caller_identity.current_caller.account_id}"
  statement_id = "EventAccountAccess"
}

###########################
# IAM Role Policy
###########################
resource "aws_iam_role_policy" "lambda-cloudwatch-log-group" {
  name   = "a204309-cloudwatch-log-group"
  role   = "${aws_iam_role.lambda_iam_role.name}"
  policy = "${data.aws_iam_policy_document.cloudwatch-log-group-lambda.json}"
}

resource "aws_iam_role_policy" "cloudwatch-event-pass-role" {
  name   = "a204309-cloudwatch-event"
  role   = "${aws_iam_role.cloudwatch-event-iam-role.name}"
  policy = "${data.aws_iam_policy_document.cloudwatch-event-pass-role.json}"
}

###########################
# IAM Roles
###########################
resource "aws_iam_role" "sns-event-iam-role" {
  name               = "a204309-sns-iam"
  assume_role_policy = "${data.aws_iam_policy_document.sns_assume_role_policy.json}"
}

resource "aws_iam_role" "lambda_iam_role" {
  name               = "a204309-lambda-iam"
  assume_role_policy = "${data.aws_iam_policy_document.lambda_assume_role_policy.json}"
}

resource "aws_iam_role" "cloudwatch-event-iam-role" {
  name               = "a204309-cloudwatch-iam"
  assume_role_policy = "${data.aws_iam_policy_document.cloudwatch_assume_role_policy.json}"
}

###########################
# Data
###########################
data "aws_iam_policy_document" "cloudwatch-log-group-lambda" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:${var.aws-region}:${data.aws_caller_identity.current_caller.account_id}:log-group:/aws/lambda/${aws_lambda_function.teams_lambda_function.function_name}:*"
    ]
  }
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    principals = {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "cloudwatch_assume_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    principals = {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "sns_assume_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    principals = {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "cloudwatch-event-pass-role" {
  statement {
    actions = [
      "events:*",
      "iam:PassRole"
    ]
    resources = [
      "*"
    ]
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "cloudwatch-submit-sns" {
  statement {
    actions = [
      "sns:Publish"
    ]
    principals = {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    resources = [
      "${aws_sns_topic.build_status.arn}"
    ]
    effect = "Allow"
  }
}