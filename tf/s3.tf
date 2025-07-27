
// Private input bucket for jpegs
resource "aws_s3_bucket" "input_bucket" {
  bucket = var.input_bucket_name
}


resource "aws_s3_bucket_ownership_controls" "input_bucket_acl_ownership" {
  bucket = aws_s3_bucket.input_bucket.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_acl" "input_bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.input_bucket_acl_ownership]
  bucket     = aws_s3_bucket.input_bucket.id
  acl        = "private"
}


// Private output bucket for jpegs
resource "aws_s3_bucket" "output_bucket" {
  bucket = var.output_bucket_name
}

resource "aws_s3_bucket_ownership_controls" "output_bucket_acl_ownership" {
  bucket = aws_s3_bucket.output_bucket.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_acl" "output_bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.output_bucket_acl_ownership]
  bucket     = aws_s3_bucket.output_bucket.id
  acl        = "private"
}

// Trigger the lambda from input bucket
resource "aws_s3_bucket_notification" "aws-lambda-trigger" {
  bucket = aws_s3_bucket.input_bucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.exif_lambda.arn
    events              = ["s3:ObjectCreated:*"]

  }
}
resource "aws_lambda_permission" "lambda" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.exif_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${aws_s3_bucket.input_bucket.id}"
}
