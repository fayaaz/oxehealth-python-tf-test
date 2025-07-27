// Input bucket policy for  user A
resource "aws_s3_bucket_policy" "input_bucket_policy" {
  bucket = aws_s3_bucket.input_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "${aws_iam_user.user_a.arn}"
        }
        Action = [
          "s3:*"
        ]
        Resource = [
          "${aws_s3_bucket.input_bucket.arn}/*",
          "${aws_s3_bucket.input_bucket.arn}"
        ]
      }
    ]
  })
}

resource "aws_iam_user" "user_a" {
  name = "userA"
}

resource "aws_iam_user_policy_attachment" "iam_user_a_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  user       = aws_iam_user.user_a.name
}

// Input bucket policy for  user B
resource "aws_s3_bucket_policy" "output_bucket_policy" {
  bucket = aws_s3_bucket.output_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "${aws_iam_user.user_b.arn}"
        }
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.output_bucket.arn}/*",
          "${aws_s3_bucket.output_bucket.arn}"
        ]
      }
    ]
  })
}

resource "aws_iam_user" "user_b" {
  name = "userB"
}

resource "aws_iam_user_policy_attachment" "iam_user_b_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  user       = aws_iam_user.user_b.name
}

