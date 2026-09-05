# Creates the service account used by the application repository to deploy Cloud Run revisions.
resource "google_service_account" "app_deployer" {
  account_id   = var.app_deployer_service_account_id
  display_name = "Application Cloud Run deployer"
  description  = "Deploys application images to the existing public Cloud Run services."
}

# Allows the application deployer to create and update Cloud Run services.
resource "google_project_iam_member" "app_deployer_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.app_deployer.email}"
}

# Allows the application deployer to attach the backend runtime service account.
resource "google_service_account_iam_member" "app_deployer_backend_user" {
  service_account_id = google_service_account.cloud_run.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.app_deployer.email}"
}

# Allows the application deployer to attach the UI runtime service account.
resource "google_service_account_iam_member" "app_deployer_ui_user" {
  service_account_id = google_service_account.ui.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.app_deployer.email}"
}