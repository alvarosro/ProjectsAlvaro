output "prod_bucket_names" {
  value = [for name, cfg in local.prod_buckets : name]
}

output "bucket_versioning" {
  value = {
    for name, cfg in var.buckets :
    name => cfg.versioning
  }
}

output "bucket_arns" {
  description = "Map of bucket names to ARNs"
  value = {
    for name, bucket in aws_s3_bucket.this :
    name => bucket.arn
  }
}