# DKCloudOps --- Secure RAG Inference Architecture

## Overview

This document captures the secure RAG inference architecture implemented
in the DKCloudOps GCP lab.

The solution combines two retrieval paths behind one Vertex AI Agent
Engine:

1.  **Unstructured enterprise knowledge** through private Vertex AI
    Vector Search.
2.  **Structured operational data** through MCP Toolbox backed by Cloud
    SQL for PostgreSQL.

The design uses workload identity, IAM, Private Service Connect (PSC),
private database networking, Cloud SQL IAM database authentication, and
least-privilege database grants.

> **Status:** Private Vector Search inference is validated end-to-end.
> MCP Toolbox and Cloud SQL were independently validated; the final
> automatic `get_shipment` invocation from Agent Engine is the remaining
> end-to-end validation.

------------------------------------------------------------------------

## Architecture

``` text
                         Client
                           |
                   HTTPS + Google Auth/IAM
                           |
                           v
                Vertex AI Agent Engine
                  DKCloudOps RAG Agent
                           |
                     Agent Identity
                           |
              +------------+------------+
              |                         |
              v                         v
       Unstructured RAG          Structured Data
              |                         |
     search_private_vector       Curated ADK tools
              |                  get_shipment
              |                  get_shipment_history
              |                  get_customer_summary
              v                         |
      Gemini Embedding                  |
              |                         |
              v                         v
 Private Vertex Vector Search     Google ID token
              |                         |
             PSC                        v
         10.128.0.31             Internal Cloud Run
              |                   MCP Toolbox
              v                         |
       Protected Index             mcp-toolbox-sa
                                        |
                                Cloud SQL IAM DB Auth
                                        |
                                        v
                               Private Cloud SQL
                                  PostgreSQL
                                  dkcloudops
```

## 1. Vertex AI Agent Engine

The inference orchestrator is deployed as Vertex AI Agent Engine /
Reasoning Engine:

``` text
projects/565532451627/locations/us-central1/reasoningEngines/8727639077530107904
```

The agent uses Gemini 2.5 Flash for reasoning and tool selection.

Routing intent:

``` text
Policy / procedure / enterprise document
              -> Private Vector Search

Shipment / customer operational data
              -> MCP Toolbox -> Cloud SQL

Question requiring both
              -> Vector Search + MCP Toolbox
```

Examples:

``` text
"What is our shipment exception policy?"
    -> Vector Search

"What is the current status of shipment 12345?"
    -> MCP -> Cloud SQL

"Shipment 12345 is delayed. What should we do according to policy?"
    -> Cloud SQL + Vector Search
```

## 2. Private RAG Retrieval

``` text
User question
     |
Agent Engine
     |
search_private_vector()
     |
gemini-embedding-001
RETRIEVAL_QUERY / 768 dimensions
     |
Private Vector Search endpoint
     |
PSC
     |
10.128.0.31
     |
Deployed Vector Index
     |
Nearest matching chunks
     |
Gemini response
```

A remote Agent Runtime invocation successfully returned:

``` text
PRIVATE_VECTOR_SEARCH_SUCCESS
id=trusted_incoming_vector-test.json#chunk-0000
```

This validates Agent Runtime authentication, embedding generation, PSC
connectivity, private Vector Search and protected-index retrieval.

## 3. Vector Search Security

Vector Search is accessed through a private PSC endpoint rather than a
public retrieval endpoint.

``` text
Agent Runtime
     |
     | PSC
     v
10.128.0.31
     |
Private Vector Search
```

This provides private downstream data-plane connectivity for RAG
retrieval.

## 4. Structured Retrieval with MCP

Transactional data is deliberately separated from the vector knowledge
base.

The operational database is exposed only through curated business
operations:

``` text
get_shipment
get_shipment_history
get_customer_summary
```

The agent is **not** given arbitrary SQL execution capability.

``` text
Avoid:

LLM -> execute arbitrary SQL -> Database

Implemented:

LLM -> get_shipment("12345")
    -> predefined MCP Toolbox query
    -> Cloud SQL
```

This reduces the blast radius of prompt injection and limits database
access to approved operations.

## 5. MCP Toolbox

MCP Toolbox for Databases runs on Cloud Run as:

``` text
dkcloudops-mcp-toolbox
Region: us-east4
```

Its configuration is stored in Secret Manager and mounted into the
container as:

``` text
/app/tools.yaml
```

Validated Toolbox startup:

``` text
Initialized 1 sources: dkcloudops-postgres
Initialized 3 tools:
  get_shipment_history
  get_customer_summary
  get_shipment
Server ready to serve!
```

The MCP endpoint was independently validated with a `tools/call`
request. A validated shipment result included:

``` json
{
  "shipment_id": "12345",
  "customer_id": "CUST1001",
  "origin": "Toronto",
  "destination": "Chicago",
  "status": "IN_TRANSIT"
}
```

## 6. Agent -\> MCP Authentication

The MCP Cloud Run service does not allow anonymous invocation.

``` text
Vertex AI Agent Identity
        |
        | IAM Credentials API
        | controlled SA impersonation
        v
agent-mcp-invoker-sa
        |
        | Google-signed ID token
        | audience = MCP Cloud Run service
        v
Cloud Run IAM
        |
        | roles/run.invoker
        v
MCP Toolbox
```

Dedicated invoker identity:

``` text
agent-mcp-invoker-sa@
project-a95e6dc6-f7fc-4043-bf9.iam.gserviceaccount.com
```

This keeps Agent Identity, Cloud Run invocation identity, and database
runtime identity separate.

## 7. MCP Cloud Run Security

MCP Toolbox uses:

``` text
Ingress: internal
Unauthenticated access: disabled
Authentication: Google IAM
```

A caller therefore needs both network reachability and IAM
authorization.

During testing, a VM caller initially received `403 Forbidden` until its
service account was granted `roles/run.invoker`, validating the Cloud
Run authorization boundary.

## 8. MCP -\> Cloud SQL Authentication

MCP Toolbox executes using:

``` text
mcp-toolbox-sa@
project-a95e6dc6-f7fc-4043-bf9.iam.gserviceaccount.com
```

Cloud SQL has IAM database authentication enabled:

``` text
cloudsql.iam_authentication = on
```

The Toolbox service account is registered as a Cloud SQL IAM database
user.

``` text
MCP Toolbox
     |
mcp-toolbox-sa
     |
Cloud SQL IAM authentication
     |
PostgreSQL
```

No static PostgreSQL password needs to be embedded in the agent.

## 9. Cloud SQL Network Security

Cloud SQL PostgreSQL has no public IPv4 address.

``` text
Instance: gcp-infra-psql
Database: dkcloudops
Private address: 10.81.132.3
PSC auto connection observed: 10.20.134.2
```

Database traffic therefore uses private connectivity rather than direct
public Internet exposure.

## 10. Database Authorization

Authentication answers **who is connecting**; PostgreSQL grants
determine **what that identity may do**.

Conceptually:

``` text
mcp-toolbox-sa
      |
      +-- CONNECT dkcloudops
      +-- USAGE on required schema
      +-- SELECT on shipments
      +-- SELECT on shipment_history
      +-- SELECT on required customer data
```

The MCP identity does not require unrestricted database-owner
privileges.

## 11. Security and Authentication Layers

  Layer                     Control
  ------------------------- -------------------------------------------------
  Client -\> Agent          Google authentication + IAM
  Agent runtime             Agent Identity
  Agent -\> embedding API   Google workload credentials
  Agent -\> Vector Search   PSC/private endpoint
  Vector data               Private Vertex AI Vector Search
  Agent -\> MCP             Google-signed Cloud Run ID token
  MCP authorization         Cloud Run IAM / `roles/run.invoker`
  MCP network               Internal Cloud Run ingress
  Toolbox configuration     Secret Manager-mounted `tools.yaml`
  MCP -\> DB                Dedicated `mcp-toolbox-sa`
  DB authentication         Cloud SQL IAM DB authentication
  DB network                Private IP/PSC; no public IPv4
  DB authorization          PostgreSQL least-privilege grants
  Agent capability          Curated business tools instead of arbitrary SQL

## 12. Identity Separation

``` text
                 Agent Identity
                       |
                 Token Creator
                       |
                       v
              agent-mcp-invoker-sa
                       |
                   run.invoker
                       |
                       v
                 MCP Cloud Run
                       |
                  executes as
                       |
                       v
                 mcp-toolbox-sa
                       |
              Cloud SQL IAM DB Auth
                       |
                       v
                    PostgreSQL
```

This reduces blast radius by avoiding one identity with access to every
layer.

## 13. MCP Integration

MCP Toolbox 1.10.0 was validated using the MCP `2026-07-28` request
format, including:

``` text
MCP-Protocol-Version: 2026-07-28
Mcp-Method: tools/call
Mcp-Name: <tool>
```

During implementation, the ADK `McpToolset` session initialization did
not interoperate with the Toolbox endpoint behavior used in this lab.

The integration was therefore changed to controlled ADK business
functions that send the already validated MCP request format to Toolbox:

``` text
Agent
  |
ADK business function
  |
MCP protocol request
  |
MCP Toolbox
  |
Cloud SQL
```

MCP Toolbox remains the database tool server and policy boundary.

## 14. Troubleshooting Validated

Real failure paths investigated during the lab included:

-   Cloud Run `403 Forbidden` caused by missing `roles/run.invoker`.
-   MCP request validation errors for missing/mismatched method, tool
    name, protocol metadata and client information.
-   ADK MCP session initialization returning `404` /
    `Session terminated`.
-   Vector Search private connectivity and PSC endpoint addressing.
-   Agent Runtime dependency/version mismatches.
-   Cloud SQL IAM database authentication and private connectivity.

These failures helped validate where authentication, authorization,
protocol and network boundaries are enforced.

## 15. Current End-to-End Model

``` text
                         CLIENT
                            |
                     Google Auth/IAM
                            |
                            v
                 VERTEX AI AGENT ENGINE
                 Gemini + Agent Identity
                            |
               +------------+-------------+
               |                          |
               v                          v
       PRIVATE RAG PATH            BUSINESS DATA PATH
               |                          |
       Gemini Embeddings            Curated ADK tools
               |                          |
               v                          v
        Private Vector              Google ID token
           Search                         |
               |                          v
              PSC                 Internal Cloud Run
               |                    MCP Toolbox
               |                          |
               |                   mcp-toolbox-sa
               |                          |
               |                   IAM DB Auth
               |                          |
               |                          v
               |                  Private Cloud SQL
               |                    PostgreSQL
               +------------+-------------+
                            |
                            v
                     Gemini response
```

## 16. Remaining Hardening

The core inference architecture can be further hardened with:

### MCP Toolbox allowed hosts/origins

Replace wildcard host/origin settings with explicit trusted values to
reduce DNS-rebinding and cross-origin exposure.

### Agent Gateway

Introduce Agent Gateway as a centralized policy point for
client-to-agent and, where appropriate, agent-to-tool traffic.

### Model Armor

Inspect inference input/output and potentially governed MCP tool traffic
for configured AI security risks such as prompt injection, unsafe
content and sensitive-data exposure.

### VPC Service Controls

Evaluate a VPC-SC perimeter in dry-run mode around supported sensitive
APIs, including as appropriate:

``` text
aiplatform.googleapis.com
storage.googleapis.com
run.googleapis.com
secretmanager.googleapis.com
sqladmin.googleapis.com
artifactregistry.googleapis.com
```

VPC-SC is an anti-exfiltration/service-perimeter control. It does not
replace PSC, IAM, Cloud Run ingress controls or database authorization.

## 17. Interview Summary

> I implemented a secure enterprise RAG inference architecture on GCP
> using Vertex AI Agent Engine. Unstructured enterprise knowledge is
> retrieved from a private Vertex AI Vector Search endpoint over Private
> Service Connect. Structured operational data is exposed through
> curated MCP Toolbox business tools running on an internal,
> IAM-protected Cloud Run service. The agent uses workload identity and
> a Google-signed ID token for service-to-service authentication. MCP
> Toolbox connects to a private Cloud SQL PostgreSQL instance using
> passwordless IAM database authentication and least-privilege
> PostgreSQL grants. The architecture separates agent identity, service
> invocation identity, database runtime identity, network controls and
> data authorization to reduce the blast radius of a compromised
> component.

## 18. Security Principles Demonstrated

-   Defense in depth
-   Workload identity
-   No static database credentials
-   Least privilege
-   Identity separation
-   Private service connectivity
-   Controlled tool exposure
-   Separation of structured and unstructured retrieval
-   Service-to-service authentication
-   Database-level authorization
-   Reduced prompt-injection blast radius
-   Auditable business operations
-   VPC-SC readiness
-   Agent Gateway and Model Armor hardening path
