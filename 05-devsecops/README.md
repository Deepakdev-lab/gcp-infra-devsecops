# DevSecOps Delivery

## Definition

DevSecOps integrates security into planning, source control, build, artifact management, deployment, and runtime operations. Controls should be automated and produce evidence without blocking every normal developer action.

## GCP resource mapping

| Security concept | GCP resource or service | Practical use |
| --- | --- | --- |
| Infrastructure as code | Terraform with Google provider | Review and reproduce infrastructure changes |
| CI builds | Cloud Build | Run tests, policy checks, and image builds |
| Artifact storage | Artifact Registry | Store container images and packages privately |
| Vulnerability scanning | Artifact Analysis | Scan supported artifacts for vulnerabilities |
| Deployment promotion | Cloud Deploy | Promote releases between environments |
| Admission control | Binary Authorization | Require trusted attestations before deployment |
| Runtime platform | Cloud Run / GKE | Run containerized workloads with different control surfaces |
| Policy as code | Organization Policy, Policy Controller, Terraform validation | Enforce guardrails before or during deployment |
| Supply-chain identity | Workload Identity Federation | Authenticate CI without static keys |

## GitHub Actions lab

Configure keyless GitHub Actions authentication with the [GitHub Actions Workload Identity Federation guide](github-actions-wif.md). It matches the Terraform workflow in `.github/workflows/terraform-network-security.yml`.

## Rules to practice

- Scan dependencies and container images before deployment.
- Pin versions and review Terraform changes.
- Keep build, deploy, and runtime identities separate.
- Require signed or attested artifacts for sensitive environments.
- Store build logs and deployment evidence centrally.
- Treat CI configuration as production security code.

## Lab outcome

Build a small container, push it to Artifact Registry, scan it, and deploy only after a successful test and security check.
