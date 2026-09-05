# Network Security

## Definition

Network security controls which systems can communicate, from where, over which ports, and through which path. The goal is to reduce exposure and create deliberate trust boundaries.

## GCP resource mapping

| Security concept | GCP resource or service | Practical use |
| --- | --- | --- |
| Private network boundary | VPC network | Isolate workloads and define routing |
| Network segmentation | Subnets and custom routes | Separate application tiers and regions |
| Stateful traffic control | VPC firewall rules | Allow only required ingress and egress |
| Outbound-only internet access | Cloud NAT | Let private workloads reach the internet without public IPs |
| Access to Google APIs privately | Private Google Access / Private Service Connect | Avoid public paths where supported |
| Web application protection | Cloud Armor | WAF rules, rate limiting, DDoS protection |
| Service exposure | External/internal load balancers | Publish only intended entry points |
| Connectivity inspection | VPC Flow Logs and Connectivity Tests | Investigate traffic and routing |

## Rules to practice

- Default-deny ingress where practical.
- Use tags or service accounts to target firewall rules narrowly.
- Keep databases and internal services on private addresses.
- Restrict administrative access through IAP, VPN, or an approved bastion pattern.
- Enable VPC Flow Logs for important subnets.

## Lab outcome

Deploy a private test VM or service, permit only required traffic from a controlled source, and confirm that direct public access is unavailable.

## Terraform lab

This directory contains the first Terraform foundation for the lab:

- Custom-mode VPC with regional routing.
- Private subnet with Private Google Access.
- VPC Flow Logs.
- Internal traffic and IAP SSH firewall rules.
- Cloud Router.
- Optional Cloud NAT, disabled by default.
- Private GCS application bucket with public access prevention.
- Dedicated Cloud Run service account with bucket-scoped IAM.
- Separate GCS bucket for application-bucket access logs.
- Required Google Cloud APIs managed through a Terraform `for_each` loop.
- Cloud Run services enabled for the first application deployment using the initial image SHA.

### Use case: Cloud Run to GCS

The application runs on Cloud Run and reads or writes objects in a GCS bucket. The intended trust path is:

```text
Cloud Run service
  -> dedicated Cloud Run service account
  -> bucket-level IAM role
  -> private GCS bucket
```

Cloud Run does not need Cloud NAT or a VPC just to call GCS. The application authenticates with its attached service account and uses the Google Cloud Storage API. The bucket is private because public access prevention is enabled; access is granted to the service account through IAM.

The default role is `roles/storage.objectViewer`, which permits object reads. For an upload application, use `roles/storage.objectUser` instead of granting broad project-level storage permissions.

### Prerequisites

- Terraform 1.5.7 or later.
- Google Cloud CLI authenticated with `gcloud auth application-default login`.
- A dedicated sandbox project with billing and the Compute Engine API enabled.
- A budget alert configured before creating billable resources.
- Globally unique names for both GCS buckets.

Terraform manages these APIs from the `locals` block in `apis.tf`:

```text
artifactregistry.googleapis.com
cloudresourcemanager.googleapis.com
compute.googleapis.com
iam.googleapis.com
iamcredentials.googleapis.com
run.googleapis.com
serviceusage.googleapis.com
storage.googleapis.com
sts.googleapis.com
```

API resources use `disable_on_destroy = false`, so running the destroy workflow removes lab resources without disabling APIs that may be shared by the project.

### Cloud Run prerequisite switch

Cloud Run creation is enabled for the first application deployment:

```hcl
enable_cloud_run = true
```

The initial image tag is `d717e2b00656369bdc62e68660b7f29efe235a3d`. Terraform owns the `enable_cloud_run = true` setting; no `ENABLE_CLOUD_RUN` GitHub variable is required. The workflow defaults to the initial image tag when `GCP_BACKEND_IMAGE` and `GCP_UI_IMAGE` are not configured. The Cloud Run definitions remain in `cloud_run_services.tf`.

Cloud Run deletion protection is explicitly disabled for this disposable lab. To destroy Cloud Run safely, run a normal `apply` once after this setting is introduced, then run the protected `destroy` operation.

### GitHub variables and Terraform WIF

Terraform manages the Google Cloud WIF pool, providers, service accounts, and IAM bindings in `wif.tf`. It does not call the GitHub API or store GitHub tokens. Configure the infrastructure repository variables under **Settings > Secrets and variables > Actions > Variables**. The application repository configures its own variables at the start of its image-build workflow using the short-lived built-in GitHub token. The existing WIF pool and providers were created manually before Terraform management was added, so import them once before applying:

```powershell
.\terraform.exe import google_iam_workload_identity_pool.github_actions projects/565532451627/locations/global/workloadIdentityPools/github-actions
.\terraform.exe import google_iam_workload_identity_pool_provider.github_infra projects/565532451627/locations/global/workloadIdentityPools/github-actions/providers/github-oidc
```

The application provider may not exist yet. If importing it returns `Cannot import non-existent remote object`, create it through Terraform:

```powershell
.\terraform.exe apply -target=google_iam_workload_identity_pool_provider.github_app
```

Do not import a resource that does not exist. After the targeted create succeeds, run a normal plan and review the remaining changes. The imported pool and infrastructure provider use `ignore_changes = all` because they were bootstrapped manually; the Terraform module will not attempt to update them.

### Initialize and plan

Terraform uses a separate GCS bucket for remote state. This bucket is the one bootstrap resource that must be created outside Terraform because Terraform needs the bucket before it can initialize the backend.

First authenticate both the Google Cloud CLI and Application Default Credentials:

```powershell
gcloud auth login
gcloud auth application-default login
gcloud auth application-default set-quota-project project-a95e6dc6-f7fc-4043-bf9
```

Create only the remote-state bucket:

```powershell
gcloud storage buckets create gs://project-a95e6dc6-f7fc-4043-bf9-tfstate `
  --project=project-a95e6dc6-f7fc-4043-bf9 `
  --location=us-east4 `
  --uniform-bucket-level-access

gcloud storage buckets update gs://project-a95e6dc6-f7fc-4043-bf9-tfstate `
  --versioning

gcloud storage buckets update gs://project-a95e6dc6-f7fc-4043-bf9-tfstate `
  --public-access-prevention
```

Then run these commands from this directory:

```powershell
.\terraform.exe init
.\terraform.exe fmt -check
.\terraform.exe validate
.\terraform.exe plan -out=tfplan
```

Terraform will detect the GCS backend and migrate any existing local state after confirmation. Review the plan carefully. Terraform will not create the application VPC, GCS buckets, service account, or IAM resources until `apply` is run.

### Apply and destroy

```powershell
terraform apply tfplan
terraform output

# Delete the lab when finished.
terraform destroy
```

Cloud NAT is intentionally disabled at first. Set `enable_nat = true`, run a new `terraform plan`, and apply it only when testing outbound access from a private VM. It is not required for the Cloud Run-to-GCS path.

### Deploying Cloud Run with this identity

After Terraform applies, retrieve the service account email:

```powershell
terraform output -raw cloud_run_service_account_email
```

Attach that identity when deploying the Cloud Run service:

```powershell
gcloud run deploy SERVICE_NAME `
  --source . `
  --region REGION `
  --service-account CLOUD_RUN_SERVICE_ACCOUNT_EMAIL
```

Replace `SERVICE_NAME`, `REGION`, and `CLOUD_RUN_SERVICE_ACCOUNT_EMAIL` with your values. The application should use the Google Cloud Storage client library and application default credentials; do not add a service-account key file to the container.

### GitHub Actions pipeline

The repository workflow at `.github/workflows/terraform-network-security.yml` runs Terraform format checking, initialization, validation, and planning for pull requests, pushes to `main`, and manual runs.

Before using the workflow, configure these GitHub repository variables:

- `GCP_WORKLOAD_IDENTITY_PROVIDER`: full Workload Identity Federation provider resource name.
- `GCP_TERRAFORM_SERVICE_ACCOUNT`: service account email used by GitHub Actions.
- `GCP_PROJECT_ID`: project ID used for the optional workflow environment link.
- `GCP_BACKEND_IMAGE`: full GAR URL for the backend image, including its tag.
- `GCP_UI_IMAGE`: full GAR URL for the UI image, including its tag.

Configure GitHub Environments named `terraform-apply` and `terraform-destroy`, and add required reviewers under each environment's deployment protection rules. From a manual workflow dispatch on `main`, choose `plan`, `apply`, or `destroy`:

- `plan` runs the plan only.
- `apply` creates or updates resources after approval from `terraform-apply`.
- `destroy` creates a destroy plan, then deletes the managed resources only after approval from `terraform-destroy`.

The destroy job applies the reviewed destroy plan. It does not run an unplanned `terraform destroy` command.

The GitHub Actions service account needs access to the remote state bucket and permission to manage the resources in this module. Workload Identity Federation is used so the workflow does not store a service-account key.

### Cloud Run application deployment

The application repository is `Deepakdev-lab/gcp-app-devsecops`. It contains a Node.js UI and a Python backend. Both images are pushed to the GAR repository created by this module.

Use this order for the first deployment:

1. Create the GAR repository without attempting to deploy Cloud Run:

  ```powershell
  .\terraform.exe apply -target=google_artifact_registry_repository.cloud_run
  ```

1. Configure the application repository's WIF variables and run its **Build and Push Cloud Run Images** workflow.
1. Set `backend_image` and `ui_image` in `terraform.tfvars` to the image URLs printed by that workflow.
1. Run `terraform plan` and apply through the protected GitHub Actions `apply` operation.

For the GitHub Actions plan, `GCP_BACKEND_IMAGE` and `GCP_UI_IMAGE` are optional repository overrides. The workflow passes them to Terraform as `TF_VAR_backend_image` and `TF_VAR_ui_image`, using the initial published image tag when they are absent. A push to `main` runs plan and then requests approval in `terraform-apply` before applying. Pull requests remain plan-only.

The backend reads `sample-data.txt` from the private application bucket using the `cloud-run-gcs-app` service account. The UI receives the backend URL from Terraform and calls `/api/data`. Both services are public for this lab; the bucket remains private.

### Learning sequence

1. Apply the bucket, service account, and bucket IAM resources.
2. Deploy a small Cloud Run service with the Terraform-created service account.
3. Verify that the service can read the bucket and cannot access an unrelated bucket.
4. Inspect bucket access logs and Cloud Audit Logs.
5. Apply the VPC and subnet with NAT disabled.
6. Add a private VM in a later exercise and connect through IAP.
7. Enable NAT and verify outbound-only internet access from the VM.
8. Add Private Service Access for a managed service such as Cloud SQL.
9. Add Private Service Connect for a private service endpoint.
10. Study VPC Service Controls last; it protects supported managed services from data exfiltration and is not a replacement for IAM, firewall rules, or routes.
