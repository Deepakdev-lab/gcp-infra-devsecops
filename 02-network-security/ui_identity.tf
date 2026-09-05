# Creates a separate runtime identity for the public UI service.
resource "google_service_account" "ui" {
  account_id   = var.ui_service_account_id
  display_name = "Cloud Run public UI identity"
  description  = "Runtime identity for the public Node.js UI."
}