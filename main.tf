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