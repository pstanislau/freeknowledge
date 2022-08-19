resource aws_s3_bucket bucket {
  bucket        = "stanis-${var.apex_domain}"
  force_destroy = true
  acl           = "private"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "s3block" {
  bucket                  = aws_s3_bucket.bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data aws_iam_policy_document policy {
  statement {
    actions = ["s3:GetObject"]

    resources = [
      aws_s3_bucket.bucket.arn,
      "${aws_s3_bucket.bucket.arn}/*"
    ]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }
  }
}


resource aws_s3_bucket_policy bucket_policy {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.policy.json
}

# resource aws_s3_bucket bucket_test {
#   bucket        = "test.${var.apex_domain}"
#   force_destroy = true
# }