data "google_project" "current" {
  project_id = var.project_id
}

data "google_service_account" "terraform_deployer" {
  account_id = var.terraform_service_account_id
  project    = var.project_id
}

# Creates the global Workload Identity Pool used by GitHub Actions OIDC tokens.
resource "google_iam_workload_identity_pool" "github_actions" {
  workload_identity_pool_id = var.github_workload_identity_pool_id
  display_name              = "GitHub Actions"
  description               = "Keyless GitHub Actions authentication for this project."
  disabled                  = false
}

# Restricts the infrastructure repository's OIDC tokens to the infrastructure repository.
resource "google_iam_workload_identity_pool_provider" "github_infra" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_actions.workload_identity_pool_id
  workload_identity_pool_provider_id = var.github_infra_provider_id
  display_name                       = "GitHub infrastructure OIDC"
  attribute_condition                = "assertion.repository == '${var.github_infra_repository}'"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Restricts the application repository's OIDC tokens to the application repository.
resource "google_iam_workload_identity_pool_provider" "github_app" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_actions.workload_identity_pool_id
  workload_identity_pool_provider_id = var.github_app_provider_id
  display_name                       = "GitHub application OIDC"
  attribute_condition                = "assertion.repository == '${var.github_app_repository}'"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Allows the infrastructure repository to impersonate the Terraform deployment service account.
resource "google_service_account_iam_member" "github_infra" {
  service_account_id = data.google_service_account.terraform_deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${data.google_project.current.number}/locations/global/workloadIdentityPools/${var.github_workload_identity_pool_id}/attribute.repository/${var.github_infra_repository}"
}

# Allows the application repository to impersonate the dedicated image publisher service account.
resource "google_service_account_iam_member" "github_app" {
  service_account_id = google_service_account.app_publisher.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${data.google_project.current.number}/locations/global/workloadIdentityPools/${var.github_workload_identity_pool_id}/attribute.repository/${var.github_app_repository}"
}