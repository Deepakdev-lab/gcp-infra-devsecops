resource "google_compute_firewall" "test_insecure_ssh" {
  name    = "test-insecure-ssh"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}
