# Creates the dedicated runtime identity that the Cloud Run service should use.
resource "google_service_account" "cloud_run" {
  account_id   = var.cloud_run_service_account_id
  display_name = "Cloud Run GCS application identity"
  description  = "Runtime identity for the Cloud Run application that accesses the GCS bucket."
}