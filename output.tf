output "source_s3_bucket_arn" {
  value = aws_s3_bucket.data-bucket.arn
}

output "destination_s3_bucket_arn" {
  value = aws_s3_bucket.bucket.arn
}