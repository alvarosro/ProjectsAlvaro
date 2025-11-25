# 1 Define a variable call applications that is a map of objects. A map of objects allows you to define multiple applications with specific attributes for each application.
# sintax: https://www.terraform.io/language/values/variables#map-of-objects 
variable "applications" {
    description = "Applications cloud provider"
    type = map(object({
      app_type = string
      region   = string
      environment = string
      instances = number
      cpu      = number
      memory_gb = number
      auto_scaling = bool
      monitoring_level = string
    }))
    default = {
        ecom = {
            app_type       = "web"
            region         = "us-west-1"
            environment    = "production"
            instances      = 3
            cpu            = 2
            memory_gb      = 4
            auto_scaling   = true
            monitoring_level = "high"
        }
        blog = {
            app_type       = "web"
            region         = "us-east-1"
            environment    = "staging"
            instances      = 2
            cpu            = 1
            memory_gb      = 2
            auto_scaling   = false
            monitoring_level = "medium"
        }
        analytics = {
            app_type       = "data"
            region         = "eu-central-1"
            environment    = "production"
            instances      = 5
            cpu            = 4
            memory_gb      = 8
            auto_scaling   = true
            monitoring_level = "high"
        }
        app3 = {
            app_type       = "api"
            region         = "ap-southeast-1"
            environment    = "development"
            instances      = 1
            cpu            = 1
            memory_gb      = 1
            auto_scaling   = false
            monitoring_level = "low"
        }
        app4 = {
            app_type       = "web"
            region         = "us-west-2"
            environment    = "production"
            instances      = 4
            cpu            = 2
            memory_gb      = 4
            auto_scaling   = true
            monitoring_level = "high"
        }
        app5 = {
            app_type       = "data"
            region         = "eu-west-1"
            environment    = "dev"
            instances      = 2
            cpu            = 2
            memory_gb      = 4
            auto_scaling   = false
            monitoring_level = "medium"
        }
        app6 = {
            app_type       = "api"
            region         = "eu-west-1"
            environment    = "production"
            instances      = 3
            cpu            = 2
            memory_gb      = 2
            auto_scaling   = true
            monitoring_level = "high"
        }
    }
}

variable "enabled_regions" {
    description = "List of enabled regions for deployment"
    type        = list(string)
    default     = ["us-east-1", "us-west-1", "eu-west-1"]
}

variable "enabled_environments" {
    description = "List of enabled environments for deployment"
    type        = list(string)
    default     = ["staging", "dev"]
}

variable "min_cpu_requirement" {
    description = "Minimum CPU requirement for applications"
    type        = number
    default     = 2
}

locals {
/* Patrón: Filtrar map de objetos basado en multiples condiciones */
/* Por cada aplicación en var.applications:
   Si la región de la aplicación está en var.enabled_regions
   Y el entorno de la aplicación está en var.enabled_environments
   Y la CPU de la aplicación es mayor o igual a var.min_cpu_requirement
   Entonces incluye la aplicación en el nuevo mapa local.apps_filtered */
  apps_filtered = { for app, detail in var.applications : 
  app => detail 
  if contains(var.enabled_regions, detail.region) && contains(var.enabled_environments, detail.environment) && detail.cpu >= var.min_cpu_requirement }

  total_resourcesby_region = {
    for region in distinct([for app in local.apps_filtered : app.region]) : 
    region => {
        total_instances = sum([ for app, config in local.apps_filtered : config.instances if config.region == region ])
        total_cpu = sum([ for app, config in local.apps_filtered : config.cpu * config.instances if config.region == region ])
        total_memory = sum([ for app, config in local.apps_filtered : config.memory_gb * config.instances if config.region == region ])
        total_apps = length([ for app, config in local.apps_filtered : app if config.region == region ])
    }
  }

  apps_by_type_and_env = {
# Opción 1: Map anidado (app_type -> environment -> [apps])
    for app_type in distinct([for app in local.apps_filtered : app.app_type]) :
  app_type => {
    for env in distinct([for app in local.apps_filtered : app.environment if app.app_type == app_type]) :
    env => [
      for app_name, config in local.apps_filtered :
      app_name if config.app_type == app_type && config.environment == env
    ]
  }
 }
 # Opción 2: Map simple con key combinada
# apps_by_type_and_env = {
#   for key in distinct([
#     for app, config in local.apps_filtered :
#     "${config.app_type}-${config.environment}"
#   ]) :
#   key => [
#     for app, config in local.apps_filtered :
#     app if "${config.app_type}-${config.environment}" == key
#   ]
# }

 # Apps con autoscaling
  apps_auto_scaling_enabled = {
    for app, config in local.apps_filtered :
    app => config if config.auto_scaling == true
  }

# Ordenar apps por número de instancias (CORREGIDO)
  sortable_apps = [
    for app_name, config in local.apps_filtered :
    format("%05d|%s", config.instances, app_name)
  ]
  
  sorted_apps = reverse(sort(local.sortable_apps))

   # Top 3 aplicaciones con más instancias
  top_3 = [
    for item in slice(local.sorted_apps, 0, min(3, length(local.sorted_apps))) :
    split("|", item)[1]
  ]

   # Calcular costos
  app_costs = {
    for app_name, config in local.apps_filtered :
    app_name => (config.cpu * 0.05 + config.memory_gb * 0.01) * config.instances * 730
  }

# Mapear a formato "instances-nombre" para poder ordenar
sortable_list = [
  for app_name, config in local.apps_filtered :
  format("%05d|%s", config.instances, app_name)
]

 }

resource "null_resource" "example" {
  for_each = local.apps_filtered
  triggers = {
    app_name = each.key
    region   = each.value.region
    env      = each.value.environment
    instances = each.value.instances
  }

  provisioner "local-exec" {
    command = "echo Deploying ${each.key} in ${each.value.region} for ${each.value.environment} with ${each.value.instances} instances"
  }
}

resource "local_file" "local" {
  for_each = local.apps_auto_scaling_enabled
  filename = "${path.module}/app-${each.key}-region-${each.value.region}.yml"
    content  = <<-EOF
        application: ${each.key}
        region: ${each.value.region}
        environment: ${each.value.environment}
        instances: ${each.value.instances}
        cpu: ${each.value.cpu}
        memory_gb: ${each.value.memory_gb}
        auto_scaling: ${each.value.auto_scaling}
        monitoring_level: ${each.value.monitoring_level}
        EOF
}


# ===== OUTPUTS =====
output "apps_by_region_and_env" {
    description = "Applications grouped by app_type and environment"
    value = local.apps_by_type_and_env
}

output "resource_summary_by_region" {
    description = "Summary of resources by region"
    value = local.total_resourcesby_region
}

output "apps_requiring_advanced_monitoring" {
    description = "List of applications that require advanced monitoring"
    value = [ for app, config in local.apps_filtered : app if config.monitoring_level == "high" ]
}

output "largest_deployments" {
    description = "Top 3 applications with the highest number of instances"
    value = local.top_3
}

output "cost_estimation" {
  description = "Monthly cost estimation by environment"
  value = {
    for env in distinct([for app in local.apps_filtered : app.environment]) :
    env => sum([
      for app_name, config in local.apps_filtered :
      local.app_costs[app_name] if config.environment == env
    ])
  }
}

output "autoscaling_apps_by_type" {
  description = "Applications with autoscaling enabled grouped by app_type"
  value = {
    for app_type in distinct([
      for app, config in local.apps_auto_scaling_enabled :
      config.app_type
    ]) :
    app_type => [
      for app_name, config in local.apps_auto_scaling_enabled :
      app_name if config.app_type == app_type
    ]
  }
}