locals {
  image     = "docker.io/infisical/infisical:${var.infisical_version}@${var.image_digest}"
  keys_file = "/etc/infisical/keys.env"
}

# ENCRYPTION_KEY encrypts every secret Infisical stores, and AUTH_SECRET
# signs its sessions. Both are made on the host by the first apply and never
# pass through Conn3x, so they're in neither the plan nor state. creates
# keeps them from ever being replaced: a new ENCRYPTION_KEY would leave the
# database unreadable.
circuit "keys" {
  hosts = var.hosts

  ssh {
    user             = var.ssh_user
    port             = var.ssh_port
    private_key_file = var.ssh_private_key_file
    known_hosts_file = var.ssh_known_hosts_file
    become           = var.ssh_become
  }

  step "dir" {
    directory {
      path  = "/etc/infisical"
      owner = "root"
      group = "root"
      mode  = "0700"
    }
  }

  # ENCRYPTION_KEY is 16 random bytes in hex, the form Infisical's docs
  # generate; AUTH_SECRET is 32 in base64.
  step "generate" {
    command {
      command = "umask 077 && { printf 'ENCRYPTION_KEY=%s\\n' \"$(head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \\n')\" && printf 'AUTH_SECRET=%s\\n' \"$(head -c 32 /dev/urandom | base64)\"; } > ${local.keys_file}.new && mv ${local.keys_file}.new ${local.keys_file}"
      creates = local.keys_file
    }
  }
}

# Infisical runs from its official image as a Quadlet unit. Everything it
# keeps is in PostgreSQL, so the container has no volume. It's on the host's
# network so it can reach a PostgreSQL and Valkey that listen only on
# localhost, and HOST and PORT decide where it listens.
module "podman" {
  source = "github.com/conn3xorg/circuit-podman?ref=v0.1.0"

  depends_on = [conn3x_command.keys__generate]

  hosts                = var.hosts
  ssh_user             = var.ssh_user
  ssh_port             = var.ssh_port
  ssh_private_key_file = var.ssh_private_key_file
  ssh_known_hosts_file = var.ssh_known_hosts_file
  ssh_become           = var.ssh_become

  containers = {
    infisical = {
      image = local.image
      environment = {
        HOST     = var.listen_address
        PORT     = tostring(var.port)
        SITE_URL = var.site_url
      }
      extra = ["Network=host", "EnvironmentFile=${local.keys_file}"]
    }
  }
  secrets = {
    infisical = merge(var.environment, {
      DB_CONNECTION_URI = var.db_connection_uri
      REDIS_URL         = var.redis_url
    })
  }
}

circuit "infisical" {
  hosts = var.hosts

  ssh {
    user             = var.ssh_user
    port             = var.ssh_port
    private_key_file = var.ssh_private_key_file
    known_hosts_file = var.ssh_known_hosts_file
    become           = var.ssh_become
  }

  # Infisical runs its database migrations before it opens the port, which
  # on a first start takes a minute or two after the image is pulled.
  step "ready" {
    depends_on = [module.podman]
    wait_for {
      port    = var.port
      timeout = "10m"
    }
  }
}
