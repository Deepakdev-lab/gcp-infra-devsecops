# Creates the regional Cloud Router used by Cloud NAT and future dynamic routing.
resource "google_compute_router" "nat" {
  name    = "${var.network_name}-router"
  region  = var.region
  network = google_compute_network.main.id
}