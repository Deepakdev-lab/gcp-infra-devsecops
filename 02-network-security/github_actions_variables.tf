provider "github" {
  owner = var.github_owner
}

# Creates the infrastructure repository's project variable.
resource "github_actions_variable" "infra_project_id" {
  repository    = var.github_infra_repository_name
  variable_name = "GCP_PROJECT_ID"
  value         = var.project_id
}

# Creates the infrastructure repository's WIF provider variable.
resource "github_actions_variable" "infra_wif_provider" {
  repository    = var.github_infra_repository_name
  variable_name = "GCP_WORKLOAD_IDENTITY_PROVIDER"
  value         = google_iam_workload_identity_pool_provider.github_infra.name
}

# Creates the infrastructure repository's Terraform service account variable.
resource "github_actions_variable" "infra_service_account" {
  repository    = var.github_infra_repository_name
  variable_name = "GCP_TERRAFORM_SERVICE_ACCOUNT"
  value         = data.google_service_account.terraform_deployer.email
}

# Creates the infrastructure repository's backend image variable.
resource "github_actions_variable" "infra_backend_image" {
  repository    = var.github_infra_repository_name
  variable_name = "GCP_BACKEND_IMAGE"
  value         = var.backend_image
}

# Creates the infrastructure repository's UI image variable.
resource "github_actions_variable" "infra_ui_image" {
  repository    = var.github_infra_repository_name
  variable_name = "GCP_UI_IMAGE"
  value         = var.ui_image
}

# Creates the application repository's project variable.
resource "github_actions_variable" "app_project_id" {
  repository    = var.github_app_repository_name
  variable_name = "GCP_PROJECT_ID"
  value         = var.project_id
}

# Creates the application repository's GAR location variable.
resource "github_actions_variable" "app_gar_location" {
  repository    = var.github_app_repository_name
  variable_name = "GAR_LOCATION"
  value         = var.artifact_registry_location
}

# Creates the application repository's GAR repository variable.
resource "github_actions_variable" "app_gar_repository" {
  repository    = var.github_app_repository_name
  variable_name = "GAR_REPOSITORY"
  value         = var.artifact_registry_repository_id
}

# Creates the application repository's WIF provider variable.
resource "github_actions_variable" "app_wif_provider" {
  repository    = var.github_app_repository_name
  variable_name = "GCP_WORKLOAD_IDENTITY_PROVIDER"
  value         = google_iam_workload_identity_pool_provider.github_app.name
}

# Creates the application repository's dedicated publisher service account variable.
resource "github_actions_variable" "app_service_account" {
  repository    = var.github_app_repository_name
  variable_name = "GCP_IMAGE_PUBLISHER_SERVICE_ACCOUNT"
  value         = google_service_account.app_publisher.email
}