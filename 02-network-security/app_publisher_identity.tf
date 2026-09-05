# Creates the service account used only by the application repository to push images to GAR.
resource "google_service_account" "app_publisher" {
  account_id   = var.app_publisher_service_account_id
  display_name = "Application image publisher"
  description  = "Pushes application container images to Artifact Registry through GitHub OIDC."
}

# Grants the application publisher permission to push images to Artifact Registry.
resource "google_project_iam_member" "app_publisher_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.app_publisher.email}"
}