# Deloitte Senior Consultant --- GCP Infrastructure Security, DevSecOps & AI Security Interview Guide

## 1. Role Focus

The role is centered on protecting GCP infrastructure while combining:

``` text
GCP Infrastructure
      +
Cloud Security
      +
IAM
      +
Networking
      +
DevSecOps / Terraform
      +
Security Monitoring
      +
AI / Agent Security
      +
Compliance
```

The strongest interview approach is to explain not only **what a service
is**, but:

``` text
Requirement
   -> Threat
   -> GCP control
   -> Implementation
   -> Validation
   -> Monitoring
```

------------------------------------------------------------------------

# 2. GCP IAM --- Must Know

Be comfortable explaining:

-   principal vs role vs permission
-   predefined vs custom roles
-   project/folder/org IAM inheritance
-   service accounts
-   service-account impersonation
-   short-lived credentials
-   Workload Identity Federation
-   Workload Identity Federation for GKE
-   IAM Conditions
-   least privilege
-   separation of duties
-   service agents vs user-managed service accounts
-   OAuth access token vs OIDC ID token

Example:

``` text
GitHub
  -> OIDC
  -> Workload Identity Pool/Provider
  -> deployment SA
  -> Terraform
```

Interview scenario:

> How would you remove service-account keys from CI/CD?

Answer with OIDC + Workload Identity Federation + short-lived
credentials.

------------------------------------------------------------------------

# 3. VPC Networking

Master:

``` text
VPC
Subnets
Routes
Firewall policies/rules
Private Google Access
Cloud NAT
Cloud Router
DNS
PSC
PSA
Load Balancing
Cloud Armor
Shared VPC
VPC Peering
```

Know this flow:

``` text
Private workload
   |
Subnet
   |
Cloud NAT
   |
Internet
```

and:

``` text
Client
   |
HTTPS Load Balancer
   |
Cloud Armor
   |
Backend
```

------------------------------------------------------------------------

# 4. PSC vs PSA vs Private Google Access

### Private Service Connect

Private consumer endpoint to a supported service.

``` text
Consumer VPC
   |
PSC endpoint
   |
Google/producer service
```

### Private Services Access

Private connectivity based on allocated address ranges and service
networking for supported managed services.

### Private Google Access

Allows workloads without external IP addresses to reach Google
APIs/services through Google networking.

Be able to explain which model Cloud SQL, Vertex AI and other services
support.

------------------------------------------------------------------------

# 5. VPC Service Controls

Key concepts:

``` text
Service Perimeter
Access Level
Ingress Policy
Egress Policy
Dry Run
Bridge
Restricted Services
```

Mental model:

> IAM answers **who is authorized**; VPC-SC reduces **where protected
> Google API data can move**.

Know that VPC-SC is not a replacement for VPC firewall rules.

Practice:

``` text
Create dry-run perimeter
  -> add supported services/projects
  -> generate expected traffic
  -> inspect violations
  -> add narrowly scoped ingress/egress
  -> enforce
```

------------------------------------------------------------------------

# 6. GKE Security

Know:

-   control plane vs node/data plane
-   private nodes
-   control-plane access
-   node pools
-   labels, taints, tolerations
-   Kubernetes RBAC
-   Google IAM
-   Workload Identity Federation for GKE
-   NetworkPolicy
-   Pod Security
-   Secret Manager
-   Artifact Registry
-   vulnerability scanning
-   Binary Authorization
-   Gateway API
-   Cloud Armor
-   Cloud NAT
-   logging/audit logs
-   cluster/node upgrades

Interview scenario:

> Secure a production GKE application.

Expected layers:

``` text
Private nodes
+ least-privilege IAM
+ Workload Identity
+ RBAC
+ NetworkPolicy
+ Pod Security
+ trusted images
+ Binary Authorization
+ Gateway/LB
+ Cloud Armor
+ TLS
+ logging/monitoring
```

------------------------------------------------------------------------

# 7. Terraform / Infrastructure as Code

Know:

-   providers
-   resources
-   variables
-   outputs
-   locals
-   modules
-   state
-   remote backend
-   locking
-   `plan`
-   `apply`
-   imports
-   lifecycle
-   dependencies
-   version pinning
-   module versioning
-   secrets handling
-   drift
-   CI/CD execution

Scenario:

> Terraform apply fails halfway.

Explain that Terraform records successful operations in state; fix the
root cause, refresh/plan, review resulting state and re-apply rather
than assuming a transactional rollback.

Security:

``` text
terraform fmt
terraform validate
terraform plan
IaC security scan
policy checks
approval
terraform apply
```

------------------------------------------------------------------------

# 8. DevSecOps Pipeline

A strong pipeline:

``` text
Developer
   |
PR
   |
SAST
SCA
Secret scanning
IaC scanning
   |
Build
   |
Container scanning
   |
Artifact Registry
   |
Policy / approval
   |
Deploy
   |
DAST / smoke tests
   |
Monitoring
```

Know the differences:

-   SAST = source/code security
-   SCA = vulnerable dependencies/licenses
-   secret scanning = credentials/tokens
-   IaC scanning = Terraform/Kubernetes misconfiguration
-   container scanning = image packages
-   DAST = running application
-   code quality = maintainability/reliability metrics

Be ready to discuss SonarQube, artifact repositories, GitHub
Actions/Jenkins and approval gates.

------------------------------------------------------------------------

# 9. Security Command Center (SCC)

Know SCC as the centralized GCP security posture/threat/finding layer
rather than thinking of it as a VM-like resource.

Understand:

``` text
Assets / cloud environment
        |
Security detectors/posture services
        |
        v
SCC Findings
        |
        +-- severity
        +-- category
        +-- affected resource
        +-- remediation
        |
        v
Cloud Logging / SIEM / ticketing / response
```

Topics:

-   findings
-   vulnerabilities/misconfigurations
-   threat detection
-   attack-path/risk concepts
-   posture management
-   organization/project activation depending on capability/tier
-   notification/export workflows
-   remediation ownership

------------------------------------------------------------------------

# 10. Cloud Logging & Monitoring

Know:

``` text
Cloud Audit Logs
Cloud Logging
Log Router
Log sinks
Cloud Monitoring
Metrics
Alerting
Dashboards
```

Audit-log categories:

-   Admin Activity
-   Data Access
-   System Event
-   Policy Denied

Scenario:

> How do you investigate an unauthorized IAM change?

Use Audit Logs to identify principal, method, resource, timestamp and
source context; correlate with SCC/security telemetry and remediate.

------------------------------------------------------------------------

# 11. Cloud Armor

Know:

-   edge/WAF protection
-   IP allow/deny
-   rate limiting
-   preconfigured WAF rules
-   SQL injection/XSS protections
-   adaptive/advanced protections where applicable
-   backend security policies
-   load-balancer integration

Architecture:

``` text
Internet
  |
Cloud Armor
  |
HTTPS Load Balancer
  |
GKE / Cloud Run backend
```

------------------------------------------------------------------------

# 12. Cloud SQL Security

Know:

-   private connectivity
-   PSC/PSA depending on design/service capability
-   IAM database authentication
-   TLS
-   CMEK where required
-   backups
-   HA
-   PITR
-   database flags
-   audit/logging
-   least-privilege DB users
-   Secret Manager
-   connection pooling
-   maintenance

Important distinction:

``` text
Cloud IAM
  -> resource/connect/auth permission

PostgreSQL privileges
  -> SQL/database authorization
```

------------------------------------------------------------------------

# 13. Encryption & Key Management

Know:

``` text
Google-managed encryption
CMEK
Cloud KMS
Key rings
Keys
Key versions
Rotation
IAM separation
HSM where required
```

Be ready for:

> When would you use CMEK?

Explain regulatory/customer control requirements, separation of duties,
key lifecycle and revocation considerations.

------------------------------------------------------------------------

# 14. Secret Management

Preferred architecture:

``` text
Workload Identity
   |
   v
Secret Manager
   |
short-lived authorized access
```

Avoid:

-   secrets in Git
-   secrets in Terraform source
-   long-lived service-account keys
-   plaintext Kubernetes manifests

------------------------------------------------------------------------

# 15. Threat Modeling

Use a repeatable structure:

``` text
Asset
  -> Trust boundary
  -> Threat
  -> Control
  -> Detection
  -> Response
```

For the RAG system:

``` text
User
 -> Agent
 -> Model
 -> Vector Search
 -> MCP
 -> Database
```

Threats include:

-   prompt injection
-   indirect prompt injection
-   excessive agency
-   data leakage
-   unauthorized tool execution
-   privilege escalation
-   poisoned RAG documents
-   malicious tool responses
-   secret exposure
-   cross-boundary data exfiltration

------------------------------------------------------------------------

# 16. Enterprise RAG Security

Your lab is a strong interview story.

``` text
Document
   |
Cloud Storage
   |
Validation gate
   +-- trusted -> ingestion
   +-- malicious -> quarantine
   |
Chunking
   |
Embeddings
   |
Private Vector Search
   |
Agent Engine
```

Controls to discuss:

-   UBLA
-   Public Access Prevention
-   IAM
-   DLP
-   prompt-injection validation
-   quarantine
-   private Vector Search through PSC
-   VPC-SC where supported/applicable
-   audit logs
-   least privilege

------------------------------------------------------------------------

# 17. Agent Engine Security

Know:

``` text
Client
   |
OAuth / IAM
   |
Agent Gateway
   |
Model Armor INPUT
   |
Agent Engine
   |
Gemini
   |
Vector Search / MCP tools
   |
Model Armor OUTPUT
```

Important concepts:

-   Agent Identity
-   Reasoning Engine query authorization
-   private downstream resources
-   Agent Gateway
-   Agent Registry
-   Model Armor
-   MCP
-   HITL
-   per-tool authorization
-   session/memory security
-   observability

------------------------------------------------------------------------

# 18. MCP Security

Explain MCP as:

> A standardized interface through which an agent discovers and invokes
> external tools.

Your lab:

``` text
Agent Engine
   |
Agent Gateway egress
   |
MCP Toolbox
   |
Cloud SQL
```

Security controls:

-   curated tools
-   Cloud Run IAM
-   internal ingress
-   OIDC
-   dedicated service accounts
-   least-privilege SQL grants
-   allowed hosts/origins
-   Agent Gateway egress policy
-   Model Armor
-   tool audit logging
-   HITL for write/destructive tools

------------------------------------------------------------------------

# 19. Agent Gateway vs AI Gateway

Interview-friendly distinction:

``` text
AI Gateway
   App -> Model

Agent Gateway
   Client -> Agent
   Agent -> Tool/API
```

Agent Gateway can govern agent communication, while AI Gateway focuses
on centralized model/API consumption.

------------------------------------------------------------------------

# 20. Agent Registry

Know the distinction:

``` text
Agent Engine
  = runtime

Agent Registry
  = catalog/discovery/governance metadata for agents,
    MCP servers, tools and skills

Agent Gateway
  = governed communication path
```

For Agent-to-Anywhere governance, register the relevant agent/MCP
destinations and apply destination/tool policy.

------------------------------------------------------------------------

# 21. Model Armor

Use it around AI trust boundaries:

``` text
Prompt
  -> Model Armor
  -> Agent/model

Agent response
  -> Model Armor
  -> Client

Agent tools/call
  -> Model Armor
  -> MCP

MCP response
  -> Model Armor
  -> Agent
```

Discuss:

-   prompt injection
-   jailbreaks
-   sensitive-data leakage
-   unsafe content
-   malicious URLs
-   indirect prompt injection

------------------------------------------------------------------------

# 22. Human-in-the-Loop

Sensitive actions should not execute solely because the model selected a
tool.

``` text
User
  |
Agent chooses cancel_shipment
  |
Authorization
  |
HITL approval
  |
MCP tool
  |
Database
```

Key interview distinction:

``` text
Authentication = Who are you?
Authorization  = Are you allowed?
HITL           = Do you approve this action now?
```

------------------------------------------------------------------------

# 23. Compliance

Know how technical controls map to frameworks rather than memorizing
every clause.

Frameworks mentioned for the role include:

-   ISO 27001
-   NIST
-   CIS
-   HIPAA
-   PCI-DSS

Example:

``` text
Requirement: least privilege
Controls:
IAM roles + IAM Conditions + service accounts + DB GRANTs

Requirement: auditability
Controls:
Cloud Audit Logs + SCC + centralized log sinks

Requirement: encryption
Controls:
TLS + encryption at rest + CMEK/KMS where required
```

------------------------------------------------------------------------

# 24. Incident Response Scenario

Question:

> SCC detects suspicious activity from a workload identity. What do you
> do?

Structured answer:

``` text
1. Validate finding
2. Identify affected resource/principal
3. Correlate Audit Logs
4. Determine blast radius
5. Contain identity/network path
6. Revoke/adjust IAM
7. Rotate exposed secrets if applicable
8. Remediate root cause
9. Validate recovery
10. Document and improve preventive controls
```

------------------------------------------------------------------------

# 25. Architecture Question Framework

For almost any design question, answer in layers:

``` text
Identity
Network
Data
Application/workload
CI/CD
Detection
Governance
Recovery
```

Example secure AI application:

``` text
User
 |
IAM/OAuth
 |
Agent Gateway
 |
Model Armor
 |
Agent Engine
 | \
 |  \-> Private Vector Search
 |
Agent Gateway egress
 |
MCP
 |
Cloud SQL

Across the architecture:
IAM + VPC-SC + KMS + Audit Logs + SCC + CI/CD controls
```

------------------------------------------------------------------------

# 26. High-Priority Practical Topics

Prioritize these before the interview:

1.  IAM + service accounts + WIF
2.  VPC, firewall, routes, DNS, NAT
3.  PSC / PSA / Private Google Access
4.  VPC-SC ingress/egress + dry run
5.  GKE security
6.  Terraform failure/upgrade/state scenarios
7.  DevSecOps pipeline
8.  SCC + Audit Logs
9.  Cloud Armor
10. Cloud SQL security
11. Agent Engine + MCP
12. Agent Gateway + Agent Registry
13. Model Armor
14. HITL + tool authorization
15. threat modeling
16. compliance mapping

------------------------------------------------------------------------

# 27. 60-Second Project Story

> I built a secure GCP RAG/agent architecture where documents are
> ingested through a validation gate into a protected vector-search
> layer. The Agent Engine uses Gemini and accesses private Vector Search
> through PSC. For structured operational data, I deployed MCP Toolbox
> on Cloud Run and exposed only curated PostgreSQL tools such as
> shipment lookup and history. The MCP service requires IAM
> authentication and uses dedicated workload identities and
> least-privilege database access. I then introduced Agent Gateway
> concepts for governed client-to-agent and agent-to-tool traffic, Agent
> Registry for approved agent/MCP resources, Model Armor for
> prompt/response/tool-content inspection, and HITL for future
> destructive operations. Around that, I apply VPC-SC, IAM, Cloud Armor,
> SCC, Audit Logs, Secret Manager and Terraform/DevSecOps controls as
> defense in depth.

------------------------------------------------------------------------

# 28. Final Interview Checklist

Before the interview, make sure you can draw and explain without notes:

``` text
1. Shared VPC enterprise architecture
2. Private GKE architecture
3. Cloud Run private backend
4. Cloud SQL private architecture
5. PSC flow
6. VPC-SC perimeter
7. GitHub OIDC -> WIF -> SA
8. Terraform CI/CD pipeline
9. SCC monitoring flow
10. Secure RAG ingestion
11. Secure RAG inference
12. Agent -> MCP authentication
13. Agent Gateway ingress/egress
14. Model Armor
15. HITL + per-tool authorization
```

If you can explain the **identity, network path, authorization boundary,
threat, preventive control, logging and validation** for each of these,
you are covering the core of the Senior Consultant GCP
infrastructure/security/DevSecOps/AI-security role.
