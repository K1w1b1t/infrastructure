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