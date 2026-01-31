locals {
/*
prod_buckets: Bucle for para crear un mapa filtrado de buckets que solo incluya aquellos en entorno "prod".
versioned_buckets: Bucle for para crear un mapa filtrado de buckets que solo incluya aquellos con versioning habilitado.
bucket_tags: Bucle for que crea un mapa de etiquetas para cada bucket, combinando etiquetas base con etiquetas adicionales usando merge().
*/
prod_buckets = {
    for name, cfg in var.buckets :
    name => cfg
    if cfg.environment == "prod"
  }

  versioned_buckets = {
    for name, cfg in var.buckets :
    name => cfg
    if cfg.versioning
  }

  bucket_tags = {
    for name, cfg in var.buckets :
    name => merge(
      {
        Environment = cfg.environment
        Tier        = cfg.environment == "prod" ? "Critical" : "Non-Critical"
        Versioned   = tostring(cfg.versioning)
      },
      {
        Managedby = "Terraform"
      }
    )
  }
}

resource "aws_s3_bucket" "this" {
  for_each = var.buckets

  bucket = each.key
  tags   = local.bucket_tags[each.key]
}

resource "aws_s3_bucket_versioning" "this" {
  for_each = local.versioned_buckets

  bucket = aws_s3_bucket.this[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}