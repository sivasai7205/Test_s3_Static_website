module "test_s3_bucket" {
  source        = "terraform-aws-modules/s3-bucket/aws"
  bucket        = "test-s3-mybucket"
  acl           = "private"
  force_destroy = true
}

data "aws_iam_policy_document" "test_s3_policy" {
  version = "2012-10-17"
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.test_s3_bucket.s3_bucket_arn}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "docs" {
  bucket = module.test_s3_bucket.s3_bucket_id
  policy = data.aws_iam_policy_document.test_s3_policy.json
}

resource "aws_s3_object" "webpage-upload" {
    for_each        = fileset("webpages/", "*.html")
    bucket          = module.test_s3_bucket.s3_bucket_id
    key             = each.value
    source          = "webpages/${each.value}"
    content_type    = "text/html"
    etag            = filemd5("webpages/${each.value}")
    acl             = "public-read"
}


resource "aws_s3_bucket_website_configuration" "website-config" {
  bucket = module.test_s3_bucket.s3_bucket_id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "404.jpeg"
  }

  routing_rule {
    condition {
      key_prefix_equals = "/abc"
    }
    redirect {
      replace_key_prefix_with = "abc.html"
    }
  }

}