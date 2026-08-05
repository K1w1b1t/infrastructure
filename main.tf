# =========================================================================
# Arquivo Raiz (Root Module) do Terraform Kiwibit
# O OCI Resource Manager varrerá este arquivo na raiz do git.
# =========================================================================

module "network" {
  source           = "./modules/network"
  compartment_ocid = var.compartment_ocid
}

module "compute" {
  source           = "./modules/compute"
  compartment_ocid = var.compartment_ocid
  subnet_id        = module.network.subnet_id
  instance_shape   = var.instance_shape
  ssh_public_key   = var.ssh_public_key
}

# Buckets de mídia do kiwibit_web — um por ambiente, com credenciais isoladas.
# staging atende a branch `release`; prod atende a `main`.
module "storage_staging" {
  source           = "./modules/storage"
  environment      = "staging"
  compartment_ocid = var.compartment_ocid
  tenancy_ocid     = var.tenancy_ocid
  region           = var.region
}

module "storage_prod" {
  source           = "./modules/storage"
  environment      = "prod"
  compartment_ocid = var.compartment_ocid
  tenancy_ocid     = var.tenancy_ocid
  region           = var.region
}