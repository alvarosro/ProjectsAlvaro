# Datos de prueba
# EJERCICIO 1: Lista de nombres en mayúsculas
# Respuesta: [for name, user in local.users : upper(name)]

locals {
  users = {
    "alice"   = { age = 30, city = "NYC" }
    "bob"     = { age = 25, city = "LA" }
    "charlie" = { age = 35, city = "NYC" }
    "diana"   = { age = 28, city = "LA" }
  }
  # Lista de nombres en mayúsculas
  names_upper = [for name, user in local.users : upper(name)]
  # Filtrar nombres con edad mayor a 25
  names_filter = [for name, user in local.users : name if user.age > 25]
  # Agregar usuarios por ciudad
  users_by_city = {
# Primero, [for user in local.users : user.city] recorre todos los usuarios y obtiene la ciudad de cada uno.
# distinct(...) elimina ciudades duplicadas, obteniendo una lista de ciudades únicas.
    for city in distinct([for user in local.users : user.city]) :
# Para cada city en esa lista única:
# Se crea una entrada en el mapa users_by_city donde la clave es la ciudad (city).
    city => [for nombre, datos in local.users : nombre if datos.city == city]
  }
  sum_all_ages = sum([for nombre, datos in local.users : datos.age])
# Por cada elemento en el mapa local.users, se crea una nueva entrada en el mapa resultante.
# La clave es el nombre (nombre) y el valor es la edad (datos.age) del usuario.
# Para cada par, se crea una entrada en el nuevo mapa name_age donde la clave es el nombre (nombre) y el valor es la edad (datos.age).
  name_age = { for nombre, datos in local.users : nombre => datos.age }
}
output "names_upper" {
  value = local.names_upper
}
output "names_filter" {
  value = local.names_filter
}
output "users_by_city" {
  value = local.users_by_city
}
output "sum_all_ages" {
  value = local.sum_all_ages
}
output "name_age" {
  value = local.name_age
}