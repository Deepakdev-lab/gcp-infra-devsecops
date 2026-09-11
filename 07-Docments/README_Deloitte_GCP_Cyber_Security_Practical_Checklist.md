# Deloitte GCP Cyber Security – Practical Preparation Checklist

## Objective

This checklist is designed for a **Senior Consultant – GCP Cyber Security** interview and hands-on preparation.

The goal is to focus on the practical areas that are still pending or need deeper hands-on validation, instead of repeating topics that are already well covered.

---

# 1. Current Practical Coverage

## Already Covered / Strong Foundation

- GCP VPC, subnet, firewall, routing concepts
- Cloud Run private ingress and connectivity
- GKE deployment basics
- Private Service Connect (PSC)
- Cloud SQL PSC connectivity
- Vertex AI / Vector Search private connectivity
- Google Cloud Storage security basics
- Public Access Prevention
- Uniform Bucket-Level Access (UBLA)
- Service Accounts and Service Agents
- IAM basics
- GitHub Actions with Workload Identity Federation / OIDC
- Terraform infrastructure provisioning
- Cloud Armor
- HTTPS Load Balancer / Gateway
- DNS and custom domain configuration
- DevSecOps concepts
- SAST / SCA / CodeQL
- Vertex AI / RAG architecture
- DLP and prompt-injection security concepts

---

# 2. VPC Service Controls – Highest Priority

## Hands-On Tasks

- Create Access Context Manager policy
- Create a VPC Service Controls perimeter
- Add a GCP project to the perimeter
- Protect services such as:
  - Cloud Storage
  - BigQuery
  - Vertex AI
- Configure restricted services
- Test access from inside the perimeter
- Test access from outside the perimeter
- Generate a deliberate VPC-SC denial
- Inspect Policy Denied / audit logs
- Configure ingress policy
- Configure egress policy
- Understand dry-run vs enforced perimeter
- Test service-to-service communication

## Interview Goal

Be able to explain:

```text
IAM
WHO can access the resource?

VPC Firewall
WHAT network traffic is allowed?

VPC Service Controls
WHERE protected Google API data is allowed to move?
```

---

# 3. Security Command Center

## Hands-On Tasks

- Enable Security Command Center
- Review Security Health Analytics findings
- Review vulnerability findings
- Review Event Threat Detection concepts
- Investigate affected resources
- Understand:
  - Severity
  - Category
  - Source
  - Resource
  - Attack path
- Remediate a finding
- Verify remediation
- Export findings to:
  - Cloud Logging
  - Pub/Sub
  - BigQuery
- Create alerting workflow

## Incident Flow

```text
SCC Finding
   ↓
Validate Severity
   ↓
Identify Resource
   ↓
Check Exposure
   ↓
IAM + Network + Logs
   ↓
Contain
   ↓
Remediate
   ↓
Validate
   ↓
Document
```

---

# 4. IAM and Organization Policy

## Hands-On Tasks

- Create IAM custom role
- Assign predefined roles
- Compare:
  - Organization-level IAM
  - Folder-level IAM
  - Project-level IAM
- Service Account impersonation
- Test Service Account Token Creator
- Policy Troubleshooter
- Policy Analyzer
- IAM Recommender
- Remove excessive permissions
- Configure Organization Policy constraints

## Important Organization Policies

Practice policies related to:

- Preventing service-account key creation
- Restricting external IP addresses
- Restricting resource locations
- Domain restricted sharing
- Public access restrictions
- Trusted image projects

## Key Difference

```text
IAM
Controls WHO can perform an action.

Organization Policy
Controls WHAT configurations are permitted.

Firewall
Controls NETWORK traffic.

VPC Service Controls
Controls DATA movement across Google managed services.
```

---

# 5. Threat Modeling and Security Assessment

Use an existing architecture:

```text
Internet
   ↓
Cloud Armor
   ↓
HTTPS Load Balancer
   ↓
Cloud Run / GKE
   ↓
Vertex AI
   ↓
Vector Search
   ↓
Cloud SQL / GCS
```

## Perform Threat Modeling

Identify:

- Assets
- Identities
- Trust boundaries
- Entry points
- Data flows
- Threats
- Likelihood
- Impact
- Risk rating
- Mitigation
- Residual risk

## STRIDE

```text
S – Spoofing
T – Tampering
R – Repudiation
I – Information Disclosure
D – Denial of Service
E – Elevation of Privilege
```

## Example

```text
Threat:
Prompt injection

Risk:
Unauthorized retrieval of sensitive RAG content

Controls:
- Authentication
- IAM
- Input validation
- DLP
- RAG authorization
- VPC-SC
- Output filtering
- Audit logging
```

---

# 6. Wiz / CSPM / CWPP

## Concepts to Master

```text
CSPM
Cloud Security Posture Management
→ Detects cloud misconfigurations

CWPP
Cloud Workload Protection Platform
→ Protects workloads and runtime

CNAPP
Cloud Native Application Protection Platform
→ Unified cloud security platform
```

## Practical Security Scenario

```text
Public workload
      +
Overprivileged Service Account
      +
Sensitive GCS access
      +
Known vulnerability
      ↓
High-risk attack path
```

Focus on:

- Risk prioritization
- Exposure paths
- Identity risks
- Vulnerabilities
- Kubernetes security
- Cloud workload protection

---

# 7. GKE and Container Security

## Hands-On Tasks

- Workload Identity Federation for GKE
- Kubernetes RBAC
- Namespace isolation
- NetworkPolicy
- Private GKE cluster
- Secret Manager integration
- Artifact Registry
- Container vulnerability scanning
- Binary Authorization
- Pod Security Standards
- Kubernetes audit logs
- Admission controls

## Secure Pipeline

```text
Developer
   ↓
GitHub
   ↓
SAST / SCA
   ↓
Build
   ↓
Artifact Registry
   ↓
Vulnerability Scan
   ↓
Binary Authorization
   ↓
GKE
   ↓
RBAC + NetworkPolicy
   ↓
Workload Identity
   ↓
GCP APIs
```

---

# 8. Logging, Detection, and Monitoring

## Generate and Investigate Events

Practice with:

- IAM role changes
- Service Account impersonation
- Firewall changes
- Bucket IAM changes
- Failed authentication
- VPC-SC violations
- Cloud Armor blocks
- Kubernetes events

## Audit Log Types

```text
Admin Activity
Data Access
System Event
Policy Denied
```

## Hands-On Tasks

- Cloud Logging
- Logs Explorer
- Log-based metrics
- Cloud Monitoring alert
- SCC integration
- Pub/Sub export
- BigQuery log sink
- Incident investigation

---

# 9. AI / GenAI Security

## Secure Architecture

```text
User
 ↓
Cloud Armor
 ↓
Authenticated API
 ↓
Prompt Validation
 ↓
DLP / Sensitive Data Control
 ↓
Vertex AI / Gemini
 ↓
RAG
 ↓
Vector Search
 ↓
Authorized Documents Only
 ↓
Output Validation
 ↓
Logging / Monitoring
```

## Security Areas

- Prompt injection
- Sensitive-data leakage
- Malicious documents
- Unauthorized RAG retrieval
- Excessive AI permissions
- Data isolation
- Model access control
- Vertex AI Service Accounts
- VPC-SC
- DLP
- Responsible AI
- Model risk
- Audit logging

---

# 10. Compliance and Security Frameworks

Create a mapping between technical controls and security frameworks.

| Risk | GCP Control | Framework |
|---|---|---|
| Excessive IAM | Least Privilege | CIS / NIST |
| Public bucket | PAP + Org Policy | CIS |
| Data exfiltration | VPC-SC | NIST |
| Internet attacks | Cloud Armor | NIST |
| Encryption | Cloud KMS / CMEK | ISO / NIST |
| Misconfiguration | SCC | CIS / NIST |
| Auditability | Cloud Audit Logs | ISO / NIST |
| Vulnerable containers | Artifact Analysis | CIS |

Frameworks to understand:

- ISO 27001
- NIST CSF
- CIS Benchmarks
- PCI-DSS
- HIPAA

---

# 11. Terraform Security / Policy as Code

## Secure IaC Pipeline

```text
terraform fmt
     ↓
terraform validate
     ↓
tflint
     ↓
Checkov / tfsec
     ↓
terraform plan
     ↓
Security Policy Validation
     ↓
Approval
     ↓
terraform apply
```

## Deliberately Test Bad Terraform

Create examples containing:

- Public GCS bucket
- `0.0.0.0/0` firewall rule
- Excessive IAM role
- Public IP
- Unencrypted resource
- Disabled logging

Ensure security tooling detects and blocks the deployment.

---

# 12. Final Preparation Priority

Recommended execution order:

```text
1. VPC Service Controls
2. Security Command Center
3. Organization Policy + IAM Governance
4. Threat Modeling
5. GKE Security
6. Logging + Detection
7. AI / GenAI Security
8. Wiz / CSPM / CWPP
9. Compliance Mapping
10. Terraform Policy-as-Code
```

---

# Interview Readiness Goal

You should be able to explain every major security control in terms of:

```text
Problem
   ↓
Risk
   ↓
GCP Security Control
   ↓
Implementation
   ↓
Validation
   ↓
Monitoring
   ↓
Incident Response
```

This is the consultant-style mindset expected for a senior GCP Cyber Security role.
