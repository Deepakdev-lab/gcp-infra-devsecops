# Creates the private Artifact Registry Docker repository used by both Cloud Run images.
resource "google_artifact_registry_repository" "cloud_run" {
  location      = var.artifact_registry_location
  repository_id = var.artifact_registry_repository_id
  description   = "Container images for the public Cloud Run application lab"
  format        = "DOCKER"
}