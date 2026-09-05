# Creates the custom-mode VPC that will contain the lab's private network resources.
resource "google_compute_network" "main" {
  name                    = var.network_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}