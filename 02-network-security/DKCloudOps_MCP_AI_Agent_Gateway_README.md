# DKCloudOps — MCP, AI Gateway & Agent Gateway

## 1. MCP

Model Context Protocol (MCP) is a standard interface for agents to discover and invoke external tools.

In the DKCloudOps lab:

```text
Vertex AI Agent Engine
        |
        v
Curated ADK business tools
        |
        v
MCP Toolbox on internal Cloud Run
        |
        v
Cloud SQL PostgreSQL
```

Exposed tools:

- `get_shipment`
- `get_shipment_history`
- `get_customer_summary`

We deliberately avoid generic `execute_sql`, because curated tools are easier to authorize, audit, and constrain.

## 2. MCP Toolbox vs Custom MCP

**MCP Toolbox** is a prebuilt, database-focused MCP server. It is configured mainly through `tools.yaml` and works well for predefined SQL-backed business tools.

**Custom MCP** is a server you build yourself in Python/Node/etc. Use it when you need custom APIs, orchestration, validations, or business logic.

Both can run on Cloud Run; the difference is the runtime/software you deploy, not the hosting platform.

## 3. MCP Security Model

### Agent to MCP

```text
Agent Identity
   |
   | service-account impersonation
   v
agent-mcp-invoker-sa
   |
   | Google-signed OIDC ID token
   v
Cloud Run IAM
   |
   | roles/run.invoker
   v
MCP Toolbox
```

### MCP to Cloud SQL

```text
MCP Toolbox
   |
   | runs as mcp-toolbox-sa
   v
Cloud SQL IAM DB Authentication
   |
   v
PostgreSQL
   |
   | least-privilege GRANTs
   v
dkcloudops tables
```

No static database password is required.

## 4. MCP Cloud Run Hardening

Current important controls:

- `ingress=internal`
- unauthenticated invocation disabled
- Cloud Run IAM required
- dedicated runtime service account
- Secret Manager-mounted `tools.yaml`
- private Cloud SQL connectivity
- curated read-only tools

Additional hardening:

- restrict `allowed-hosts`
- restrict `allowed-origins`
- keep tool definitions narrow
- log tool name, caller, latency, status
- route agent-to-MCP through Agent Gateway egress
- inspect `tools/call` request/response with Model Armor

## 5. AI Gateway

Simple mental model:

> **AI Gateway = Application -> Model**

Typical flow:

```text
Application
   |
   v
AI Gateway
   |
   +-- authentication
   +-- quotas / rate limiting
   +-- routing
   +-- policy
   +-- observability
   |
   v
Gemini / model endpoint
```

It is mainly useful when an application directly calls LLM/model APIs and you want centralized model access governance.

Our agent does use `gemini-2.5-flash`, but because Gemini is called from inside Agent Engine, AI Gateway is not automatically required for this architecture.

## 6. Agent Gateway

Simple mental model:

> **Agent Gateway = Client -> Agent and Agent -> Tools**

There are two important governed paths.

### Client-to-Agent

```text
Client
   |
   | OAuth + Vertex AI IAM
   v
Agent Engine API
   |
   v
Agent Gateway (CLIENT_TO_AGENT)
   |
   +-- security policy
   +-- Model Armor input/output
   |
   v
Agent Runtime
```

The client still targets the Reasoning Engine API. Once `clientToAgentConfig` is attached to the Reasoning Engine, inbound traffic is routed through the configured gateway.

### Agent-to-Anywhere

```text
Agent Engine
   |
   | Agent Identity
   v
Agent Gateway (AGENT_TO_ANYWHERE)
   |
   +-- destination policy
   +-- IAP/IAM authorization
   +-- Model Armor on tool traffic
   |
   v
MCP / API / external tool
```

## 7. Agent Registry

Agent Registry is separate from Agent Gateway.

```text
Agent Runtime
  = runs the agent

Agent Registry
  = catalogs agents, MCP servers, tools and skills

Agent Gateway
  = governs communication paths
```

For Client-to-Agent ingress, Agent Registry is not required.

For Agent-to-Anywhere egress, it is useful for registering approved destinations such as:

```text
Agents
  - DKCloudOps RAG Agent

MCP Servers
  - dkcloudops-mcp-toolbox

Tools
  - get_shipment
  - get_shipment_history
  - get_customer_summary
```

## 8. Tool Authorization

The goal is to enforce policy outside the LLM prompt.

Example:

```text
DKCloudOps RAG Agent
   |
   +-- get_shipment            ALLOW
   +-- get_shipment_history    ALLOW
   +-- get_customer_summary    ALLOW
   +-- cancel_shipment         DENY
```

A future operations/admin agent can be granted a different set of tools.

## 9. Human-in-the-Loop

Read-only tools can normally run automatically.

Sensitive tools should require confirmation:

```text
cancel_shipment
refund_customer
delete_customer
update_delivery_address
```

ADK pattern:

```python
FunctionTool(
    cancel_shipment,
    require_confirmation=True,
)
```

Flow:

```text
User request
   |
Agent selects tool
   |
Confirmation event
   |
Client shows Approve / Reject
   |
Approved
   |
Tool executes
```

Authorization and confirmation are separate:

- Authorization: **Are you allowed?**
- Confirmation: **Do you approve this action now?**

## 10. Model Armor

### Input protection

```text
User Prompt
   |
   v
Agent Gateway
   |
   +-- Model Armor INPUT
   |
   v
Agent Engine
```

Potential protections include:

- prompt injection
- jailbreak
- sensitive data
- malicious URLs
- unsafe content

### Output protection

```text
Agent Response
   |
   v
Model Armor OUTPUT
   |
   v
Client
```

Useful for detecting:

- PII leakage
- secret exposure
- unsafe content
- policy violations

### MCP protection

```text
Agent
   |
Agent Gateway egress
   |
Model Armor
   |
MCP tools/call
   |
MCP Toolbox
   |
Tool response
   |
Model Armor
   |
Agent
```

This helps with indirect prompt injection coming from tool results.

## 11. Client Authentication to Agent Engine

The Agent Engine is not anonymously callable.

```text
Client
   |
   | OAuth 2.0 access token / ADC
   v
Vertex AI IAM
   |
   | aiplatform.reasoningEngines.query
   v
Reasoning Engine
```

Agent Gateway ingress does not replace this IAM boundary.

## 12. End-to-End Security Architecture

```text
Trusted Client
    |
    | OAuth / IAM
    v
Agent Gateway INGRESS
    |
    +-- Model Armor INPUT
    |
    v
Vertex AI Agent Engine
    |
    +-----------------------+
    |                       |
    v                       v
Private Vector Search   Agent Gateway EGRESS
via PSC                    |
                           +-- IAP/IAM
                           +-- tool policy
                           +-- Model Armor MCP
                           |
                           v
                     MCP Toolbox
                           |
                     Cloud SQL IAM
                           |
                           v
                     PostgreSQL
    |
    v
Model Armor OUTPUT
    |
    v
Client
```

## 13. Interview Summary

> MCP provides a standard tool interface. MCP Toolbox is a prebuilt database-oriented MCP server. AI Gateway governs application-to-model access, while Agent Gateway governs client-to-agent and agent-to-tool communication. Agent Registry catalogs approved agents, MCP servers and tools. Model Armor inspects AI input/output and selected MCP traffic. IAM controls identity and authorization, PSC/private networking controls data-plane reachability, and Cloud SQL IAM plus PostgreSQL grants enforce database access.
