variable "hosts" {
  type        = any
  description = "Hosts to configure: a map of names to addresses, or to host objects with an address and optional host_key, user, port, private_key_file or jump_hosts."
}

variable "ssh_user" {
  type        = string
  default     = "root"
  description = "User to log in as."
}

variable "ssh_port" {
  type        = number
  default     = 22
  description = "SSH port."
}

variable "ssh_private_key_file" {
  type        = string
  default     = null
  description = "Path to a private key. When null, Conn3x uses the SSH agent."
}

variable "ssh_known_hosts_file" {
  type        = string
  default     = null
  description = "known_hosts file to check host keys against. When null, ~/.ssh/known_hosts."
}

variable "ssh_become" {
  type        = bool
  default     = false
  description = "Run commands as root through sudo."
}

variable "infisical_version" {
  type        = string
  default     = "v0.167.4"
  description = "Tag of the docker.io/infisical/infisical image, such as \"v0.167.4\". Change image_digest with it."

  validation {
    condition     = can(regex("^[A-Za-z0-9_][A-Za-z0-9_.-]*$", var.infisical_version))
    error_message = "infisical_version must be an image tag, such as \"v0.167.4\"."
  }
}

variable "image_digest" {
  type        = string
  default     = "sha256:80a3bb51bee4092b7332d000506d5740ba57b1c4d48550e50746fe9c5209715d"
  description = "Digest of the image for infisical_version, such as \"sha256:80a3...\". Podman pulls by the digest, so a tag that moves upstream can't change what runs."

  validation {
    condition     = can(regex("^sha256:[a-f0-9]{64}$", var.image_digest))
    error_message = "image_digest must be a sha256 digest, such as \"sha256:\" followed by 64 hex digits."
  }
}

variable "site_url" {
  type        = string
  description = "The address people and clients reach Infisical at, such as \"https://secrets.example.com\". Infisical uses it for CORS, links in emails and SSO redirects."

  validation {
    condition     = can(regex("^https?://[^\\s/]+(/[^\\s]*)?$", var.site_url))
    error_message = "site_url must be an http or https URL, such as \"https://secrets.example.com\"."
  }
}

variable "db_connection_uri" {
  type        = string
  ephemeral   = true
  sensitive   = true
  description = "PostgreSQL connection URI, such as \"postgres://infisical:PASSWORD@127.0.0.1:5432/infisical\". It reaches the host in a root-only file and never the plan or state."

  validation {
    condition     = can(regex("^postgres(ql)?://", var.db_connection_uri)) && !strcontains(var.db_connection_uri, "\n")
    error_message = "db_connection_uri must be a postgres:// or postgresql:// URI on one line."
  }
}

variable "redis_url" {
  type        = string
  ephemeral   = true
  sensitive   = true
  description = "Redis or Valkey URL, such as \"redis://:PASSWORD@127.0.0.1:6379\". It reaches the host in a root-only file and never the plan or state."

  validation {
    condition     = can(regex("^rediss?://", var.redis_url)) && !strcontains(var.redis_url, "\n")
    error_message = "redis_url must be a redis:// or rediss:// URL on one line."
  }
}

variable "listen_address" {
  type        = string
  default     = "127.0.0.1"
  description = "Address Infisical listens on. The default keeps it on the host for a reverse proxy in front; \"0.0.0.0\" listens on every address."

  validation {
    condition     = can(cidrhost("${var.listen_address}/${strcontains(var.listen_address, ":") ? 128 : 32}", 0))
    error_message = "listen_address must be an IPv4 or IPv6 address, such as \"127.0.0.1\"."
  }
}

variable "port" {
  type        = number
  default     = 8080
  description = "Port Infisical listens on."

  validation {
    condition     = var.port >= 1 && var.port <= 65535 && floor(var.port) == var.port
    error_message = "port must be a whole number from 1 to 65535."
  }
}

variable "environment" {
  type        = map(string)
  default     = {}
  ephemeral   = true
  sensitive   = true
  nullable    = false
  description = "More of Infisical's environment variables, such as { SMTP_HOST = \"smtp.example.com\", SMTP_PASSWORD = \"...\", TELEMETRY_ENABLED = \"false\" }. They go in the same root-only file as the connection settings and never reach the plan or state."

  validation {
    condition     = alltrue([for k, v in var.environment : can(regex("^[A-Za-z_][A-Za-z0-9_]*$", k)) && !strcontains(v, "\n")])
    error_message = "environment maps variable names, such as SMTP_HOST, to values on one line."
  }

  validation {
    condition     = length(setintersection(keys(var.environment), ["HOST", "PORT", "SITE_URL", "DB_CONNECTION_URI", "REDIS_URL", "ENCRYPTION_KEY", "ROOT_ENCRYPTION_KEY", "AUTH_SECRET"])) == 0
    error_message = "Set HOST, PORT, SITE_URL, DB_CONNECTION_URI and REDIS_URL with their own inputs. ENCRYPTION_KEY and AUTH_SECRET are generated on the host."
  }
}
