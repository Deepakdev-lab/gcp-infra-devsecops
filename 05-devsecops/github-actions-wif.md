# GitHub Actions Workload Identity Federation

This guide configures keyless authentication from the GitHub repository to Google Cloud. GitHub Actions receives a short-lived OIDC token and exchanges it for access to the Terraform deployment service account. No service-account JSON key is stored in GitHub.

## Values

Run these commands in PowerShell. Replace only the repository value if the repository changes.

```powershell
$PROJECT_ID = "project-a95e6dc6-f7fc-4043-bf9"
$GITHUB_REPOSITORY = "Deepakdev-lab/gcp-infra-devsecops"
$SERVICE_ACCOUNT_ID = "terraform-deployer"
$POOL_ID = "github-actions"
$PROVIDER_ID = "github-oidc"
```

Get the numeric project ID. Workload Identity Federation resource names require the project number, not only the project ID:

```powershell
$PROJECT_NUMBER = gcloud projects describe $PROJECT_ID --format="value(projectNumber)"
$SERVICE_ACCOUNT_EMAIL = "$SERVICE_ACCOUNT_ID@$PROJECT_ID.iam.gserviceaccount.com"
```

## Enable APIs

```powershell
gcloud services enable iamcredentials.googleapis.com `
  iam.googleapis.com `
  sts.googleapis.com `
  --project=$PROJECT_ID
```

## Create the Terraform service account

This identity is used by GitHub Actions to run Terraform. It is separate from the Cloud Run runtime identity.

```powershell
gcloud iam service-accounts create $SERVICE_ACCOUNT_ID `
  --project=$PROJECT_ID `
  --display-name="Terraform GitHub Actions deployer"
```

For this learning lab, grant the deployment identity the following project roles:

```powershell
gcloud projects add-iam-policy-binding $PROJECT_ID `
  --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" `
  --role="roles/editor"

gcloud projects add-iam-policy-binding $PROJECT_ID `
  --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" `
  --role="roles/iam.serviceAccountAdmin"

gcloud projects add-iam-policy-binding $PROJECT_ID `
  --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" `
  --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding $PROJECT_ID `
  --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" `
  --role="roles/storage.admin"
```

`roles/editor` is intentionally broad for this learning lab. Replace it with resource-specific roles before using this pattern in production.

Grant access to the remote Terraform state bucket:

```powershell
gcloud storage buckets add-iam-policy-binding `
  gs://project-a95e6dc6-f7fc-4043-bf9-tfstate `
  --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" `
  --role="roles/storage.objectAdmin"
```

## Create the workload identity pool

```powershell
gcloud iam workload-identity-pools create $POOL_ID `
  --project=$PROJECT_ID `
  --location=global `
  --display-name="GitHub Actions"
```

## Create the GitHub OIDC provider

The condition limits token exchange to this GitHub repository. Pull requests and pushes from other repositories cannot impersonate the service account.

```powershell
gcloud iam workload-identity-pools providers create-oidc $PROVIDER_ID `
  --project=$PROJECT_ID `
  --location=global `
  --workload-identity-pool=$POOL_ID `
  --display-name="GitHub Actions OIDC" `
  --issuer-uri="https://token.actions.githubusercontent.com" `
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.ref=assertion.ref" `
  --attribute-condition="assertion.repository == '$GITHUB_REPOSITORY'"
```

## Allow GitHub to impersonate the service account

```powershell
$WIF_MEMBER = "principalSet://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$POOL_ID/attribute.repository/$GITHUB_REPOSITORY"

gcloud iam service-accounts add-iam-policy-binding $SERVICE_ACCOUNT_EMAIL `
  --project=$PROJECT_ID `
  --role="roles/iam.workloadIdentityUser" `
  --member=$WIF_MEMBER
```

## Configure GitHub repository variables

Get the provider resource name:

```powershell
$WIF_PROVIDER = "projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$POOL_ID/providers/$PROVIDER_ID"
$WIF_PROVIDER
$SERVICE_ACCOUNT_EMAIL
```

In GitHub, open **Settings > Secrets and variables > Actions > Variables** and create:

| Name | Value |
| --- | --- |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | The `$WIF_PROVIDER` output |
| `GCP_TERRAFORM_SERVICE_ACCOUNT` | The `$SERVICE_ACCOUNT_EMAIL` output |
| `GCP_PROJECT_ID` | `project-a95e6dc6-f7fc-4043-bf9` |

The workflow at `.github/workflows/terraform-network-security.yml` already reads these variable names.

## Configure apply approval

Create a GitHub Environment named `terraform-apply`:

1. Open **Settings > Environments > New environment**.
2. Name it `terraform-apply`.
3. Add required reviewers under deployment protection rules.
4. Save the environment.

The workflow runs `plan` automatically. The `apply` job runs only from **Actions > Terraform Network Security > Run workflow** on the `main` branch. It pauses at the `terraform-apply` environment until a required reviewer approves it.

## Verify the setup

```powershell
gcloud iam workload-identity-pools providers describe $PROVIDER_ID `
  --project=$PROJECT_ID `
  --location=global `
  --workload-identity-pool=$POOL_ID

gcloud iam service-accounts get-iam-policy $SERVICE_ACCOUNT_EMAIL `
  --project=$PROJECT_ID
```

Then run the workflow manually. A successful plan followed by an approval request confirms the GitHub OIDC and service-account configuration.
