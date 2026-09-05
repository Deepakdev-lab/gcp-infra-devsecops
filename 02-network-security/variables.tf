variable "project_id" {
  description = "Google Cloud project used for the lab."
  type        = string
  default     = "project-a95e6dc6-f7fc-4043-bf9"
}

variable "region" {
  description = "Region for the subnet, router, and Cloud NAT."
  type        = string
  default     = "asia-south1"
}

variable "network_name" {
  description = "Name of the custom-mode VPC."
  type        = string
  default     = "netsec-vpc"
}

variable "subnet_name" {
  description = "Name of the private subnet."
  type        = string
  default     = "private-subnet"
}

variable "subnet_cidr" {
  description = "Primary IPv4 range for the private subnet."
  type        = string
  default     = "10.10.0.0/24"
}

variable "enable_nat" {
  description = "Create Cloud NAT for outbound access from private instances."
  type        = bool
  default     = false
}

variable "enable_cloud_run" {
  description = "Create the public UI and backend Cloud Run services."
  type        = bool
  default     = true
}

variable "bucket_name" {
  description = "Globally unique name of the application's GCS bucket."
  type        = string
  default     = "project-a95e6dc6-f7fc-4043-bf9-app-data"
}

variable "bucket_location" {
  description = "Location of the application's GCS bucket."
  type        = string
  default     = "ASIA-SOUTH1"
}

variable "bucket_force_destroy" {
  description = "Allow Terraform to delete bucket objects when destroying the lab."
  type        = bool
  default     = false
}

variable "audit_log_bucket_name" {
  description = "Globally unique name of the GCS access-log bucket."
  type        = string
  default     = "project-a95e6dc6-f7fc-4043-bf9-audit-logs"
}

variable "audit_log_bucket_force_destroy" {
  description = "Allow Terraform to delete access-log objects when destroying the lab."
  type        = bool
  default     = false
}

variable "cloud_run_service_account_id" {
  description = "Account ID for the dedicated Cloud Run runtime service account."
  type        = string
  default     = "cloud-run-gcs-app"
}

variable "cloud_run_bucket_role" {
  description = "Least-privilege bucket role for the Cloud Run runtime identity."
  type        = string
  default     = "roles/storage.objectViewer"
}

variable "artifact_registry_location" {
  description = "Region for the Docker Artifact Registry repository."
  type        = string
  default     = "us-east4"
}

variable "artifact_registry_repository_id" {
  description = "Artifact Registry Docker repository ID."
  type        = string
  default     = "cloudrun-images"
}

variable "cloud_run_region" {
  description = "Region for both Cloud Run services."
  type        = string
  default     = "us-east4"
}

variable "backend_service_name" {
  description = "Cloud Run backend service name."
  type        = string
  default     = "gcp-app-backend"
}

variable "ui_service_name" {
  description = "Cloud Run UI service name."
  type        = string
  default     = "gcp-app-ui"
}

variable "backend_image" {
  description = "Container image URL for the backend Cloud Run service."
  type        = string
  default     = "us-east4-docker.pkg.dev/project-a95e6dc6-f7fc-4043-bf9/cloudrun-images/backend:d717e2b"
}

variable "ui_image" {
  description = "Container image URL for the UI Cloud Run service."
  type        = string
  default     = "us-east4-docker.pkg.dev/project-a95e6dc6-f7fc-4043-bf9/cloudrun-images/ui:d717e2b"
}

variable "ui_service_account_id" {
  description = "Account ID for the public UI runtime identity."
  type        = string
  default     = "cloud-run-ui"
}

variable "gcs_object_name" {
  description = "Object name that the backend reads from the application bucket."
  type        = string
  default     = "sample-data.txt"
}

variable "gcs_object_content" {
  description = "Sample content displayed by the UI through the backend."
  type        = string
  default     = "Hello from a protected GCS object served by Cloud Run."
}

variable "terraform_service_account_id" {
  description = "Existing service account ID used by the infrastructure repository."
  type        = string
  default     = "terraform-deployer"
}

variable "app_publisher_service_account_id" {
  description = "Dedicated service account ID used by the application repository to push images."
  type        = string
  default     = "app-image-publisher"
}

variable "github_workload_identity_pool_id" {
  description = "Global Workload Identity Pool ID for GitHub Actions."
  type        = string
  default     = "github-actions"
}

variable "github_infra_provider_id" {
  description = "OIDC provider ID for the infrastructure repository."
  type        = string
  default     = "github-oidc"
}

variable "github_app_provider_id" {
  description = "OIDC provider ID for the application repository."
  type        = string
  default     = "github-app-oidc"
}

variable "github_infra_repository" {
  description = "GitHub owner/repository allowed to authenticate as Terraform."
  type        = string
  default     = "Deepakdev-lab/gcp-infra-devsecops"
}

variable "github_app_repository" {
  description = "GitHub owner/repository allowed to publish application images."
  type        = string
  default     = "Deepakdev-lab/gcp-app-devsecops"
}

variable "app_deployer_service_account_id" {
  description = "Account ID used by the application repository to deploy Cloud Run revisions."
  type        = string
  default     = "app-deployer"
}