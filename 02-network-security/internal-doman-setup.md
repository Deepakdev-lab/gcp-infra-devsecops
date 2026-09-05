# Private Cloud Run with Internal Application Load Balancer

## Overview

This project demonstrates how to expose a **Google Cloud Run service privately inside a VPC** using a **Regional Internal Application Load Balancer (Internal ALB)**.

The Cloud Run service is **not directly attached to the load balancer**.

Instead, Google Cloud uses a **Serverless Network Endpoint Group (Serverless NEG)** as the integration layer between the Internal Application Load Balancer and Cloud Run.

### Architecture

```text
                         PRIVATE VPC
┌───────────────────────────────────────────────────────────────┐
│                                                               │
│   Client / VM                                                 │
│   vpc-test-vm                                                 │
│        │                                                      │
│        │ HTTP                                                 │
│        ▼                                                      │
│   Private Cloud DNS                                           │
│   gcp-app-ui.internal.company.com                             │
│        │                                                      │
│        │ resolves to 10.150.0.3                               │
│        ▼                                                      │
│   Internal Application Load Balancer                           │
│   gcp-ui-ilb                                                  │
│   10.150.0.3:80                                               │
│        │                                                      │
│        ▼                                                      │
│   Target HTTP Proxy                                            │
│   gcp-ui-http-proxy                                           │
│        │                                                      │
│        ▼                                                      │
│   URL Map                                                     │
│   gcp-ui-url-map                                               │
│        │                                                      │
│        ▼                                                      │
│   Backend Service                                               │
│   gcp-ui-backend                                               │
│        │                                                      │
│        ▼                                                      │
│   Serverless NEG                                               │
│   gcp-ui-neg                                                    │
│        │                                                      │
│        ▼                                                      │
│   Cloud Run                                                    │
│   gcp-app-ui                                                   │
│   ingress = internal                                           │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

Google documents this architecture using a **serverless NEG backend** for the regional Internal Application Load Balancer.

---

# 1. Environment

## Project

```bash
PROJECT_ID="project-a95e6dc6-f7fc-4043-bf9"
```

## Region

```bash
REGION="us-east4"
```

## VPC

```text
default
```

## Subnet

```text
default
10.150.0.0/20
```

## Cloud Run service

```text
gcp-app-ui
```

---

# 2. Why do we need a Serverless NEG?

A Cloud Run service does not expose a VM-style IP address and port that an Internal Load Balancer can directly use as a traditional backend.

Therefore:

```text
Internal ALB
      |
      X
      |
Cloud Run
```

is not the model we use.

Instead:

```text
Internal ALB
      |
Backend Service
      |
Serverless NEG
      |
Cloud Run
```

The Serverless NEG acts as the integration mechanism between the load balancer and the Cloud Run service.

Google describes Serverless NEGs as the mechanism that allows load balancers to route requests to Cloud Run services.

---

# 3. Cloud Run configuration

The Cloud Run service is configured with internal ingress:

```bash
gcloud run services update gcp-app-ui \
  --project="$PROJECT_ID" \
  --region="$REGION" \
  --ingress=internal
```

Verify:

```bash
gcloud run services describe gcp-app-ui \
  --project="$PROJECT_ID" \
  --region="$REGION" \
  --format="yaml(metadata.annotations,spec.ingress)"
```

Expected:

```yaml
run.googleapis.com/ingress: internal
```

### Why `ingress=internal`?

This prevents the Cloud Run service from being directly accessible from the public internet.

Traffic coming through the Regional Internal Application Load Balancer is considered internal traffic.

---

# 4. Create Serverless NEG

Create the Serverless NEG:

```bash
gcloud compute network-endpoint-groups create gcp-ui-neg \
  --project="$PROJECT_ID" \
  --region="$REGION" \
  --network-endpoint-type=serverless \
  --cloud-run-service=gcp-app-ui
```

Verify:

```bash
gcloud compute network-endpoint-groups describe gcp-ui-neg \
  --project="$PROJECT_ID" \
  --region="$REGION"
```

Expected:

```yaml
networkEndpointType: SERVERLESS
cloudRun:
  service: gcp-app-ui
```

You may also see:

```yaml
size: 0
```

This is normal.

A Serverless NEG does not contain VM IP addresses like a VM-based NEG.

---

# 5. Create Regional Backend Service

Create the backend service:

```bash
gcloud compute backend-services create gcp-ui-backend \
  --project="$PROJECT_ID" \
  --region="$REGION" \
  --load-balancing-scheme=INTERNAL_MANAGED \
  --protocol=HTTP
```

The backend service provides the logical backend configuration for the load balancer.

---

# 6. Attach Serverless NEG to Backend Service

This is the important connection:

```text
Backend Service
      |
      ▼
gcp-ui-neg
      |
      ▼
gcp-app-ui
```

Command:

```bash
gcloud compute backend-services add-backend gcp-ui-backend \
  --project="$PROJECT_ID" \
  --region="$REGION" \
  --network-endpoint-group=gcp-ui-neg \
  --network-endpoint-group-region="$REGION"
```

Verify:

```bash
gcloud compute backend-services describe gcp-ui-backend \
  --project="$PROJECT_ID" \
  --region="$REGION"
```

You should see:

```yaml
backends:
- group: .../networkEndpointGroups/gcp-ui-neg
```

---

# 7. Create URL Map

The URL map determines where incoming requests should go.

```bash
gcloud compute url-maps create gcp-ui-url-map \
  --project="$PROJECT_ID" \
  --region="$REGION" \
  --default-service=gcp-ui-backend
```

Current routing:

```text
Any request
     |
     ▼
gcp-ui-url-map
     |
     ▼
gcp-ui-backend
```

Later, host/path-based routing can be added.

For example:

```text
gcp-app-ui.internal.company.com
             |
             ▼
       gcp-ui-backend


gcp-app-backend.internal.company.com
             |
             ▼
       gcp-backend-backend
```

---

# 8. Create Target HTTP Proxy

Create the regional HTTP proxy:

```bash
gcloud compute target-http-proxies create gcp-ui-http-proxy \
  --project="$PROJECT_ID" \
  --region="$REGION" \
  --url-map=gcp-ui-url-map
```

The target proxy connects the frontend listener to the URL map.

Architecture:

```text
Forwarding Rule
      |
      ▼
Target HTTP Proxy
      |
      ▼
URL Map
```

---

# 9. Create Proxy-Only Subnet

Regional proxy-based Internal Application Load Balancers require a dedicated proxy-only subnet.

```bash
gcloud compute networks subnets create proxy-only-us-east4 \
  --project="$PROJECT_ID" \
  --region="$REGION" \
  --network=default \
  --range=192.168.0.0/23 \
  --purpose=REGIONAL_MANAGED_PROXY \
  --role=ACTIVE
```

Verify:

```bash
gcloud compute networks subnets describe proxy-only-us-east4 \
  --project="$PROJECT_ID" \
  --region="$REGION"
```

Important:

```text
default subnet
10.150.0.0/20
```

is where normal VPC resources such as the test VM live.

Whereas:

```text
proxy-only subnet
192.168.0.0/23
```

is reserved for Google-managed load-balancer proxy infrastructure.

---

# 10. Reserve Internal IP

Reserve the private frontend IP:

```bash
gcloud compute addresses create gcp-ui-ilb-ip \
  --project="$PROJECT_ID" \
  --region="$REGION" \
  --subnet=default \
  --addresses=10.150.0.3
```

Verify:

```bash
gcloud compute addresses describe gcp-ui-ilb-ip \
  --project="$PROJECT_ID" \
  --region="$REGION"
```

Expected:

```text
10.150.0.3
```

This becomes the private IP address of the Internal Load Balancer.

---

# 11. Create Internal Forwarding Rule

Create the frontend listener:

```bash
gcloud compute forwarding-rules create gcp-ui-ilb \
  --project="$PROJECT_ID" \
  --region="$REGION" \
  --load-balancing-scheme=INTERNAL_MANAGED \
  --network=default \
  --subnet=default \
  --address=gcp-ui-ilb-ip \
  --ports=80 \
  --target-http-proxy=gcp-ui-http-proxy
```

Verify:

```bash
gcloud compute forwarding-rules describe gcp-ui-ilb \
  --project="$PROJECT_ID" \
  --region="$REGION"
```

Expected:

```text
IPAddress: 10.150.0.3
portRange: 80-80
loadBalancingScheme: INTERNAL_MANAGED
```

---

# 12. Private Cloud DNS

Create a private DNS zone:

```bash
gcloud dns managed-zones create internal-company \
  --project="$PROJECT_ID" \
  --dns-name="internal.company.com." \
  --visibility=private \
  --networks=default \
  --description="Private DNS zone for internal applications"
```

Create the A record:

```bash
gcloud dns record-sets create \
  gcp-app-ui.internal.company.com. \
  --project="$PROJECT_ID" \
  --zone=internal-company \
  --type=A \
  --ttl=300 \
  --rrdatas=10.150.0.3
```

Now:

```text
gcp-app-ui.internal.company.com
              |
              DNS
              |
              ▼
          10.150.0.3
              |
              ▼
       Internal ALB
```

---

# 13. Test From Private VM

SSH into the VM:

```bash
gcloud compute ssh vpc-test-vm \
  --project="$PROJECT_ID" \
  --zone=us-east4-a
```

Check DNS:

```bash
nslookup gcp-app-ui.internal.company.com
```

Expected:

```text
Name:
gcp-app-ui.internal.company.com

Address:
10.150.0.3
```

Test the application:

```bash
curl -v http://gcp-app-ui.internal.company.com
```

Expected:

```text
HTTP/1.1 200 OK
```

---

# 14. Request Flow

The complete request flow is:

```text
1. Client
   |
   | http://gcp-app-ui.internal.company.com
   |
   ▼

2. Private Cloud DNS
   |
   | DNS lookup
   |
   | 10.150.0.3
   |
   ▼

3. Internal Forwarding Rule
   |
   | 10.150.0.3:80
   |
   ▼

4. Target HTTP Proxy
   |
   ▼

5. URL Map
   |
   ▼

6. Backend Service
   |
   ▼

7. Serverless NEG
   |
   ▼

8. Cloud Run
   |
   | gcp-app-ui
   |
   ▼

9. Application Response
```

---

# 15. Important Concept: Ingress vs Egress

These two concepts should not be confused.

## Ingress

Controls:

> Who can send requests INTO Cloud Run?

We configured:

```bash
--ingress=internal
```

Therefore:

```text
Internet
   |
   X
Cloud Run
```

but:

```text
Internal ALB
      |
      ▼
Cloud Run
```

is allowed.

---

## Egress

Controls:

> Where can Cloud Run send traffic OUT to?

For example, Cloud Run may need to communicate with:

```text
Cloud Storage
Cloud SQL
Private APIs
Other VPC resources
```

That is a separate networking decision.

---

# 16. Why Cloud Run Doesn't Need a VPC IP

A common misconception is:

```text
Cloud Run
   |
   | needs private IP
   ▼
VPC
```

Cloud Run is serverless.

You don't assign it a VM-style private IP.

Instead:

```text
VPC
 |
 | Internal ALB
 |
 ▼
Serverless NEG
 |
 ▼
Cloud Run
```

The Serverless NEG provides the load-balancer integration.

---

# 17. Why `size: 0` on Serverless NEG is Normal

If you run:

```bash
gcloud compute network-endpoint-groups describe gcp-ui-neg \
  --region=us-east4
```

you may see:

```yaml
size: 0
```

Do not interpret this as:

```text
❌ No backend
```

For a serverless NEG, there aren't VM endpoints to enumerate.

The NEG references the Cloud Run service:

```yaml
cloudRun:
  service: gcp-app-ui
```

Therefore:

```text
Serverless NEG
      |
      └── Reference → Cloud Run service
```

---

# 18. Why We Need the Proxy-Only Subnet

The Internal Application Load Balancer uses managed proxy infrastructure.

Therefore Google requires a dedicated proxy-only subnet:

```text
proxy-only-us-east4
192.168.0.0/23
```

Conceptually:

```text
VPC
│
├── default subnet
│      └── VM
│
└── proxy-only subnet
       └── Google-managed LB proxies
```

The proxy-only subnet is not where Cloud Run runs.

---

# 19. Why We Don't Need a Firewall Rule for Cloud Run

For a load balancer using only serverless NEG backends, traffic from the load balancer to the serverless backend uses special routes outside the VPC and isn't controlled by normal VPC firewall rules.

Therefore you don't create a firewall rule such as:

```text
proxy subnet → Cloud Run
```

just to make the serverless NEG work.

---

# 20. Disable Cloud Run Default URL

Once the private load-balancer path is working, the Cloud Run default URL can be disabled:

```bash
gcloud run services update gcp-app-ui \
  --project="$PROJECT_ID" \
  --region="$REGION" \
  --no-default-url
```

This gives the architecture an even stronger private-ingress model:

```text
Private Client
      |
      ▼
Internal ALB
      |
      ▼
Serverless NEG
      |
      ▼
Cloud Run
```

instead of relying on:

```text
https://xxxxx-uc.a.run.app
```

---

# 21. Verification Commands

## Cloud Run

```bash
gcloud run services describe gcp-app-ui \
  --project="$PROJECT_ID" \
  --region="$REGION"
```

## Serverless NEG

```bash
gcloud compute network-endpoint-groups describe gcp-ui-neg \
  --project="$PROJECT_ID" \
  --region="$REGION"
```

## Backend Service

```bash
gcloud compute backend-services describe gcp-ui-backend \
  --project="$PROJECT_ID" \
  --region="$REGION"
```

## URL Map

```bash
gcloud compute url-maps describe gcp-ui-url-map \
  --project="$PROJECT_ID" \
  --region="$REGION"
```

## Target Proxy

```bash
gcloud compute target-http-proxies describe gcp-ui-http-proxy \
  --project="$PROJECT_ID" \
  --region="$REGION"
```

## Forwarding Rule

```bash
gcloud compute forwarding-rules describe gcp-ui-ilb \
  --project="$PROJECT_ID" \
  --region="$REGION"
```

## Proxy-only subnet

```bash
gcloud compute networks subnets describe proxy-only-us-east4 \
  --project="$PROJECT_ID" \
  --region="$REGION"
```

---

# 22. Troubleshooting

## 503 — `no healthy upstream`

If you receive:

```text
HTTP/1.1 503 Service Unavailable

no healthy upstream
```

First check the backend service:

```bash
gcloud compute backend-services describe gcp-ui-backend \
  --region=us-east4
```

Make sure the Serverless NEG is attached:

```yaml
backends:
- group: .../networkEndpointGroups/gcp-ui-neg
```

If `backends: null` appears, attach the NEG:

```bash
gcloud compute backend-services add-backend gcp-ui-backend \
  --project="$PROJECT_ID" \
  --region="$REGION" \
  --network-endpoint-group=gcp-ui-neg \
  --network-endpoint-group-region="$REGION"
```

---

## DNS doesn't resolve

Check:

```bash
nslookup gcp-app-ui.internal.company.com
```

Verify that the DNS record points to:

```text
10.150.0.3
```

---

## Connection timeout

Check:

```bash
gcloud compute forwarding-rules describe gcp-ui-ilb \
  --region="$REGION"
```

Confirm:

```text
IPAddress: 10.150.0.3
Port: 80
```

Also verify that the client is connected to the correct VPC.

---

## Cloud Run returns 403/404

Check Cloud Run ingress:

```bash
gcloud run services describe gcp-app-ui \
  --region="$REGION" \
  --format="value(metadata.annotations.run\.googleapis\.com/ingress)"
```

Expected:

```text
internal
```

---

# 23. Resource Summary

| Resource          | Name                              | Purpose                         |
| ----------------- | --------------------------------- | ------------------------------- |
| VPC               | `default`                         | Private network                 |
| Subnet            | `default`                         | VM/private resources            |
| Proxy subnet      | `proxy-only-us-east4`             | Managed LB proxy infrastructure |
| Internal IP       | `gcp-ui-ilb-ip`                   | Stable private LB IP            |
| Cloud DNS zone    | `internal-company`                | Private DNS                     |
| DNS record        | `gcp-app-ui.internal.company.com` | Resolves hostname → ILB IP      |
| Serverless NEG    | `gcp-ui-neg`                      | Connects LB to Cloud Run        |
| Backend service   | `gcp-ui-backend`                  | LB backend configuration        |
| URL map           | `gcp-ui-url-map`                  | L7 routing                      |
| Target HTTP proxy | `gcp-ui-http-proxy`               | HTTP proxy                      |
| Forwarding rule   | `gcp-ui-ilb`                      | Private frontend                |
| Cloud Run         | `gcp-app-ui`                      | Application                     |

---

# 24. The Most Important Mental Model

Remember this:

```text
Cloud Run
   ↓
Serverless NEG
   ↓
Backend Service
   ↓
URL Map
   ↓
Target Proxy
   ↓
Forwarding Rule
   ↓
Internal IP
```

The direction of configuration is:

```text
Client
  ↓
Forwarding Rule
  ↓
Target Proxy
  ↓
URL Map
  ↓
Backend Service
  ↓
Serverless NEG
  ↓
Cloud Run
```

---

# 25. Interview Questions

### Q1. Can an Internal Load Balancer directly point to Cloud Run?

No.

For this architecture, use a **Serverless NEG** as the backend integration for Cloud Run.

---

### Q2. What is a Serverless NEG?

A Serverless NEG is a load-balancer backend abstraction that references a serverless service such as Cloud Run instead of VM IP/port endpoints.

---

### Q3. Does the Serverless NEG contain Cloud Run IP addresses?

No.

Cloud Run is serverless and doesn't expose VM-style backend IPs for this purpose.

---

### Q4. Why is the NEG size sometimes `0`?

Because it isn't maintaining VM-style endpoints.

The NEG references the Cloud Run service.

---

### Q5. Why do we need a backend service?

The backend service represents the logical backend configuration used by the load balancer.

It references the Serverless NEG.

---

### Q6. Why do we need a URL map?

The URL map provides Layer 7 routing.

For example:

```text
ui.internal.company.com
        ↓
UI backend

api.internal.company.com
        ↓
Backend service
```

---

### Q7. Why do we need a target HTTP proxy?

It terminates/processes the HTTP frontend traffic and uses the URL map to determine where the request should go.

---

### Q8. Why do we need the forwarding rule?

The forwarding rule defines the frontend:

```text
10.150.0.3:80
```

and sends traffic to the target proxy.

---

### Q9. Why use an Internal ALB instead of directly using the Cloud Run URL?

Because the requirement is:

```text
Private VPC access
```

rather than:

```text
Public run.app endpoint
```

The Internal ALB provides a private, policy-enforcing ingress point.

---

# 26. Final Architecture

```text
                    PRIVATE VPC
                         │
                         │
                  ┌──────▼──────┐
                  │ Private DNS │
                  │             │
                  │ internal.   │
                  │ company.com │
                  └──────┬──────┘
                         │
                         │
                    10.150.0.3
                         │
                  ┌──────▼──────┐
                  │  Internal   │
                  │     ALB     │
                  └──────┬──────┘
                         │
                  ┌──────▼──────┐
                  │ URL Map /   │
                  │ HTTP Proxy  │
                  └──────┬──────┘
                         │
                  ┌──────▼──────┐
                  │  Backend    │
                  │   Service   │
                  └──────┬──────┘
                         │
                  ┌──────▼──────┐
                  │ Serverless  │
                  │     NEG     │
                  └──────┬──────┘
                         │
                  ┌──────▼──────┐
                  │  Cloud Run  │
                  │ gcp-app-ui  │
                  │             │
                  │  INTERNAL   │
                  │   INGRESS   │
                  └─────────────┘
```

## Key takeaway

> **Internal Application Load Balancer does not directly attach to Cloud Run. The recommended integration is Internal ALB → Backend Service → Serverless NEG → Cloud Run.**

This is the core pattern to remember for GCP interviews.

Reference: Google Cloud's current regional internal ALB documentation explicitly uses a Serverless NEG for Cloud Run and provides the corresponding `gcloud` commands.
