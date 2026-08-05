output "vps_public_ip" {
  description = "Endereço IP público atribuído à VPS de Bug Bounty"
  value       = module.compute.public_ip
}

output "ssh_connection_string" {
  description = "Comando rápido para acessar sua nova máquina"
  value       = "ssh ubuntu@${module.compute.public_ip}"
}

# =========================================================================
# Storage de mídia do kiwibit_web
#
# Depois do apply, leia os valores e cadastre no Vercel e nos GitHub
# Environments. Os secrets são marcados como sensitive: use
# `terraform output -raw <nome>` para ler um por um.
#
#   GitHub Environment "Preview"  + Vercel Preview     <- valores staging
#   GitHub Environment "Production" + Vercel Production <- valores prod
#
# Variáveis esperadas pelo app (mesmos nomes nos dois ambientes):
#   OCI_STORAGE_NAMESPACE, OCI_STORAGE_REGION  (iguais nos dois)
#   OCI_STORAGE_BUCKET, OCI_S3_ACCESS_KEY_ID, OCI_S3_SECRET_ACCESS_KEY
# =========================================================================

output "media_namespace" {
  description = "OCI_STORAGE_NAMESPACE (comum aos dois ambientes)"
  value       = module.storage_prod.namespace
}

output "media_staging_bucket" {
  description = "OCI_STORAGE_BUCKET do ambiente de staging"
  value       = module.storage_staging.bucket_name
}

output "media_staging_access_key_id" {
  description = "OCI_S3_ACCESS_KEY_ID do ambiente de staging"
  value       = module.storage_staging.access_key_id
}

output "media_staging_secret_access_key" {
  description = "OCI_S3_SECRET_ACCESS_KEY do ambiente de staging"
  value       = module.storage_staging.secret_access_key
  sensitive   = true
}

output "media_staging_public_base_url" {
  description = "Prefixo público de leitura do bucket de staging"
  value       = module.storage_staging.public_base_url
}

output "media_prod_bucket" {
  description = "OCI_STORAGE_BUCKET do ambiente de produção"
  value       = module.storage_prod.bucket_name
}

output "media_prod_access_key_id" {
  description = "OCI_S3_ACCESS_KEY_ID do ambiente de produção"
  value       = module.storage_prod.access_key_id
}

output "media_prod_secret_access_key" {
  description = "OCI_S3_SECRET_ACCESS_KEY do ambiente de produção"
  value       = module.storage_prod.secret_access_key
  sensitive   = true
}

output "media_prod_public_base_url" {
  description = "Prefixo público de leitura do bucket de produção"
  value       = module.storage_prod.public_base_url
}
