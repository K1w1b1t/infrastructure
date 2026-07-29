# =========================================================================
# Módulo Storage — bucket de mídia do kiwibit_web (Always Free)
#
# Instanciado uma vez por ambiente (staging e prod). Cada instância cria:
#   - um bucket com leitura pública de objeto (sem listagem)
#   - um usuário IAM dedicado, com policy escopada SOMENTE ao seu bucket
#   - uma Customer Secret Key (credencial S3-compatível) para o app
#
# O isolamento por ambiente é intencional: uma chave de staging vazada não
# consegue escrever nem apagar mídia de produção.
#
# ATENÇÃO Always Free: Object Storage é elegível (20 GB), mas o plano limita
# 50.000 requests de API por mês. O app deve servir tudo via next/image, que
# faz a Vercel cachear no edge e reduz drasticamente as leituras no origin.
# =========================================================================

variable "environment" {
  description = "Nome do ambiente (staging ou prod). Compõe o nome de todos os recursos."
  type        = string

  validation {
    condition     = contains(["staging", "prod"], var.environment)
    error_message = "environment deve ser 'staging' ou 'prod'."
  }
}

variable "compartment_ocid" {
  description = "OCID do Compartment onde o bucket será criado"
  type        = string
}

variable "tenancy_ocid" {
  description = "OCID da Tenancy Root. Recursos de identidade (user/group/policy) são tenancy-scoped."
  type        = string
}

variable "region" {
  description = "Região da OCI (usada só para compor as URLs de output)"
  type        = string
}

locals {
  bucket_name = "kiwibit-media-${var.environment}"
  group_name  = "kiwibit-media-writers-${var.environment}"
  user_name   = "kiwibit-media-app-${var.environment}"
}

data "oci_objectstorage_namespace" "current" {
  compartment_id = var.compartment_ocid
}

# access_type = ObjectRead libera GET de objeto sem autenticação, mas mantém a
# listagem do bucket privada — é o que permite servir a imagem publicamente sem
# expor o inventário de arquivos.
resource "oci_objectstorage_bucket" "media" {
  compartment_id = var.compartment_ocid
  namespace      = data.oci_objectstorage_namespace.current.namespace
  name           = local.bucket_name
  storage_tier   = "Standard"
  access_type    = "ObjectRead"
  versioning     = "Disabled"

  freeform_tags = {
    project     = "kiwibit_web"
    environment = var.environment
    managed_by  = "terraform"
  }
}

# -------------------------------------------------------------------------
# Identidade do app. compartment_id = tenancy_ocid porque user, group e policy
# só existem no compartment raiz.
# -------------------------------------------------------------------------

resource "oci_identity_user" "app" {
  compartment_id = var.tenancy_ocid
  name           = local.user_name
  description    = "Usuário de serviço do kiwibit_web para upload de mídia (${var.environment})"

  freeform_tags = {
    project     = "kiwibit_web"
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "oci_identity_group" "media_writers" {
  compartment_id = var.tenancy_ocid
  name           = local.group_name
  description    = "Grupo com permissão de escrita no bucket ${local.bucket_name}"
}

resource "oci_identity_user_group_membership" "app" {
  user_id  = oci_identity_user.app.id
  group_id = oci_identity_group.media_writers.id
}

# A cláusula `where target.bucket.name` é o que impede o grupo de staging de
# tocar no bucket de prod. Sem ela, "manage objects in tenancy" daria acesso a
# todos os buckets da tenancy.
resource "oci_identity_policy" "media_writers" {
  compartment_id = var.tenancy_ocid
  name           = "kiwibit-media-policy-${var.environment}"
  description    = "Permite ao app do kiwibit_web gerenciar objetos apenas em ${local.bucket_name}"

  statements = [
    "Allow group ${oci_identity_group.media_writers.name} to manage objects in tenancy where target.bucket.name = '${local.bucket_name}'",
    "Allow group ${oci_identity_group.media_writers.name} to read buckets in tenancy where target.bucket.name = '${local.bucket_name}'",
  ]
}

# Credencial S3-compatível consumida pelo app (aws4fetch / SigV4).
# ATENÇÃO: o secret fica no state do Resource Manager.
resource "oci_identity_customer_secret_key" "app" {
  user_id      = oci_identity_user.app.id
  display_name = "kiwibit-media-s3-${var.environment}"
}

# -------------------------------------------------------------------------
# Outputs
# -------------------------------------------------------------------------

output "bucket_name" {
  description = "Nome do bucket de mídia"
  value       = oci_objectstorage_bucket.media.name
}

output "namespace" {
  description = "Namespace de Object Storage da tenancy"
  value       = data.oci_objectstorage_namespace.current.namespace
}

output "access_key_id" {
  description = "OCI_S3_ACCESS_KEY_ID para este ambiente"
  value       = oci_identity_customer_secret_key.app.id
}

output "secret_access_key" {
  description = "OCI_S3_SECRET_ACCESS_KEY para este ambiente"
  value       = oci_identity_customer_secret_key.app.key
  sensitive   = true
}

output "s3_endpoint" {
  description = "Endpoint S3-compatível de escrita"
  value       = "https://${data.oci_objectstorage_namespace.current.namespace}.compat.objectstorage.${var.region}.oraclecloud.com"
}

output "public_base_url" {
  description = "Prefixo público de leitura dos objetos"
  value       = "https://objectstorage.${var.region}.oraclecloud.com/n/${data.oci_objectstorage_namespace.current.namespace}/b/${oci_objectstorage_bucket.media.name}/o"
}
