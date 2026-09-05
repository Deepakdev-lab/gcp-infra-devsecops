# Identity and Access Management

## Definition

Identity and Access Management (IAM) answers: **who** can access **which resource**, **what action** can they perform, and **under which conditions**?

The core model is principal + role + resource. IAM is inherited through the hierarchy: organization, folder, project, and resource.

## GCP resource mapping

| Security concept | GCP resource or service | Practical use |
|---|---|---|
| Human identity | Cloud Identity / Google account | Sign-in for engineers and administrators |
| Authorization | IAM policies and roles | Grant only required permissions |
| Workload identity | Service account | Application or automation identity |
| Temporary access | IAM Conditions | Time, resource, or request-based restrictions |
| Privileged access | IAM Recommender, organization policies | Reduce excessive permissions |
| Hierarchy | Organization, folder, project | Apply policy at the right scope |
| Federated CI identity | Workload Identity Federation | Let GitHub Actions or another CI system access GCP without long-lived keys |

## Rules to practice

- Prefer predefined roles; use custom roles only when needed.
- Grant access to groups rather than individual users where possible.
- Use separate service accounts for separate workloads.
- Never commit service-account JSON keys.
- Avoid `roles/owner` and broad primitive roles for daily work.
- Review IAM bindings and service-account usage regularly.

## Lab outcome

Create a least-privilege service account for a small workload, grant one narrow role at project or resource scope, and verify that an unrelated action is denied.
