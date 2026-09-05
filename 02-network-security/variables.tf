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