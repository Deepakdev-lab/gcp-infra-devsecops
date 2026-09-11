# DKCloudOps --- Service Accounts, IAM Grants & Least-Privilege Design

> This README separates **grants confirmed during the lab** from
> **recommended least-privilege grants**. Where an exact grant was not
> captured in the lab output, it is marked as a target/recommendation
> rather than presented as already configured.

## 1. Identities in the Current Architecture

``` text
Developer / Test VM
        |
        | VM identity
        v
565532451627-compute@developer.gserviceaccount.com
        |
        | roles/run.invoker   [CONFIRMED]
        v
dkcloudops-mcp-toolbox (Cloud Run)

Vertex AI Agent Engine
        |
        | Agent Identity
        v
principal://agents.global.org-722355238062.system.id.goog/
resources/aiplatform/projects/565532451627/
locations/us-central1/reasoningEngines/8727639077530107904
        |
        | roles/run.invoker   [CONFIRMED]
        v
dkcloudops-mcp-toolbox

MCP Toolbox Runtime
        |
        | dedicated runtime identity
        v
Cloud SQL PostgreSQL
```

## 2. Confirmed Cloud Run Invoker Policy

The lab validated the following policy on `dkcloudops-mcp-toolbox`:

``` yaml
bindings:
- members:
  - principal://agents.global.org-722355238062.system.id.goog/resources/aiplatform/projects/565532451627/locations/us-central1/reasoningEngines/8727639077530107904
  - serviceAccount:565532451627-compute@developer.gserviceaccount.com
  role: roles/run.invoker
```

This means both the Agent Engine identity and the test VM's Compute
Engine service account can invoke the protected Cloud Run MCP service.

## 3. Test VM Service Account

### Current identity

``` text
565532451627-compute@developer.gserviceaccount.com
```

### Confirmed grant

``` text
roles/run.invoker
```

Scope this grant to:

``` text
Cloud Run service:
dkcloudops-mcp-toolbox
```

rather than granting it project-wide.

### Better production design

The default Compute Engine service account is convenient for a lab but
should normally be replaced by a dedicated VM identity:

``` text
dkcloudops-mcp-test-client@PROJECT_ID.iam.gserviceaccount.com
```

Give it only:

``` text
roles/run.invoker
```

on the specific MCP Cloud Run service.

Do not give the test VM Editor, Owner, broad Vertex AI Admin, or Cloud
SQL Admin merely to test MCP invocation.

## 4. Agent Engine Identity

The deployed Reasoning Engine has its own Agent Identity:

``` text
principal://agents.global.org-722355238062.system.id.goog/
resources/aiplatform/projects/565532451627/
locations/us-central1/reasoningEngines/8727639077530107904
```

### Confirmed grant

``` text
roles/run.invoker
```

on:

``` text
dkcloudops-mcp-toolbox
```

This allows the specific deployed agent to invoke the MCP Cloud Run
service.

### Least privilege

Prefer:

``` text
THIS reasoning engine
        |
roles/run.invoker
        |
THIS Cloud Run MCP service
```

instead of granting every agent or a project-wide service account access
to every Cloud Run service.

When Agent Gateway egress is enabled, add destination-level
authorization there as an additional control rather than replacing Cloud
Run IAM.

## 5. MCP Toolbox Runtime Service Account

Use a dedicated identity such as:

``` text
mcp-toolbox-sa@PROJECT_ID.iam.gserviceaccount.com
```

Its job is only to run Toolbox and access the database/configuration it
requires.

### Recommended grants

Depending on the exact connection/configuration:

``` text
roles/cloudsql.client
```

Allows connectivity to Cloud SQL through the supported Cloud SQL
authentication/connectivity path.

If Cloud SQL IAM database authentication is used, the runtime identity
may also require:

``` text
roles/cloudsql.instanceUser
```

Do not automatically grant `roles/cloudsql.admin`.

If `tools.yaml` is sourced from Secret Manager, grant only the secret it
needs:

``` text
roles/secretmanager.secretAccessor
```

Scope it to the specific `tools.yaml` secret rather than every secret in
the project.

### Database permissions are separate from IAM

Cloud IAM does not replace PostgreSQL authorization.

Example:

``` text
mcp-toolbox-sa
      |
      | Cloud SQL IAM authentication
      v
PostgreSQL database user
      |
      +-- SELECT on shipment tables
      +-- SELECT on customer summary view
      X-- DROP
      X-- CREATE
      X-- ALTER
      X-- unrestricted UPDATE
```

For the current read-only tools, a read-only database role is the
preferred design.

## 6. Agent-to-MCP Impersonation Identity

If the agent obtains an ID token by impersonating a dedicated service
account such as:

``` text
agent-mcp-invoker-sa@PROJECT_ID.iam.gserviceaccount.com
```

use a two-stage authorization model:

``` text
Agent Identity
      |
      | permission to impersonate/token-mint
      v
agent-mcp-invoker-sa
      |
      | roles/run.invoker
      v
MCP Cloud Run
```

The agent should receive only the narrow token-creation/impersonation
permission required for this identity. Avoid granting broad Service
Account Admin or project-level Owner/Editor.

The invoker service account itself needs only the destination invocation
permission, typically:

``` text
roles/run.invoker
```

on `dkcloudops-mcp-toolbox`.

## 7. Vector Search Permissions

The RAG agent performs:

``` text
Agent Engine
   |
   | embedding request
   v
Vertex AI
   |
   | PSC
   v
Private Vector Search Index Endpoint
```

Use the minimum Vertex AI permissions required to generate embeddings
and query the deployed index endpoint.

Avoid giving the runtime:

``` text
roles/aiplatform.admin
```

unless administration is actually required.

Separate deployment/admin identities from runtime/query identities:

``` text
CI/CD identity
  -> create/update Agent Engine and Vector Search resources

Agent runtime identity
  -> invoke model + query existing Vector Search endpoint
```

## 8. Cloud Storage Permissions

The deployment process used:

``` text
gs://fedex-ai-documents-123456/agent_engine/
```

for Agent Engine packages such as:

``` text
agent_engine.pkl
requirements.txt
dependencies.tar.gz
```

The deployment identity needs object permissions for the deployment
bucket.

Do not grant Storage Admin to the runtime simply because the deployment
pipeline needs to upload artifacts.

For RAG document ingestion, use a separate ingestion identity with
access only to the required trusted/quarantine buckets.

## 9. Secret Manager Least Privilege

For Toolbox configuration:

``` text
Secret:
tools.yaml
```

Recommended:

``` text
mcp-toolbox-sa
   |
roles/secretmanager.secretAccessor
   |
specific tools.yaml secret
```

Avoid:

``` text
all service accounts
   |
Secret Manager Admin
   |
all secrets
```

Secret Manager Admin is for administration; runtime workloads normally
need only secret access.

## 10. Cloud SQL Least Privilege

Separate the layers:

``` text
Google IAM
   |
   +-- Can connect/authenticate to Cloud SQL?
   |
PostgreSQL IAM/database user
   |
   +-- What SQL operations can this identity perform?
```

For the current MCP read tools:

``` sql
GRANT CONNECT ON DATABASE dkcloudops TO <mcp_db_role>;
GRANT USAGE ON SCHEMA public TO <mcp_db_role>;
GRANT SELECT ON required_table_or_view TO <mcp_db_role>;
```

Avoid making the MCP runtime:

``` text
postgres superuser
database owner
schema owner
```

unless genuinely required.

## 11. CI/CD Identity

Use a separate deployment identity for Terraform/GitHub Actions.

Preferred authentication:

``` text
GitHub Actions
      |
      | OIDC
      v
Workload Identity Federation
      |
      v
Deployment Service Account
```

Avoid storing long-lived service-account JSON keys in GitHub Secrets.

Its roles should be split according to what Terraform actually creates.
Where practical, create separate deployment identities for platform
infrastructure and application deployment.

## 12. Recommended Identity Matrix

  -----------------------------------------------------------------------
  Identity                Purpose                 Minimum target access
  ----------------------- ----------------------- -----------------------
  Test VM SA              MCP validation          `roles/run.invoker` on
                                                  MCP service

  Agent Identity          Agent runtime           Invoke only required
                                                  downstream services

  Agent MCP invoker SA    MCP authentication      `roles/run.invoker` on
                                                  MCP service

  MCP Toolbox SA          Toolbox runtime         Cloud SQL
                                                  connect/login +
                                                  specific Secret access

  PostgreSQL MCP role     SQL authorization       SELECT only on required
                                                  tables/views

  CI/CD SA                Deployment              Resource-specific
                                                  create/update
                                                  permissions

  Ingestion SA            RAG ingestion           Required GCS +
                                                  embedding/index update
                                                  permissions

  Human developer         Administration          Prefer groups +
                                                  temporary/elevated
                                                  access
  -----------------------------------------------------------------------

## 13. Roles to Avoid for Runtime Workloads

Avoid broad primitive/admin roles when a narrower role works:

``` text
roles/owner
roles/editor
roles/iam.serviceAccountAdmin
roles/aiplatform.admin
roles/cloudsql.admin
roles/storage.admin
roles/secretmanager.admin
```

Runtime identities should normally receive data-plane permissions, not
administrative control-plane permissions.

## 14. Enterprise Principle

``` text
Human
  -> authenticated identity

Client
  -> Agent Engine query permission

Agent
  -> only required model/vector/tool access

Agent -> MCP
  -> destination-specific invocation

MCP
  -> only required Secret + Cloud SQL connectivity

Database
  -> table/view-level permissions

CI/CD
  -> deployment permissions, separated from runtime
```

This creates multiple independent authorization boundaries.

## 15. Interview Answer

> I separate deployment identities from runtime identities. The Agent
> Engine uses its workload identity and is granted only invocation
> access to the MCP service. MCP Toolbox runs under a dedicated service
> account with only Secret Manager access to its configuration and the
> minimum Cloud SQL connectivity permissions. PostgreSQL permissions are
> separately restricted to the tables and operations exposed by the MCP
> tools. CI/CD authenticates through Workload Identity Federation rather
> than static keys. I scope grants to individual resources wherever
> possible and avoid Owner, Editor and broad admin roles for runtime
> workloads.
