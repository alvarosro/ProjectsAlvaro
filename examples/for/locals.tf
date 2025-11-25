# local.users es un mapa con dos claves: "alice" y "bob".
# Cada clave apunta a un object con atributos (age, city).
locals {
  users = {
    "alice" = { age = 30, city = "NYC" }
    "bob"   = { age = 25, city = "LA" }
  }
}

/*
k es la clave (nombre de usuario), u es el object (datos del usuario).
> [ for k, u in local.users : "${k} lives in ${u.city}" ]
[
  "alice lives in NYC",
  "bob lives in LA",
]

for es útil para recorrer todos, pero si quieres uno solo, accede directamente por índice.
En resumen: para acceder a un valor específico usa la clave del mapa (local.users["alice"].city).
*/
#local.servers es un mapa (map(object)).
locals {
  servers = {
    "web-1"  = { ip = "10.0.1.1", port = 80 }
    "db-1"   = { ip = "10.0.2.1", port = 5432 }
    "cache-1" = { ip = "10.0.3.1", port = 6379 }
  }
}

/*
Example 1: Lista de nombres de servidores en mayúsculas
Cuando iteras sobre un map, Terraform te da acceso a: k → la clave del mapa ("web-1", "db-1", "cache-1") v → el valor asociado a esa clave ({ ip = "...", port = ... }).
> [ for k, v in local.servers : upper(k) ]
[
  "CACHE-1",
  "DB-1",
  "WEB-1",
]

Example 2: Lista de IPs
[ for k, v in local.servers : v.ip ]
# => ["10.0.1.1", "10.0.2.1", "10.0.3.1"]
 Mapa IP → nombre
 Indica que por cada par clave-valor en local.servers, quieres crear un nuevo mapa donde la clave es v.ip.
 => siginifica "asigna a"
{ for k, v in local.servers : v.ip => k }
# => { "10.0.1.1" = "web-1", "10.0.2.1" = "db-1", "10.0.3.1" = "cache-1" }

Nota: Cuando itera sobre una lista terraform espera solo un valor. [] → listas, solo valores.
Cuando itera sobre un mapa terraform espera pares clave-valor. {} → mapas, pares clave-valor.
Terraform entiende que quieres construir un mapa nuevo, donde:
• La clave es v.ip
• El valor es k

Example 3: Filtrar servidores con puerto mayor a 1000
[ for k, v in local.servers : k if v.port > 1000 ]
# => ["cache-1", "db-1"]
*/

locals {
  usa = {
    "alice"   = { city = "NYC", age = 30 }
    "bob"     = { city = "LA", age = 25 }
    "charlie" = { city = "NYC", age = 35 }
  }

# distinct elimina duplicados de una lista.
  one = distinct([ for k, v in local.usa : v.city])
  two = { for k in local.one : city => [ for i, o in local.usa : i if o.city == city ]}
}
