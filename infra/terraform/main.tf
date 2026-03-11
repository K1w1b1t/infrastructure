# =========================================================================
# 1. Configurações Globais / Data Sources
# =========================================================================

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

data "oci_core_images" "ubuntu" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = var.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# =========================================================================
# 2. Virtual Cloud Network (VCN) e Rede
# =========================================================================

resource "oci_core_vcn" "bug_bounty_vcn" {
  compartment_id = var.compartment_ocid
  display_name   = "bug-bounty-vcn"
  cidr_block     = "10.0.0.0/16"
  is_ipv6enabled = false
}

resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.bug_bounty_vcn.id
  display_name   = "bug-bounty-igw"
  enabled        = true
}

resource "oci_core_default_route_table" "public_route" {
  manage_default_resource_id = oci_core_vcn.bug_bounty_vcn.default_route_table_id

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

# Modificado para permitir apenas as portas essenciais 
# e a comunicação via requisição HTTPS para fora.
resource "oci_core_default_security_list" "security_list" {
  manage_default_resource_id = oci_core_vcn.bug_bounty_vcn.default_security_list_id

  # Libera outbound (Saída) para a internet toda
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  # Libera Inbound TCP (Entrada) - Só SSH na Porta 22
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0" # Para maior segurança restrinja a IPs de sua casa VPN no futuro

    tcp_options {
      min = 22
      max = 22
    }
  }

  # Ping / ICMP (Diagnóstico)
  ingress_security_rules {
    protocol = "1" # ICMP
    source   = "0.0.0.0/0"
    icmp_options {
      type = 3
      code = 4
    }
  }
}

resource "oci_core_subnet" "public_subnet" {
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.bug_bounty_vcn.id
  cidr_block        = "10.0.1.0/24"
  display_name      = "bug-bounty-public-subnet"
  route_table_id    = oci_core_vcn.bug_bounty_vcn.default_route_table_id
  security_list_ids = [oci_core_vcn.bug_bounty_vcn.default_security_list_id]
}


# =========================================================================
# 3. Compute (VPS Always Free)
# =========================================================================

resource "oci_core_instance" "bug_bounty_vps" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_ocid
  display_name        = "bug-bounty-bot"
  shape               = var.instance_shape

  # Shape config do Always Free. (Mesmo sem block ele pega default, porém garante consistência)
  shape_config {
    ocpus         = 1
    memory_in_gbs = 1
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public_subnet.id
    assign_public_ip = true
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu.images[0].id
  }

  # Injectando a chave pro seu acesso via SSH
  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }
}