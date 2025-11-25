variable "buckets" {
    type = map(object({
      environment = string
      versioning  = bool 
    }))
    default = {
      app-data = {
        environment = "production"
        versioning  = true
      }
      logs = {
        environment = "development"
        versioning  = false
      }
      buckups = {
        environment = "production"
        versioning  = true
      }
    }
}

variable "create_nat_getway" {
  type    = bool
  default = true
}


resource "aws_nat_gateway" "nat1" {
  count = var.create_nat_getway ? aws_nat_gateway.nat1

  allocation_id = aws_eip.nat1.id
  subnet_id     = aws_subnet.public1.id
}


locals {
  filter = { for k, v in var.buckets : k => v if v.environment == "production" && v.versioning == true } 
}


resource "aws_s3_bucket" "mybuckets" {
  for_each = var.buckets
  bucket = "${each.key}-${each.value.environment}"

  tags = {
    Name = each.key
    Environment = each.value.environment
    versioning = each.value.versioning ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
    // "Para cada clave k y valor v en var.buckets, crea un par clave-valor k => v, SOLO SI v.versioning es verdadero"
    /*
    k => Define qué devolver: k será la clave del nuevo mapa v será el valor del nuevo mapa 
    => es el operador de mapeo
    */
  for_each = { for k, v in var.buckets : k => v if v.versioning }

  bucket = aws_s3_bucket.mybuckets[each.key].id
    versioning_configuration {
        status = "Enabled"
    }
}