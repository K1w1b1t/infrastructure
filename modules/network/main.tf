variable "compartment_ocid" { type = string }

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

resource "oci_core_default_security_list" "security_list" {
  manage_default_resource_id = oci_core_vcn.bug_bounty_vcn.default_security_list_id

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol = "1"
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

output "subnet_id" {
  value = oci_core_subnet.public_subnet.id
}