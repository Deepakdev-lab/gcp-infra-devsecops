# Enables every Google Cloud API required by the network, storage, WIF, GAR, and Cloud Run lab.
resource "google_project_service" "required" {
  for_each = toset(var.required_services)

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}