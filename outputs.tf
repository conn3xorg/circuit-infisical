output "service" {
  description = "The systemd service that runs Infisical on each host."
  value       = "infisical.service"
}

output "image" {
  description = "The Infisical image the hosts run."
  value       = local.image
}

output "keys_file" {
  description = "File on each host holding the generated ENCRYPTION_KEY and AUTH_SECRET. Back it up: without ENCRYPTION_KEY, nothing in the database can be decrypted."
  value       = local.keys_file
}
