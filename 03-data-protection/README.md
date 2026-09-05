# Data Protection

## Definition

Data protection preserves confidentiality, integrity, and availability across the data lifecycle: creation, storage, use, transmission, backup, and deletion.

## GCP resource mapping

| Security concept | GCP resource or service | Practical use |
|---|---|---|
| Secret storage | Secret Manager | Store API keys, passwords, and certificates outside source code |
| Key management | Cloud KMS key rings and keys | Control encryption keys and rotation |
| Customer-managed encryption | CMEK | Use a key you control for supported services |
| Object storage | Cloud Storage | Apply uniform bucket-level access, retention, and public access prevention |
| Database protection | Cloud SQL / Spanner encryption controls | Protect structured data and backups |
| Sensitive-data discovery | Sensitive Data Protection | Inspect and classify sensitive data |
| Exfiltration boundary | VPC Service Controls | Reduce data movement from supported managed services |
| Audit evidence | Cloud Audit Logs | Record administrative and data access activity |

## Rules to practice

- Never store secrets in Git, images, or plain-text configuration.
- Enable public access prevention on sensitive Cloud Storage buckets.
- Use uniform bucket-level access instead of object ACL sprawl.
- Separate key administrators from data users where possible.
- Define retention and deletion requirements before creating production data.

## Lab outcome

Create a private bucket, store a non-sensitive test value in Secret Manager, and document who can read the object and secret and why.
