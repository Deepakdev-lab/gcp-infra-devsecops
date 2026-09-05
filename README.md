# GCP Infrastructure Security and DevSecOps

This workspace is a hands-on learning path for a GCP Infrastructure Security and DevSecOps role.

## Learning map

| Definition | GCP resources | Read next |
|---|---|---|
| Identity and access management | IAM, service accounts, Cloud Identity, Organization Policy | [01-iam](01-iam/README.md) |
| Network security | VPC, subnets, firewall rules, Cloud NAT, Private Google Access, Cloud Armor | [02-network-security](02-network-security/README.md) |
| Data protection | Cloud KMS, Secret Manager, Cloud Storage, CMEK, VPC Service Controls | [03-data-protection](03-data-protection/README.md) |
| Logging and monitoring | Cloud Logging, Cloud Monitoring, Audit Logs, Security Command Center | [04-logging-monitoring](04-logging-monitoring/README.md) |
| DevSecOps delivery | Cloud Build, Artifact Registry, Binary Authorization, Cloud Deploy, Terraform | [05-devsecops](05-devsecops/README.md) |
| Governance and response | Resource Manager, folders, projects, budgets, constraints, incident response | [06-governance](06-governance/README.md) |

## Suggested order

1. Create or select one sandbox project.
2. Learn IAM and avoid using owner permissions for daily work.
3. Build a small VPC and restrict ingress.
4. Store a test secret and encrypt a test bucket with Cloud KMS.
5. Enable audit logging and create an alert.
6. Build a container pipeline with scanning and deployment controls.
7. Add governance policies, budgets, and an incident runbook.

## Project safety

Use a dedicated trial project. Set a budget alert before creating resources. Delete labs when finished, and avoid exposing public IPs, buckets, databases, or credentials unless the exercise explicitly requires it.

## GCP project access

This workspace cannot attach itself to a GCP project by folder access alone. The local machine needs:

- Google Cloud CLI (`gcloud`) installed.
- A browser-authenticated Google account: `gcloud auth login`.
- The trial project ID, set with `gcloud config set project PROJECT_ID`.
- Billing enabled only where a lab requires a billable API or resource.

Do not place service-account keys, passwords, or access tokens in this folder. Prefer user authentication locally and Workload Identity Federation in CI/CD.
