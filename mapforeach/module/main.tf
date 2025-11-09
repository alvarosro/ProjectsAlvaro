variable "users" {
  type = list(object({
    name = string
    email = string
    age = optional(number)
    city = optional(string)
  }))
  # default = [ 
  #   { name = "alvaro", email = "alvaro@example.com", age = 30, city = "Madrid" },
  #   { name = "maria",  email = "maria@example.com", age = 25, city = "Barcelona" }
  # ]
}

locals {
  users_by_name = { for u in var.users : u.name => u }
}

resource "null_resource" "test" {
  for_each = local.users_by_name

  triggers = {
    name  = each.value.name
    email = each.value.email
    age   = each.value.age != null ? tostring(each.value.age) : "N/A"
    city  = each.value.city != null ? each.value.city : "N/A"
  }
}