terraform {
  # The state bucket must be created once before running terraform init.
  # Backend blocks cannot use Terraform variables.
  # Create the referenced bucket in the us-east4 region.
  backend "gcs" {
    bucket = "project-a95e6dc6-f7fc-4043-bf9-tfstate"
    prefix = "network-security"
  }
}