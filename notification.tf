resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.name}-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for logging to CloudWatch
resource "aws_iam_policy" "lambda_logging_policy" {
  name        = "${var.name}-lambda-logging-policy"
  description = "IAM policy for Lambda function to write logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attach the logging policy to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_logs_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
}


# Create a zip archive of the Lambda function code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/files/index.mjs"
  output_path = "${path.module}/files/lambda_function.zip"
}

# Lambda Function Resource
resource "aws_lambda_function" "amplify_notifier" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.name
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "nodejs20.x"

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url
    }
  }

  # Add a dependency to ensure the role is created before the function
  depends_on = [aws_iam_role.lambda_exec_role]
}


resource "aws_cloudwatch_event_rule" "amplify_build_rule" {
  name        = "${var.name}-amplify-build"
  description = "Amplify Build"

  event_pattern = jsonencode({
    "source"      = ["aws.amplify"],
    "detail-type" = ["Amplify Job State Change"],
    "detail" = merge(
      {
        "jobStatus" = ["SUCCEED", "FAILED", "STARTED"]
      },
      # Conditionally add the appId to the filter if the variable is set
      { "appId" = [aws_amplify_app.this.id] }
    )
  })

  depends_on = [aws_amplify_app.this]
}

resource "aws_cloudwatch_event_target" "this" {
  rule      = aws_cloudwatch_event_rule.amplify_build_rule.name
  target_id = "SendToLambdaFunction"
  arn       = aws_lambda_function.amplify_notifier.arn
}

# Grant EventBridge permission to invoke the Lambda function
resource "aws_lambda_permission" "this" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.amplify_notifier.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.amplify_build_rule.arn
}
