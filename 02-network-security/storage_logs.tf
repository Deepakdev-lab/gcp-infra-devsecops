# Creates the GCS bucket that receives access logs for the application bucket.
resource "google_storage_bucket" "audit_logs" {
  name                        = var.audit_log_bucket_name
  location                    = var.bucket_location
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = var.audit_log_bucket_force_destroy

  versioning {
    enabled = true
  }
}