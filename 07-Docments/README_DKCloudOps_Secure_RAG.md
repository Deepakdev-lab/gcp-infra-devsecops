# DKCloudOps — Secure Enterprise RAG on Google Cloud

## Overview

This project demonstrates a security-first Retrieval-Augmented Generation (RAG) architecture on Google Cloud.

It implements two distinct pipelines:

1. **RAG ingestion** — validate, inspect, classify, chunk, embed, and index trusted enterprise documents.
2. **RAG inference** — run an ADK agent on Vertex AI Agent Runtime, authenticate with Agent Identity, and retrieve data from a private Vertex AI Vector Search endpoint over Private Service Connect (PSC).

The design follows:

- Least-privilege IAM
- Private networking
- Zero-trust principles
- Model Armor
- Sensitive Data Protection (DLP)
- Private Service Connect
- Agent Identity
- Controlled tool execution
- Centralized logging and auditability

> Note: Some lab resources still use the original `fedex-*` resource names. The overall project / solution name is **DKCloudOps**.

---

# Architecture

## RAG Ingestion

```text
                         UNTRUSTED DOCUMENT
                                │
                                ▼
                         Cloud Storage
                           incoming/
                                │
                                ▼
                            Eventarc
                                │
                                ▼
                     Cloud Run Validator
                                │
              ┌─────────────────┼─────────────────┐
              │                 │                 │
              ▼                 ▼                 ▼
        Schema / JSON       Model Armor          DLP
         Validation        Prompt Injection   Sensitive Data
              │                 │                 │
              └─────────────────┼─────────────────┘
                                │
                         Security Decision
                         ┌──────┴───────┐
                         │              │
                       BLOCK          ALLOW
                         │              │
                         ▼              ▼
                    quarantine/      trusted/
                                         │
                                         ▼
                                      Eventarc
                                         │
                                         ▼
                                  RAG Index Worker
                                         │
                              ┌──────────┼──────────┐
                              │          │          │
                              ▼          ▼          ▼
                           Chunking   Embedding   Upsert
                                         │
                                         ▼
                                Vertex AI Vector Search
                                   Private Endpoint
                                         │
                                        PSC
```

## RAG Inference

```text
                              USER / CLIENT
                                    │
                                    ▼
                               Backend / UI
                                    │
                                    ▼
                             Agent entry layer
                                    │
                       Authentication / Authorization
                                    │
                                    ▼
                           Vertex AI Agent Runtime
                              Google ADK Agent
                                    │
                          ┌─────────┴─────────┐
                          │                   │
                          ▼                   ▼
                    Gemini 2.5 Flash    RAG Retrieval Tool
                                              │
                                              ▼
                                     Gemini Embedding 001
                                      RETRIEVAL_QUERY
                                              │
                                              ▼
                                      PSC Interface
                                              │
                                              ▼
                                   Network Attachment
                                  agent-runtime-psc-na
                                              │
                                              ▼
                                         default VPC
                                              │
                                              ▼
                                    Vector Search PSC IP
                                         10.128.0.31
                                              │
                                              ▼
                                  Private Vector Search
                                              │
                                              ▼
                                      Nearest Neighbors
                                              │
                                              ▼
                                          Agent Answer
```

---

# 1. Cloud Storage Trust Zones

The ingestion bucket is logically divided into security zones:

```text
incoming/
trusted/
quarantine/
```

| Prefix | Purpose |
|---|---|
| `incoming/` | Newly uploaded and untrusted documents |
| `trusted/` | Documents that passed validation and security inspection |
| `quarantine/` | Rejected or suspicious documents |

A document is **never indexed directly from `incoming/`**.

---

# 2. Eventarc-Driven Ingestion

Eventarc listens for:

```text
google.cloud.storage.object.v1.finalized
```

The first Eventarc trigger invokes the document validation service.

The second Eventarc trigger invokes the RAG indexing worker after a document reaches the trusted path.

The RAG worker independently enforces:

```text
if object_name does not start with trusted/:
    ignore
```

This creates an additional trust boundary.

---

# 3. Cloud Run Document Validator

The validation service performs:

```text
CloudEvent validation
        │
        ▼
Bucket / object validation
        │
        ▼
JSON / schema validation
        │
        ▼
Business validation
        │
        ▼
Model Armor
        │
        ▼
Prompt-injection inspection
        │
        ▼
Sensitive Data Protection (DLP)
        │
        ▼
ALLOW / BLOCK
```

Rejected documents are moved to:

```text
quarantine/
```

Validated documents are promoted to:

```text
trusted/
```

---

# 4. Model Armor

Model Armor is part of the ingestion security layer.

Example template used in the lab:

```text
rag-ingestion-security
```

It is used to detect or enforce policy against threats such as:

- Prompt injection
- Jailbreak content
- Unsafe content
- Malicious URLs
- Sensitive-data exposure

Conceptually:

```text
Document
   │
   ▼
Model Armor
   │
   ├── SAFE  → continue
   └── BLOCK → quarantine
```

Model Armor is intentionally combined with DLP and application-level validation rather than treated as the only security control.

---

# 5. Sensitive Data Protection (DLP)

DLP is used as a separate inspection layer.

```text
Document
   │
   ├── Model Armor
   │
   └── DLP
          │
          ▼
     Security Decision
```

This creates defense in depth for sensitive enterprise data.

---

# 6. Trusted RAG Index Worker

Cloud Run service:

```text
rag-index-worker
```

Dedicated runtime identity:

```text
rag-index-worker-sa@
project-a95e6dc6-f7fc-4043-bf9.iam.gserviceaccount.com
```

The worker processes only trusted objects.

Processing flow:

```text
Trusted JSON
    │
    ▼
Deterministic text conversion
    │
    ▼
Chunking
    │
    ▼
Gemini Embedding
    │
    ▼
Vector Search datapoints
    │
    ▼
Streaming upsert
```

---

# 7. Chunking

The lab currently uses deterministic word-based chunking.

Example:

```text
chunk_size = 500 words
```

Each chunk receives a deterministic datapoint ID.

Example:

```text
trusted_incoming_vector-test.json#chunk-0000
```

This makes the vector entry traceable back to:

- Source object
- Chunk number

---

# 8. Embeddings

Embedding model:

```text
gemini-embedding-001
```

Dimensions:

```text
768
```

For ingestion:

```text
task_type=RETRIEVAL_DOCUMENT
```

For inference:

```text
task_type=RETRIEVAL_QUERY
```

This ensures document embeddings and query embeddings are generated for their intended retrieval tasks.

---

# 9. Vertex AI Vector Search

Index ID:

```text
1129811969214251008
```

Private Index Endpoint ID:

```text
5247966800351592448
```

Deployed Index ID:

```text
fedex_rag_vector_endpoint__1789035974320
```

The index uses streaming updates.

The ingestion worker successfully upserted a datapoint:

```text
trusted_incoming_vector-test.json#chunk-0000
```

---

# 10. Private Service Connect for Vector Search

The Vector Search Index Endpoint is private.

Configuration:

```text
enablePrivateServiceConnect: true
```

PSC match address:

```text
10.128.0.31
```

Network:

```text
projects/project-a95e6dc6-f7fc-4043-bf9/global/networks/default
```

The agent does not need to use the public Vector Search endpoint for retrieval.

---

# 11. Vertex AI Agent Runtime

Framework:

```text
Google ADK
```

Model:

```text
gemini-2.5-flash
```

Agent Runtime / Reasoning Engine:

```text
projects/565532451627/
locations/us-central1/
reasoningEngines/8727639077530107904
```

Display name:

```text
FedEx RAG Agent - PSC
```

The Runtime was deployed using:

```text
identity_type = AGENT_IDENTITY
```

---

# 12. Agent Identity

The Runtime uses **Agent Identity** rather than storing a service-account key.

Effective identity format:

```text
agents.global.org-722355238062.system.id.goog/
resources/aiplatform/projects/565532451627/
locations/us-central1/
reasoningEngines/8727639077530107904
```

Project IAM includes the default Agent Platform access and additional least-privilege access needed by the agent.

For Vector AI resource access, the specific agent identity was granted:

```text
roles/aiplatform.user
```

rather than granting additional access to every agent in the project.

---

# 13. Agent Runtime PSC Interface

Agent Runtime executes in a Google-managed environment.

To reach private resources in the VPC, a PSC interface was configured.

Dedicated subnet:

```text
agent-runtime-psc-subnet
172.16.0.0/28
```

Network attachment:

```text
agent-runtime-psc-na
```

Region:

```text
us-central1
```

Attachment configuration:

```text
connectionPreference: ACCEPT_AUTOMATIC
```

Observed accepted PSC connections:

```text
172.16.0.2  ACCEPTED
172.16.0.3  ACCEPTED
```

The Agent Runtime deployment contains:

```text
pscInterfaceConfig:
  networkAttachment:
    projects/project-a95e6dc6-f7fc-4043-bf9/
    regions/us-central1/
    networkAttachments/agent-runtime-psc-na
```

---

# 14. Least-Privilege PSC IAM

Instead of granting broad:

```text
roles/compute.networkAdmin
```

a custom project role was created:

```text
agentRuntimePscAttachment
```

Permissions:

```text
compute.networkAttachments.get
compute.networkAttachments.update
compute.regionOperations.get
```

The role is granted to the Vertex AI / Agent Platform service agent:

```text
service-565532451627@
gcp-sa-aiplatform.iam.gserviceaccount.com
```

This keeps network permissions narrowly scoped.

---

# 15. Agent Packaging Security / Deployment

The agent is packaged using the Vertex AI Agent Engine SDK.

Because the ADK agent lives inside the local `agent/` Python package, it must be included as an extra package:

```python
extra_packages=["agent"]
```

Without this, the Runtime failed during deserialization with:

```text
ModuleNotFoundError: No module named 'agent'
```

The corrected deployment packages:

```text
agent_engine.pkl
requirements.txt
dependencies.tar.gz
```

---

# 16. Agent Authentication Diagnostic

Inside the Agent Runtime, Application Default Credentials were explicitly validated.

Observed:

```text
AUTH_DIAGNOSTIC
credential_type=Credentials
token_present=True
```

This confirmed that:

- Agent Runtime had credentials
- Agent Identity was active
- The problem was not missing ADC

---

# 17. Agent Identity Token-Binding Compatibility

During testing, the Agent Identity credential was rejected by a Vertex AI API call with:

```text
401 UNAUTHENTICATED
```

For the lab, the Runtime was temporarily configured with:

```text
GOOGLE_API_PREVENT_AGENT_TOKEN_SHARING_FOR_GCP_SERVICES=False
```

After this compatibility setting was applied, the authenticated Vertex AI Index Endpoint API test succeeded.

> **Security note:** this setting weakens token-sharing protections and should be treated as a compatibility workaround for the lab, not the desired final production state. Production deployments should keep stronger token-binding protections where supported.

---

# 18. Private RAG Retrieval Tool

The ADK agent exposes a controlled retrieval function:

```text
search_private_vector(query)
```

Its flow:

```text
User query
    │
    ▼
RETRIEVAL_QUERY embedding
    │
    ▼
768-dimensional vector
    │
    ▼
Private Matching Engine endpoint
    │
    ▼
PSC IP 10.128.0.31
    │
    ▼
Nearest-neighbor search
```

The private PSC IP is supplied explicitly to the Vector Search client:

```text
10.128.0.31
```

This avoids incorrect project-number/project-ID PSC network resolution encountered during testing.

---

# 19. Successful End-to-End Private Retrieval

Validated query:

```text
shipment 12345
```

Returned:

```text
PRIVATE_VECTOR_SEARCH_SUCCESS

id=trusted_incoming_vector-test.json#chunk-0000
distance=0.29104578495025635
```

This validates the complete inference path:

```text
Remote client
    │
    ▼
Agent Runtime
    │
    ▼
Gemini 2.5 Flash
    │
    ▼
ADK Tool Call
    │
    ▼
Agent Identity
    │
    ▼
Gemini Embedding 001
    │
    ▼
Agent Runtime PSC Interface
    │
    ▼
default VPC
    │
    ▼
Vector Search PSC 10.128.0.31
    │
    ▼
Private Vector Search
    │
    ▼
Nearest-neighbor result
    │
    ▼
Gemini response
```

---

# 20. Security and Authentication Layers

The architecture intentionally separates authentication, authorization, network security, data inspection, and AI security.

```text
Identity
   │
   ▼
IAM / Agent Identity
   │
   ▼
Network Controls / PSC
   │
   ▼
Data Validation
   │
   ▼
DLP
   │
   ▼
Model Armor
   │
   ▼
Private Vector Retrieval
   │
   ▼
Agent Tool Authorization
```

## IAM

Answers:

```text
WHO can access WHAT?
```

## PSC

Answers:

```text
HOW does the workload privately reach the service?
```

## VPC Service Controls

Target control for:

```text
WHERE can protected Google APIs / data be accessed from?
```

## DLP

Answers:

```text
WHAT sensitive information exists in the content?
```

## Model Armor

Answers:

```text
IS this AI input / output / content safe to process?
```

---

# 21. Service Identities

The architecture separates workload identities.

```text
Document Validator
    └── fedex-validator-sa

RAG Index Worker
    └── rag-index-worker-sa

Agent Runtime
    └── Agent Identity

Vertex AI control plane
    └── Agent Platform service agent
```

Static service-account JSON keys are not required for these workloads.

---

# 22. Cloud Logging

Important events are written to Cloud Logging.

Examples:

```text
Received object event
Ignoring object outside trusted/
Document chunks=N
Embedding generated
Vector Search datapoint prepared
VECTOR_SEARCH_UPSERT_SUCCESS

AUTH_DIAGNOSTIC
EMBEDDING_SUCCESS
VECTOR_SEARCH_QUERY_START
VECTOR_SEARCH_SUCCESS
```

This gives an audit trail across:

```text
Upload
→ validation
→ trust decision
→ ingestion
→ embedding
→ upsert
→ agent call
→ tool call
→ retrieval
```

---

# 23. Current Cloud SQL / MCP Direction

The next phase uses:

```text
MCP Toolbox for Databases
```

instead of exposing unrestricted SQL through a generic MCP tool.

Target design:

```text
Agent Runtime
      │
      ▼
MCP Toolbox
      │
      ├── get_shipment()
      ├── get_shipment_history()
      └── get_customer_summary()
              │
              ▼
       Cloud SQL PostgreSQL
```

Cloud SQL instance:

```text
gcp-infra-psql
```

PostgreSQL:

```text
POSTGRES_18
```

Private IP:

```text
10.81.132.3
```

Public IPv4:

```text
Disabled
```

PSC:

```text
Enabled
```

The planned application database name is:

```text
dkcloudops
```

---

# 24. Why MCP Business Tools Instead of Arbitrary SQL?

Avoid:

```text
execute_sql("SELECT/UPDATE/DELETE ...")
```

Prefer:

```text
get_shipment(shipment_id)
get_shipment_history(shipment_id)
get_customer_summary(customer_id)
```

Each tool can map to a predefined parameterized query.

Benefits:

- Least privilege
- Reduced SQL injection risk
- Predictable tool behavior
- Easier authorization
- Easier auditing
- Smaller AI attack surface
- Easier testing
- No arbitrary DDL / DML from the agent

---

# 25. Planned Secure Inference Architecture

The target production-style design is:

```text
User
 │
 ▼
UI
 │
 ▼
Backend
 │
 ▼
Agent Gateway
 ├── Authentication
 ├── Authorization
 ├── Semantic governance
 └── Model Armor INPUT
 │
 ▼
Agent Runtime
 │
 ├── Gemini
 │
 ├── Private Vector Search
 │      └── PSC
 │
 └── MCP
       ├── MCP Toolbox
       │       └── Cloud SQL PostgreSQL
       │
       └── Custom MCP
               └── External APIs
 │
 ▼
Agent Gateway
 └── Model Armor OUTPUT
 │
 ▼
Backend
 │
 ▼
UI
```

---

# 26. Threats Addressed

## Malicious document upload

```text
Upload
  ↓
Validator
  ↓
Model Armor + DLP
  ↓
Quarantine
```

## Prompt injection embedded in enterprise documents

```text
Document
  ↓
Model Armor
  ↓
BLOCK / quarantine
```

## Sensitive-data leakage

```text
Document
  ↓
DLP
  ↓
Policy decision
```

## Unauthorized Vector Search access

Protected with:

- Agent Identity
- IAM
- private endpoint
- PSC

## Public data-plane exposure

Reduced by:

- Private Vector Search
- private Cloud SQL
- PSC
- internal workloads where appropriate

## Excessive agent database permissions

Prevented by planned MCP business-specific tools instead of arbitrary SQL.

---

# 27. Validated Milestones

## Ingestion

- [x] Cloud Storage event ingestion
- [x] Eventarc trigger
- [x] Cloud Run validator
- [x] Schema / business validation
- [x] Model Armor
- [x] DLP
- [x] Trusted / quarantine flow
- [x] Trusted object filtering

## RAG indexing

- [x] Chunking
- [x] `gemini-embedding-001`
- [x] 768-dimensional embeddings
- [x] Streaming Vector Search upsert
- [x] Datapoint creation

## Private networking

- [x] Private Vector Search Index Endpoint
- [x] PSC automation
- [x] Vector Search private address `10.128.0.31`
- [x] Agent Runtime PSC subnet
- [x] Network Attachment
- [x] Accepted PSC interface connections

## Agent inference

- [x] Google ADK
- [x] Gemini 2.5 Flash
- [x] Agent Runtime
- [x] Agent Identity
- [x] Remote invocation
- [x] Remote custom tool execution
- [x] Agent credential validation
- [x] Authenticated Index Endpoint control-plane access
- [x] Private Vector Search data-plane retrieval
- [x] Real nearest-neighbor result

## Next

- [ ] Create `dkcloudops` PostgreSQL database
- [ ] Create shipment schema and sample data
- [ ] Read-only database identity
- [ ] MCP Toolbox
- [ ] Business-specific MCP tools
- [ ] Agent → MCP integration
- [ ] Agent Gateway
- [ ] Model Armor inference policies
- [ ] MCP authorization and audit controls

---

# 28. Interview Explanation

A concise way to explain the implementation:

> I built a security-first RAG architecture on Google Cloud with separate ingestion and inference trust boundaries. Documents first land in an untrusted Cloud Storage path and are processed through Eventarc and a Cloud Run validation service. Before data is indexed, it goes through schema validation, business rules, Model Armor, prompt-injection inspection, and DLP. Only trusted documents are chunked and embedded with Gemini Embedding and streamed into Vertex AI Vector Search.
>
> For inference, I deployed a Google ADK agent to Vertex AI Agent Runtime using Agent Identity. Because the Vector Search endpoint is private, the Agent Runtime uses a PSC interface through a dedicated Network Attachment to enter the VPC, then reaches the private Vector Search PSC endpoint. Query embeddings are generated with `RETRIEVAL_QUERY`, and the agent successfully performs nearest-neighbor retrieval over the private data plane. IAM, Agent Identity, PSC, Model Armor, DLP, and workload-specific identities provide independent security boundaries.
>
> The next layer uses MCP Toolbox with narrowly scoped business tools against private Cloud SQL PostgreSQL rather than exposing unrestricted SQL to the model.

---

# 29. Key Security Principle

The central design principle is:

```text
Never trust content.
Never expose a data plane publicly unless required.
Never give an agent more authority than the specific business tool needs.
```

The architecture therefore combines:

```text
IAM
+ Agent Identity
+ PSC
+ Model Armor
+ DLP
+ Application validation
+ Private Vector Search
+ Controlled MCP tools
+ Logging / auditing
```

rather than relying on a single security product.

---

## Status

```text
RAG Ingestion             ✅ Validated
Secure document gating    ✅ Validated
Embedding + indexing      ✅ Validated
Private Vector Search     ✅ Validated
Agent Runtime             ✅ Validated
Agent Identity            ✅ Validated
Agent Runtime PSC         ✅ Validated
Private RAG retrieval     ✅ Validated
MCP Toolbox               ⏳ Next
Cloud SQL business tools  ⏳ Next
Agent Gateway             ⏳ Planned
Inference Model Armor     ⏳ Planned
```
