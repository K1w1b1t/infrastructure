output "vps_public_ip" {
  description = "Endereço IP público atribuído à VPS de Bug Bounty"
  value       = module.compute.public_ip
}

output "ssh_connection_string" {
  description = "Comando rápido para acessar sua nova máquina"
  value       = "ssh ubuntu@${module.compute.public_ip}"
}
