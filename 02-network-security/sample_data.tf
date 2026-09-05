# Creates the sample object that the backend reads from the protected application bucket.
resource "google_storage_bucket_object" "sample_data" {
  name         = var.gcs_object_name
  content      = var.gcs_object_content
  bucket       = google_storage_bucket.application.name
  content_type = "text/plain"
}