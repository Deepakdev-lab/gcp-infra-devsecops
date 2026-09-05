# Creates the backend Cloud Run service that reads the configured GCS object.
resource "google_cloud_run_v2_service" "backend" {
  name     = var.backend_service_name
  location = var.cloud_run_region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.cloud_run.email

    containers {
      image = var.backend_image

      env {
        name  = "GCS_BUCKET"
        value = google_storage_bucket.application.name
      }

      env {
        name  = "GCS_OBJECT"
        value = google_storage_bucket_object.sample_data.name
      }
    }
  }
}

# Makes the backend publicly reachable so the public UI can call it in this lab.
resource "google_cloud_run_v2_service_iam_member" "backend_public" {
  name     = google_cloud_run_v2_service.backend.name
  location = google_cloud_run_v2_service.backend.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Creates the public Cloud Run UI and injects the backend URL at deployment time.
resource "google_cloud_run_v2_service" "ui" {
  name     = var.ui_service_name
  location = var.cloud_run_region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.ui.email

    containers {
      image = var.ui_image

      env {
        name  = "BACKEND_URL"
        value = google_cloud_run_v2_service.backend.uri
      }
    }
  }
}

# Makes the UI publicly reachable for the initial application demo.
resource "google_cloud_run_v2_service_iam_member" "ui_public" {
  name     = google_cloud_run_v2_service.ui.name
  location = google_cloud_run_v2_service.ui.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}