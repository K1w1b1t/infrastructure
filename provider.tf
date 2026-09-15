terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 4.0.0"
    }
    posthog = {
      source  = "PostHog/posthog"
      version = "~> 1.0"
    }
  }
}
# No Resource Manager, o provider pode ficar vazio pois a OCI injeta a autenticação
provider "oci" {
  region = var.region
}

# A Personal API Key deve ser informada como variável sensível no OCI
# Resource Manager. Nunca exponha esta credencial aos projetos ou frontends.
provider "posthog" {
  api_key = var.posthog_api_key
  host    = var.posthog_host
}
