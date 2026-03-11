terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 4.0.0"
    }
  }
}
# No Resource Manager, o provider pode ficar vazio pois a OCI injeta a autenticação
provider "oci" {
  region = var.region
}
