module "demo_users" {
  source = "./module"

  users = [
    { name = "alvaro", email = "alvaro@example.com", age = null, city = "Madrid" },
    { name = "maria",  email = "maria@example.com", age = null, city = "Barcelona" }
  ]
}
