data "oci_objectstorage_namespace" "current" {
    compartment_id = var.compartment_ocid
}

resource "oci_objectstorage_bucket" "test_bucket" {
    compartment_id = var.compartment_ocid
    name           = "bucket-teste-terraform"
    namespace      = data.oci_objectstorage_namespace.current.namespace
    storage_tier   = "Standard"
    access_type    = "NoPublicAccess"
}
