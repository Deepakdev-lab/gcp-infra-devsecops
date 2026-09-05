# Governance and Incident Response

## Definition

Governance makes security consistent across projects. Incident response defines how to detect, contain, investigate, recover from, and learn from security events.

## GCP resource mapping

| Security concept | GCP resource or service | Practical use |
|---|---|---|
| Resource hierarchy | Organization, folders, projects | Separate environments and apply inherited policy |
| Preventive guardrails | Organization Policy Service | Restrict locations, public access, allowed services, and identities |
| Asset inventory | Cloud Asset Inventory | Search resource configuration and history |
| Security posture | Security Command Center | Track findings and posture issues |
| Cost governance | Budgets and billing reports | Detect unexpected spend and reduce trial-project risk |
| Change governance | Terraform, Cloud Deploy, IAM approvals | Make changes reviewable and traceable |
| Incident evidence | Cloud Logging and Audit Logs | Reconstruct actions and timelines |
| Containment | IAM, firewall rules, service-account controls | Remove access and isolate affected resources |

## Rules to practice

- Separate sandbox, non-production, and production projects.
- Set budget alerts before creating billable resources.
- Define who can approve privileged changes.
- Keep an incident runbook with contacts, containment steps, and evidence locations.
- Test recovery rather than assuming backups work.

## Lab outcome

Write a one-page incident runbook for a leaked service credential: revoke access, identify affected resources, review logs, rotate the secret, and document lessons learned.
