#Patrón 1: Transformar lista

# Input: lista de nombres
# Output: lista de emails

locals {
  names  = ["alice", "bob"]
  emails = [for name in local.names : "${name}@company.com"]
  # ["alice@company.com", "bob@company.com"]
}

output "list" {
  value = local.emails
}

#Patrón 2: Filtrar lista

locals {
  numbers = [5, 15, 8, 20, 3]
  large   = [for n in local.numbers : n if n > 10] # n if n > 10 → Incluye el valor n en la nueva lista solo si n > 10
  # [15, 20]
}

output "list_2" {
  value = local.large
}

#Patrón 3: Lista a map.

# Input: listagit config --global credential.helper osxkeychain
# Output: map con índice
locals {
  fruits = ["apple", "banana", "orange"]
  indexed = {
    for i, hola in local.fruits : i => hola #i es el índice de cada elemento (0, 1, 2...).
  }
}

output "map" {
  value = local.indexed
}

#Patrón 4: Map a lista (solo keys)

locals {
  servers = {
    "web" = "t3.micro"
    "db"  = "t3.large"
  }
  names = [for name, type in local.servers : name]
  # ["web", "db"]
}

output "lista_servers" {
  value = local.names
}

#Patrón 5: Map a lista (solo values)

locals {
  servers_2 = {
    "web" = "t3.micro"
    "db"  = "t3.large"
  }
  types = [for name, type in local.servers_2 : type]
  # ["t3.micro", "t3.large"]
}

output "lista_tipos" {
  value = local.types
}

#Patrón 6: Filtrar map

locals {
  all_servers = {
    "web"   = { size = "small" }
    "db"    = { size = "large" }
    "cache" = { size = "small" }
  }
  
  small_servers = {
 /*
Recorre el mapa: Por cada entrada en local.all_servers:
name = la clave ("web", "db", "cache")
key = el valor (el objeto { size = "small" } o { size = "large" })
Condición: Solo incluye la entrada SI key.size == "small" Crea nueva entrada: name => key significa:
La clave del nuevo mapa será name
El valor del nuevo mapa será key
¿Qué significa =>?
Es el operador para crear pares clave-valor en un mapa
clave => valor
 */
  
    for name, key in local.all_servers :
    name => key
    if key.size == "small"
  }
}
/*
En resumen:
name es la clave actual
key es el valor actual
Se agrega name => key al nuevo mapa si la condición (si existe) es verdadera.
*/
output "small_servers" {
  value = local.small_servers
}


# Patrón 7: Agrupar (como tu output)

locals {
  servers_3 = [
    { name = "web1", type = "web" },
    { name = "web2", type = "web" },
    { name = "db1", type = "db" }
  ]
  
  by_type = {
    // Obtiene una lista de tipos únicos: ["web", "db"]
    // Para cada type en esa lista: Crea una entrada en el mapa by_type donde la clave es el tipo (type).
    for type in distinct([for s in local.servers_3 : s.type]) :
    // El valor es una lista con los nombres de los servidores que tienen ese tipo.
    type => [ for s in local.servers_3 : s.name if s.type == type ]
  }
}

output "grouped_servers" {
  value = local.by_type
}