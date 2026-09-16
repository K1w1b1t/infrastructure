variable "tenancy_ocid" {
  description = "OCID da Tenancy Root da OCI"
  type        = string
}

variable "compartment_ocid" {
  description = "OCID do Compartment onde os recursos serão criados"
  type        = string
}

variable "region" {
  description = "Região da OCI a ser utilizada"
  type        = string
  default     = "sa-saopaulo-1"
}

variable "instance_shape" {
  description = "Shape da VPS (A1.Flex ou E2.1.Micro para Always Free)"
  type        = string
  default     = "VM.Standard.E2.1.Micro"
}

variable "ssh_public_key" {
  description = "Chave SSH Pública (sem aspas) usada para acessar o SO da instância ubuntu"
  type        = string
}

variable "posthog_api_key" {
  description = "Personal API Key usada pelo Terraform para administrar recursos no PostHog"
  type        = string
  sensitive   = true
}

variable "posthog_project_id" {
  description = "ID numerico do projeto PostHog compartilhado, obtido em Project settings"
  type        = string
}

variable "posthog_app_urls" {
  description = "Dominios HTTPS autorizados para Web Analytics e Session Replay, sem curingas"
  type        = string

  validation {
    condition     = can(jsondecode(jsondecode(var.posthog_app_urls)))
    error_message = "posthog_app_urls deve ser uma lista JSON dupla serializada nao vazia de dominios HTTPS completos."
  }
}

variable "posthog_discord_webhook_url" {
  description = "Incoming Webhook Discord para alertas PostHog de producao"
  type        = string
  sensitive   = true
}

variable "posthog_host" {
  description = "URL da região da conta PostHog Cloud"
  type        = string
  default     = "https://us.posthog.com"

  validation {
    condition     = contains(["https://us.posthog.com", "https://eu.posthog.com"], var.posthog_host)
    error_message = "posthog_host deve ser https://us.posthog.com ou https://eu.posthog.com."
  }
}
