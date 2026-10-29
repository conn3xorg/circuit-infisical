variable "port" {
  type    = number
  default = 2222
}

# Example passwords only. Pass your own with -var or TF_VAR_ on a real host.
variable "db_password" {
  type      = string
  default   = "correct-horse-battery"
  ephemeral = true
  sensitive = true
}

variable "valkey_password" {
  type      = string
  default   = "staple-paper-clip"
  ephemeral = true
  sensitive = true
}

locals {
  host = { box = "127.0.0.1" }
}

# PostgreSQL and Valkey on the same host, each listening only on localhost.
module "postgres" {
  source = "github.com/conn3xorg/circuit-postgres?ref=v0.2.0"

  hosts                = local.host
  ssh_port             = var.port
  ssh_private_key_file = "./id_ed25519"
  ssh_known_hosts_file = "./known_hosts"

  users          = ["infisical"]
  user_passwords = { infisical = var.db_password }
  databases      = { infisical = "infisical" }
}

module "valkey" {
  source = "github.com/conn3xorg/circuit-valkey?ref=v0.1.0"

  hosts                = local.host
  ssh_port             = var.port
  ssh_private_key_file = "./id_ed25519"
  ssh_known_hosts_file = "./known_hosts"

  password = var.valkey_password
}

module "infisical" {
  source = "../.."

  depends_on = [module.postgres, module.valkey]

  hosts                = local.host
  ssh_port             = var.port
  ssh_private_key_file = "./id_ed25519"
  ssh_known_hosts_file = "./known_hosts"

  site_url          = "http://localhost:8080"
  db_connection_uri = "postgres://infisical:${var.db_password}@127.0.0.1:5432/infisical"
  redis_url         = "redis://:${var.valkey_password}@127.0.0.1:6379"
  environment       = { TELEMETRY_ENABLED = "false" }
}
