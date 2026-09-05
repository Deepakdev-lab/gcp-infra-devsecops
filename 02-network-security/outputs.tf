output "network_name" {
  description = "VPC network name."
  value       = google_compute_network.main.name
}

output "subnet_name" {
  description = "Private subnet name."
  value       = google_compute_subnetwork.private.name
}

output "subnet_self_link" {
  description = "Private subnet self-link."
  value       = google_compute_subnetwork.private.self_link
}

output "nat_enabled" {
  description = "Whether Cloud NAT was created."
  value       = var.enable_nat
}

output "bucket_name" {
  description = "Application GCS bucket name."
  value       = google_storage_bucket.application.name
}

output "audit_log_bucket_name" {
  description = "GCS bucket receiving application bucket access logs."
  value       = google_storage_bucket.audit_logs.name
}

output "cloud_run_service_account_email" {
  description = "Service account email to attach to the Cloud Run service."
  value       = google_service_account.cloud_run.email
}

output "cloud_run_bucket_role" {
  description = "Bucket role granted to the Cloud Run service account."
  value       = var.cloud_run_bucket_role
}

output "artifact_registry_repository" {
  description = "Artifact Registry repository URL."
  value       = google_artifact_registry_repository.cloud_run.name
}

output "backend_url" {
  description = "Public Cloud Run backend URL."
  value       = google_cloud_run_v2_service.backend.uri
}

output "ui_url" {
  description = "Public Cloud Run UI URL."
  value       = google_cloud_run_v2_service.ui.uri
}

output "required_services" {
  description = "Google Cloud APIs managed by this lab."
  value       = sort(tolist(local.required_services))
}