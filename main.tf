terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

//
//ROLE
//

resource "aws_iam_role" "tf_accesskeycleanup_lambda_role" {
  name = "tf_accesskeycleanup_iam_for_lambda"

  inline_policy {
    name = "accesskeycleanup_lambda_iam_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = [
              "iam:ListUsers",
              "iam:ListAccessKeys",
              "iam:GetAccessKeyLastUsed",
              "iam:DeleteAccessKey",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action   = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Effect   = "Allow"
          Resource = "arn:aws:logs:*:*:*"
        }
      ]
    })
  }

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

//
//LAMBDA FUNCTION
//

variable "lambda_function_name" {
  default = "tf_accesskeycleanup_function"
}

resource "aws_lambda_function" "tf_accesskeycleanup_function" {
  function_name = var.lambda_function_name
  filename      = "tf_accesskeycleanup_function.zip"
  role          = aws_iam_role.tf_accesskeycleanup_lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  source_code_hash = filebase64sha256("tf_accesskeycleanup_function.zip")
  timeout = 10

  runtime = "python3.7"

  depends_on = [
    aws_cloudwatch_log_group.tf_accesskeycleanup_cloudwatch_lambda_log_group,
  ]
}

//
//LOGGING
//

resource "aws_cloudwatch_log_group" "tf_accesskeycleanup_cloudwatch_lambda_log_group" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 14
}

//
//TRIGGERING
//


resource "aws_cloudwatch_event_rule" "tf_accesskeycleanup_rule_every_five_minutes" {
    name = "every-five-minutes"
    description = "Fires every five minutes"
    schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "tf_accesskeycleanup_target_every_five_minutes" {
    rule = "${aws_cloudwatch_event_rule.tf_accesskeycleanup_rule_every_five_minutes.name}"
    target_id = "evaludate_time"
    arn = "${aws_lambda_function.tf_accesskeycleanup_function.arn}"
}

resource "aws_lambda_permission" "tf_accesskeycleanup_allow_cloudwatch_to_call_evaluate_time" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.tf_accesskeycleanup_function.function_name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.tf_accesskeycleanup_rule_every_five_minutes.arn}"
}