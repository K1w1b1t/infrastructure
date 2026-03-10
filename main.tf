resource "oci_objectstorage_bucket" "test_bucket" {
    compartment_id = var.compartment_ocid
    name           = "bucket-teste-terraform"
    namespace      = "gr8jqsbktuzk" # O namespace que você informou
    storage_tier   = "Standard"
    visibility     = "Private"
}
