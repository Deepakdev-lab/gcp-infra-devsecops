# Creates outbound-only internet translation for private resources when explicitly enabled.
resource "google_compute_router_nat" "main" {
  count = var.enable_nat ? 1 : 0

  name                               = "${var.network_name}-nat"
  router                             = google_compute_router.nat.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.private.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}