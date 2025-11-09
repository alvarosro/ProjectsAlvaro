## 1. Using for_each with set of strings

variable "environments" {
  type    = set(string)
  default = ["dev", "staging", "prod"]
}

variable "include_prod" {
  description = "Exclude prod environment"
  type = bool
  default = true
}

resource "local_file" "env_config" {
  #for_each = var.environments
  # Se lee como: "Para cada 'env' en 'var.environments', incluye 'env' SI 'env' no es igual a 'prod'"
  for_each = var.include_prod ? var.environments : toset([for env in var.environments : env if env != "prod"])

  filename = "${path.module}/configs/${each.key}.txt"
  content  = <<-EOF
    Environment: ${each.key}
    Created at: ${timestamp()}
    Status: Active
  EOF
}

output "created_files" {
  value = [for env in local_file.env_config : env.filename]
}

output "environments_created" {
  value = keys(local_file.env_config)
}

output "prod_included" {
  value = var.include_prod
}