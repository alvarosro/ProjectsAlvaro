variable "environments" {
  type    = set(string)
  default = ["dev", "staging", "prod"]

  validation {
    condition     = length(var.environments) > 0
    error_message = "At least one environment must be specified."
  }
}

variable "include_prod" {
  description = "Include production environment in deployment"
  type        = bool
  default     = true
}

locals {
  # Más legible: definir los entornos filtrados como local
  active_environments = var.include_prod ? var.environments : toset([
    for env in var.environments : env if env != "prod"
  ])
}

resource "local_file" "env_config" {
  for_each = local.active_environments
  
  filename = "${path.module}/configs/${each.key}.txt"
  content  = <<-EOF
    Environment: ${each.key}
    Created at: ${timestamp()}
    Status: Active
    Production: ${each.key == "prod" ? "Yes" : "No"}
  EOF
}

# Outputs múltiples para mejor visibilidad
output "created_files" {
  description = "List of all created configuration files"
  value       = values(local_file.env_config)[*].filename
}

output "environments_map" {
  description = "Map of environment names to file paths"
  value = {
    for key, file in local_file.env_config : key => file.filename
  }
}

output "total_environments" {
  description = "Total number of environments created"
  value       = length(local_file.env_config)
}

output "skipped_environments" {
  description = "Environments that were not created"
  value = setsubtract(var.environments, local.active_environments)
}