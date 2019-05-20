variable "project-name" {
  type = "string"
}


provider "aws" {
  region     = "us-west-1"
}
resource "aws_sns_topic" "build_status" {
  name = "a204309-build-completed-topic"
}

resource "aws_iam_role" "lambda_iam" {
    name = "a204309-lambda-iam"
    assume_role_policy = "${data.aws_iam_policy_document.iam_policy_data.json}"
}

data "archive_file" "teams_push" {
    type = "zip"
    source_dir = "teams_push"
    output_path = "teams_push.zip"
}

resource "aws_lambda_function" "teams_lambda_function" {
    role =  "${aws_iam_role.lambda_iam.arn}"
    runtime = "python3.7"
    handler = "teams_push.lambda_handler"
    function_name = "teams_push"
    filename = "teams_push.zip"
    source_code_hash = "${data.archive_file.teams_push.output_base64sha256}"
}

resource "aws_sns_topic_subscription" "build_status_lambda_subscription" {
  topic_arn = "${aws_sns_topic.build_status.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.teams_lambda_function.arn}"
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = "${aws_cloudwatch_event_rule.codebuild_trigger.name}"
  target_id = "SendToSNS"
  arn       = "${aws_sns_topic.build_status.arn}"
}

# Trigger event for sending message to sns
resource "aws_cloudwatch_event_rule" "codebuild_trigger" {
  name        = "codebuild_trigger"
  description = "Posts the status of a build to an sns topic."

  event_pattern = <<PATTERN
{
  "detail-type": [
    "CodeBuild Build State Change"
  ],
  "detail": {
    "build-status": [
      "IN_PROGRESS",
      "SUCCEEDED", 
      "FAILED",
      "STOPPED" 
    ],
    "project-name": [
      "${var.project-name}"
    ]
  }  
}
PATTERN
}

data "aws_iam_policy_document" "iam_policy_data" {
    statement {
        sid = "1"
        actions = [
            "sts:AssumeRole"
        ]
        principals = {
            type = "Service"
            identifiers  = ["lambda.amazonaws.com"]
        }
        effect = "Allow"
    }
}
