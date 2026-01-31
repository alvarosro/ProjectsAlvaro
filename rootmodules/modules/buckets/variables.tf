variable "buckets" {
  description = "Buckets to create"
  type = map(object({
    environment = string
    versioning  = bool
    logs        = bool
  }))
}