#buckets

resource "aws_s3_bucket" "choirlessRaw" {
  bucket = "choirless-raw-${terraform.workspace}"
  tags = var.tags
}

resource "aws_s3_bucket" "choirlessSnapshot" {
  bucket = "choirless-snapshot-${terraform.workspace}"
  tags = var.tags
}

resource "aws_s3_bucket" "choirlessConverted" {
  bucket = "choirless-converted-${terraform.workspace}"
  tags = var.tags
}

resource "aws_s3_bucket" "choirlessDefinition" {
  bucket = "choirless-definition-${terraform.workspace}"
  tags = var.tags
}

resource "aws_s3_bucket" "choirlessFinalParts" {
  bucket = "choirless-final-parts-${terraform.workspace}"
  lifecycle_rule {
    id = "self-clean"
    enabled = true
    expiration {
      days = 2
    }
  }

  tags = var.tags
}


#triggers for buckets
module "raw_trigger" {
  source ="./modules/trigger"
  bucket = aws_s3_bucket.choirlessRaw
  lambda = aws_lambda_function.snapshot
  events = ["s3:ObjectCreated:*"]
}

module "converted_trigger" {
  source ="./modules/trigger"
  bucket = aws_s3_bucket.choirlessConverted
  lambda = aws_lambda_function.calculateAlignment
  events = ["s3:ObjectCreated:*"]
}

module "definition_trigger" {
  source ="./modules/trigger"
  bucket = aws_s3_bucket.choirlessDefinition
  lambda = aws_lambda_function.rendererCompositorMain
  events = ["s3:ObjectCreated:*"]
}
