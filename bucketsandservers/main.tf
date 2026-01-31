terraform {
  required_version = ">=1.10.0"
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

variable "buckets" {
  description = "Buckets to create"
  type = map(object({
    environment = string
    versioning  = bool
    logs        = bool
  }))

  default = {
    "app-data" = {
      environment = "prod"
      versioning  = true
      logs        = true
    }
    "access-logs" = {
      environment = "prod"
      versioning  = false
      logs        = false
    }
    "temp-files" = {
      environment = "dev"
      versioning  = false
      logs        = false
    }
  }
}

variable "applications" {
  type = map(object({
    environment    = string
    instance_count = number
    size           = string # "small" | "medium" | "large"
  }))

  default = {
    "frontend" = {
      environment    = "prod"
      instance_count = 3
      size           = "small"
    }
    "backend" = {
      environment    = "prod"
      instance_count = 2
      size           = "medium"
    }
    "worker" = {
      environment    = "dev"
      instance_count = 1
      size           = "large"
    }
  }
}


// Locals → Transformas, filtras, enriqueces esos datos.
locals {
    // Filtra los buckets que son solo de producción
    prod_buckets = {
# Para cada (name, cfg) en var.buckets: 
# Si cfg.environment == "prod", incluir: 
# clave: name
# valor: cfg (el objeto original sin modificar)
# Eso genera un nuevo mapa, más pequeño, que solo tiene los buckets de prod
    for name, cfg in var.buckets :
    name => cfg
    if cfg.environment == "prod"
    }

    versioned_buckets = {
    for name, cfg in var.buckets :
    name => cfg
    if cfg.versioning
    }
// Ejemplo con merge(): En este caso añade etiquetas adicionales, merge se usa para combinar mapas
bucket_tags = {
    for name, cfg in var.buckets :
    name => merge(
        {
          Environment = cfg.environment
          Tier = cfg.environment == "prod" ? "Critical" : "Non-Critical"
          Versioned   = tostring(cfg.versioning)
        },
        {
          Managedby = "Terraform"
        }
    )
}

instance_type_map = {
  "small"  = "t3.micro"
  "medium" = "t3.small"
  "large"  = "t3.medium"
}

app_instances = {
  for pair in flatten([ # Convierte una la lista de listas en una sola lista plana de objetos
    for app_name, app in var.applications : [ # Recorre cada aplicación definida en el mapa applications
      for i in range(app.instance_count) : { # Para cada aplicación, repite el bloque tantas veces como indique instance_count (el número de instancias que quieres de esa app).
        key         = "${app_name}-${i}" # Crea un objeto con información de la instancia.
        app         = app_name
        environment = app.environment
        size        = app.size
        index       = i
      }
    ]
  ]) : pair.key => pair # convierte esa lista en un mapa, usando el key como clave y el objeto completo como valor.
}

}

resource "aws_instance" "apps" {
  for_each = local.app_instances
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI (HVM), SSD Volume Type
  instance_type = local.instance_type_map[each.value.size]
  tags = {
    Name        = each.key
    Application = each.value.app
    Environment = each.value.environment
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

output "prod_bucket_names" {
  value = [for name, cfg in local.prod_buckets : name]
}

output "bucket_versioning" {
  value = {
    for name, cfg in var.buckets :
    name => cfg.versioning
  }
}

# output "bucket_arns" {
#   description = "Map of bucket names to ARNs"
#   value = {
#     for name, cfg in var.buckets :
#     name => aws_s3_bucket.this[name].arn
#   }
# }

output "bucket_arns" {
  description = "Map of bucket names to ARNs"
  value = {
    for name, bucket in aws_s3_bucket.this :
    name => bucket.arn
  }
}

output "app_instance_ids" {
  description = "Map of instance names to IDs"
  value = {
    for name, instance in aws_instance.apps :
    name => instance.id
  }
}