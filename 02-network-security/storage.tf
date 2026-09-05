# Creates a private GCS bucket for application objects with uniform IAM access control.
resource "google_storage_bucket" "application" {
  name                        = var.bucket_name
  location                    = var.bucket_location
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = var.bucket_force_destroy

  logging {
    log_bucket = google_storage_bucket.audit_logs.name
  }

  versioning {
    enabled = true
  }
}