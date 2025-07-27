locals {
  lambda_function_name          = "exifstrip"
  lambda_runtime                = "python3.12"
  lambda_root                   = "${path.module}/../src"
  lambda_layer_root             = "${local.lambda_root}/layer"
  lambda_layer_requirements_txt = "${local.lambda_layer_root}/requirements.txt"
  lambda_layer_lib_root         = "${local.lambda_layer_root}/python"
  lambda_function_root          = "${local.lambda_root}/function"
}

resource "aws_iam_role" "exif_lambda" {
  name = "exif_stripper_lambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

}

resource "aws_iam_role_policy" "lambda_s3_policy" {
  name = "s3_lambda_trigger"
  role = aws_iam_role.exif_lambda.id

  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "s3:*"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
  EOF
}


resource "aws_iam_role_policy_attachment" "exif_lambda" {
  role       = aws_iam_role.exif_lambda.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.lambda_function_name}"
  retention_in_days = 14
}

resource "null_resource" "pip_install" {
  provisioner "local-exec" {
    command = "pip install --quiet --quiet --requirement ${local.lambda_layer_requirements_txt} --target ${local.lambda_layer_lib_root}"
  }

  triggers = {
    requirements = filemd5(local.lambda_layer_requirements_txt)
  }
}

data "archive_file" "lambda_layer" {
  depends_on  = [null_resource.pip_install]
  type        = "zip"
  source_dir  = local.lambda_layer_root
  output_path = "${path.module}/lambda_layer.zip"
}

resource "aws_lambda_layer_version" "pil_layer" {
  layer_name          = "${local.lambda_function_name}-pip-requirements"
  filename            = data.archive_file.lambda_layer.output_path
  source_code_hash    = data.archive_file.lambda_layer.output_base64sha256
  compatible_runtimes = [local.lambda_runtime]

  lifecycle {
    create_before_destroy = true
  }
}

data "archive_file" "lambda_function" {
  type        = "zip"
  source_dir  = local.lambda_function_root
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "exif_lambda" {
  # Ensure log group is created by terraform before lambda function executes and
  # creates the log group.
  depends_on = [aws_cloudwatch_log_group.lambda]

  filename         = data.archive_file.lambda_function.output_path
  function_name    = local.lambda_function_name
  role             = aws_iam_role.exif_lambda.arn
  timeout          = 60
  handler          = "lambda.handler"
  runtime          = local.lambda_runtime
  source_code_hash = data.archive_file.lambda_function.output_base64sha256
  layers           = [aws_lambda_layer_version.pil_layer.arn]
  environment {
    variables = {
      OUTPUT_S3_BUCKET = "${aws_s3_bucket.output_bucket.id}"
    }
  }
}
