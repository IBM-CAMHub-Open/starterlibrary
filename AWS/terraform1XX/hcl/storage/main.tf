####
#Template AWS S3
###

provider "aws" {
  region  = var.aws_region
}

module "camtags" {
  source = "../Modules/camtags"
}
resource "aws_s3_bucket" "bucket" {
  bucket = var.name
  tags   = module.camtags.tagsmap
}
  
resource "aws_s3_bucket_ownership_controls" "controls" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "acl" {
  depends_on = [aws_s3_bucket_ownership_controls.controls]
  bucket = aws_s3_bucket.bucket.id
  acl    = var.acl
}  
