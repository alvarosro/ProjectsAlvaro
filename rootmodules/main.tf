
module "buckets" {
  source = "./modules/buckets"

  buckets = {
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