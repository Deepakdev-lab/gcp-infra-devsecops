# Grants the Cloud Run runtime identity only the configured object-level bucket role.
resource "google_storage_bucket_iam_member" "cloud_run" {
  bucket = google_storage_bucket.application.name
  role   = var.cloud_run_bucket_role
  member = "serviceAccount:${google_service_account.cloud_run.email}"
}