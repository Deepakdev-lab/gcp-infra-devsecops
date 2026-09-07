# GCP Infrastructure & Security Hands-On Lab

## 1. Lab Objective

Build and understand a production-style secure GCP architecture through hands-on implementation.

Primary technologies:

* Google Cloud VPC
* Subnets
* Private Google Access (PGA)
* Private Service Access (PSA)
* Private Service Connect (PSC)
* Cloud SQL for PostgreSQL
* Compute Engine
* GKE Standard
* GKE VPC-native networking
* Workload Identity Federation for GKE
* IAM
* Cloud SQL IAM authentication
* Cloud SQL Auth Proxy
* Cloud Armor
* Apigee
* Cloud Load Balancing
* Cloud DNS

---

# 2. GCP Project

Project:

```text
project-a95e6dc6-f7fc-4043-bf9
```

Primary VPC:

```text
default
```

Primary region:

```text
us-east4
```

---

# 3. Network Architecture

Current lab:

```text
                         INTERNET
                             |
                             v
                    +------------------+
                    | Cloud Armor      |
                    +------------------+
                             |
                             v
                    +------------------+
                    | HTTPS LB /       |
                    | Gateway          |
                    +------------------+
                             |
                             v
                         GKE App
                             |
                    Kubernetes SA
                             |
                     Workload Identity
                             |
                             v
                     Google SA (GSA)
                             |
                  +----------+----------+
                  |                     |
                  v                     v
             Cloud SQL Proxy       Google APIs
                  |
             +----+----+
             |         |
            PSA       PSC
             |         |
             v         v
        Cloud SQL   PSC Endpoint
                       |
                       v
                  Service Attachment
                       |
                       v
                    Cloud SQL
```

---

# 4. VPC

VPC:

```text
default
```

The VPC provides the Layer-3 networking boundary for the workloads.

Resources currently associated with the VPC include:

* Compute Engine VM
* GKE
* Cloud SQL private connectivity
* PSC endpoint
* Cloud DNS private zones

---

# 5. Default Subnet

Region:

```text
us-east4
```

Primary range:

```text
10.150.0.0/20
```

VM and GKE node addresses come from this range.

Example:

```text
VM:
10.150.0.2

GKE node:
10.150.0.5
```

---

# 6. Private Google Access (PGA)

PGA was enabled on the subnet:

```text
default / us-east4
```

Command:

```bash
gcloud compute networks subnets update default \
  --region=us-east4 \
  --enable-private-ip-google-access
```

## What PGA does

PGA allows VMs without external IP addresses to access supported Google APIs and services using Google's infrastructure.

Conceptually:

```text
Private VM
   |
   | Google API traffic
   v
Google APIs
```

PGA is primarily about:

> Private access from resources with internal IP addresses to Google APIs/services.

Important:

```text
PGA != PSA
PGA != PSC
```

---

# 7. Private Service Access (PSA)

PSA was configured for the VPC.

Existing allocated ranges:

```text
google-managed-services-default-22
10.81.132.0/22

google-managed-services-default-28
10.75.227.112/28
```

PSA connection:

```text
servicenetworking-googleapis-com
```

Producer:

```text
Google Cloud Platform
```

VPC:

```text
default
```

---

# 8. Cloud SQL Using PSA

Cloud SQL instance:

```text
gcp-infra-psql
```

Region:

```text
us-east4
```

Private IP:

```text
10.81.132.3
```

PSA DNS:

```text
y5cq9h7379vd.3g03wvzwjqqnd.global.sql-psa.goog.
```

Connectivity:

```text
VM
 |
 | TCP 5432
 v
10.81.132.3
 |
 v
PSA
 |
 v
Cloud SQL
```

Test:

```bash
nc -vz 10.81.132.3 5432
```

This succeeded.

PostgreSQL connectivity also succeeded.

---

# 9. PSA Key Concept

PSA is essentially:

```text
Consumer VPC
      |
      | VPC peering / Service Networking
      v
Google-managed service network
      |
      v
Cloud SQL
```

The Cloud SQL private IP is allocated from the PSA range.

Example:

```text
Cloud SQL = 10.81.132.3
```

This IP is not an IP from the normal VM subnet.

---

# 10. Private Service Connect (PSC)

PSC was also configured for Cloud SQL.

PSC endpoint:

```text
10.20.134.2
```

VPC:

```text
default
```

PSC endpoint status:

```text
ACCEPTED / ACTIVE
```

PSC service attachment:

```text
projects/af4a4dbdd7d2cc64cp-tp/regions/us-east4/serviceAttachments/a-8b5fa6a7cfb9-psc-service-attachment-cf148ede779248fe
```

---

# 11. PSC Architecture

The traffic path is:

```text
GKE Pod / VM
       |
       v
10.20.134.2
       |
       v
PSC Forwarding Rule
       |
       v
PSC Service Attachment
       |
       v
Cloud SQL
```

PSC endpoint:

```text
10.20.134.2
```

---

# 12. PSC DNS

The PSC DNS hostname is:

```text
8b5fa6a7cfb9.3g03wvzwjqqnd.us-east4.sql-psc.goog
```

Important:

```text
.sql-psc.goog
```

is the PSC hostname.

Do not confuse it with:

```text
.sql.goog
```

The PSC hostname resolves to:

```text
10.20.134.2
```

Test:

```bash
getent hosts 8b5fa6a7cfb9.3g03wvzwjqqnd.us-east4.sql-psc.goog
```

Expected:

```text
10.20.134.2
```

---

# 13. PSA vs PSC

## PSA

```text
Workload
   |
   v
Cloud SQL private IP
10.81.132.3
   |
   v
Service Networking
   |
   v
Cloud SQL
```

## PSC

```text
Workload
   |
   v
PSC endpoint
10.20.134.2
   |
   v
PSC service attachment
   |
   v
Cloud SQL
```

Simple interview answer:

> PSA provides private service networking between a VPC and supported Google-managed services through Service Networking, while PSC exposes a specific service through a private endpoint in the consumer VPC.

---

# 14. VM Connectivity Testing

VM:

```text
vpc-test-vm
```

Internal IP:

```text
10.150.0.2
```

Gateway:

```text
10.150.0.1
```

PSA connectivity:

```bash
nc -vz 10.81.132.3 5432
```

Succeeded.

PSC connectivity:

```bash
nc -vz 10.20.134.2 5432
```

Succeeded.

PostgreSQL through PSC also succeeded:

```bash
psql -h 10.20.134.2 \
  -p 5432 \
  -U postgres \
  -d postgres
```

---

# 15. GKE Cluster

Cluster:

```text
gke-secure-lab
```

Type:

```text
GKE Standard
```

Zone:

```text
us-east4-a
```

Kubernetes version:

```text
1.35.7-gke.1150000
```

Nodes:

```text
Private nodes
```

Workload Identity:

```text
Enabled
```

Workload Identity pool:

```text
project-a95e6dc6-f7fc-4043-bf9.svc.id.goog
```

---

# 16. GKE Networking

GKE is VPC-native.

Node range:

```text
10.150.0.0/20
```

Pod secondary range:

```text
10.60.0.0/16
```

Service secondary range:

```text
10.70.0.0/20
```

Example:

```text
Node:
10.150.0.5

Pod:
10.60.0.x

Service:
10.70.x.x
```

---

# 17. GKE Pod-to-Pod Connectivity

Pod-to-pod connectivity was tested successfully.

Architecture:

```text
Pod A
10.60.x.x
   |
   v
GKE VPC networking
   |
   v
Pod B
10.60.x.x
```

---

# 18. GKE Pod-to-Service Connectivity

Service:

```text
net-test-service
```

ClusterIP:

```text
10.70.5.185
```

Endpoint:

```text
10.60.0.15:80
```

HTTP connectivity from another Pod succeeded.

This demonstrated:

```text
Pod
 |
 v
Kubernetes Service
 |
 v
Pod
```

---

# 19. GKE → Cloud SQL Using PSA

A PostgreSQL client Pod was created.

Pod:

```text
psql-client
```

Pod IP:

```text
10.60.0.16
```

Connection:

```text
10.60.0.16
     |
     v
10.81.132.3:5432
     |
     v
PSA
     |
     v
Cloud SQL
```

PostgreSQL connection succeeded.

Server address:

```text
10.81.132.3
```

---

# 20. GKE → Cloud SQL Using PSC

The same GKE environment successfully connected through:

```text
10.20.134.2:5432
```

Architecture:

```text
GKE Pod
10.60.x.x
   |
   v
PSC endpoint
10.20.134.2
   |
   v
PSC service attachment
   |
   v
Cloud SQL
```

PostgreSQL connection succeeded.

---

# 21. Workload Identity

Namespace:

```text
secure-app
```

Kubernetes ServiceAccount:

```text
app-ksa
```

Google Service Account:

```text
secure-app-gsa@project-a95e6dc6-f7fc-4043-bf9.iam.gserviceaccount.com
```

Trust relationship:

```text
Kubernetes ServiceAccount
        |
        | Workload Identity
        v
Google Service Account
```

No service-account key was mounted.

---

# 22. Workload Identity IAM Binding

Binding:

```bash
gcloud iam service-accounts add-iam-policy-binding \
  secure-app-gsa@project-a95e6dc6-f7fc-4043-bf9.iam.gserviceaccount.com \
  --role=roles/iam.workloadIdentityUser \
  --member="serviceAccount:project-a95e6dc6-f7fc-4043-bf9.svc.id.goog[secure-app/app-ksa]"
```

Kubernetes annotation:

```bash
kubectl annotate serviceaccount app-ksa \
  -n secure-app \
  iam.gke.io/gcp-service-account=secure-app-gsa@project-a95e6dc6-f7fc-4043-bf9.iam.gserviceaccount.com
```

---

# 23. Cloud SQL IAM Roles

GSA:

```text
secure-app-gsa
```

Roles:

```text
roles/cloudsql.client
roles/cloudsql.instanceUser
```

Meaning:

### Cloud SQL Client

Allows the workload to connect to Cloud SQL.

### Cloud SQL Instance User

Allows IAM-based database authentication.

---

# 24. Cloud SQL IAM Authentication

Cloud SQL PostgreSQL has:

```text
cloudsql.iam_authentication=on
```

IAM database user:

```text
secure-app-gsa@project-a95e6dc6-f7fc-4043-bf9.iam
```

Important PostgreSQL detail:

The PostgreSQL IAM username uses the service-account email without:

```text
.gserviceaccount.com
```

---

# 25. Cloud SQL Auth Proxy

Proxy image:

```text
gcr.io/cloud-sql-connectors/cloud-sql-proxy:2.18.2
```

Initial successful PSA configuration:

```text
--auto-iam-authn
--private-ip
--structured-logs
--address=0.0.0.0
INSTANCE_CONNECTION_NAME
```

Connection name:

```text
project-a95e6dc6-f7fc-4043-bf9:us-east4:gcp-infra-psql
```

---

# 26. Successful IAM Authentication Test

The application Pod connected through:

```text
KSA
 |
 v
Workload Identity
 |
 v
GSA
 |
 v
Cloud SQL IAM
 |
 v
Cloud SQL Auth Proxy
 |
 v
Cloud SQL
```

Command:

```bash
psql \
  -h 127.0.0.1 \
  -p 5432 \
  -U 'secure-app-gsa@project-a95e6dc6-f7fc-4043-bf9.iam' \
  -d postgres
```

Successful result:

```text
current_database = postgres

current_user =
secure-app-gsa@project-a95e6dc6-f7fc-4043-bf9.iam
```

This proved:

```text
GKE
+
Workload Identity
+
IAM
+
Cloud SQL IAM DB Authentication
+
Cloud SQL Auth Proxy
+
Private connectivity
```

---

# 27. Current PSC Proxy Investigation

Goal:

```text
GKE
 |
 v
Workload Identity
 |
 v
Cloud SQL Auth Proxy
 |
 v
PSC
 |
 v
Cloud SQL
```

The proxy was changed to:

```text
--auto-iam-authn
--psc
--structured-logs
--address=0.0.0.0
INSTANCE_CONNECTION_NAME
```

However, the proxy attempted to resolve:

```text
8b5fa6a7cfb9.3g03wvzwjqqnd.us-east4.sql.goog
```

instead of the PSC hostname:

```text
8b5fa6a7cfb9.3g03wvzwjqqnd.us-east4.sql-psc.goog
```

The PSC hostname itself resolves correctly:

```text
10.20.134.2
```

Current status:

```text
PSA path = successfully tested
PSC direct connectivity = successfully tested
PSC + Cloud SQL Auth Proxy = still being investigated
```

This is where the lab will continue tomorrow.

Google's current Cloud SQL documentation explicitly documents using the PSC DNS name with the Auth Proxy and also documents `--psc` for PSC-enabled instances.

---

# 28. Cloud Armor

Cloud Armor is part of the external application security layer.

Target architecture:

```text
Internet
   |
   v
External HTTPS Load Balancer
   |
   v
Cloud Armor
   |
   v
GKE
```

Cloud Armor provides capabilities such as:

* Layer 7 protection
* WAF rules
* IP-based rules
* Geo-based rules
* Rate limiting
* OWASP-related protections
* DDoS protection integration

Important interview point:

> Cloud Armor is generally placed at the Google Cloud load-balancing edge, before traffic reaches the backend.

---

# 29. Apigee

Apigee is the API management layer.

Conceptually:

```text
Client
  |
  v
Apigee
  |
  v
Backend API
  |
  v
GKE / Cloud Run / other backend
```

Apigee provides API-management capabilities such as:

* API proxying
* Authentication
* Authorization
* API policies
* Rate limiting
* Quotas
* Traffic management
* API analytics
* Developer/API consumer management

---

# 30. Cloud Armor vs Apigee

Important interview distinction:

### Cloud Armor

Primarily:

```text
Network/application edge security
+
WAF
+
DDoS
+
IP/rate-based protection
```

### Apigee

Primarily:

```text
API management
+
API policies
+
API consumers
+
API lifecycle
+
Analytics
```

They can coexist.

Example:

```text
Internet
   |
   v
Load Balancer
   |
   v
Cloud Armor
   |
   v
Apigee
   |
   v
GKE API
```

---

# 31. Key Security Model

The lab demonstrates four separate security concepts.

## Network connectivity

```text
VPC
PSA
PSC
PGA
Firewall
```

Question answered:

> Can the workload reach the destination?

---

## Workload identity

```text
Kubernetes ServiceAccount
        |
        v
Workload Identity
        |
        v
Google ServiceAccount
```

Question answered:

> Who is the workload?

---

## IAM authorization

```text
Google ServiceAccount
        |
        v
IAM roles
```

Question answered:

> What is the workload allowed to do?

---

## Database authentication

```text
IAM DB User
        |
        v
Cloud SQL
```

Question answered:

> Which database identity is being used?

---

# 32. Important Interview Statement

A strong senior-level answer:

> "I separate connectivity, identity, authorization, and application/database authentication. PSA or PSC determines how the workload privately reaches Cloud SQL. Workload Identity determines the Google identity of the GKE workload. IAM controls what that identity can access, while Cloud SQL IAM authentication determines the database identity used for PostgreSQL authentication."

---

# 33. Current Lab Status

| Component                    | Status                        |
| ---------------------------- | ----------------------------- |
| VPC                          | Completed                     |
| Subnet                       | Completed                     |
| PGA                          | Completed                     |
| PSA                          | Completed                     |
| Cloud SQL private IP         | Completed                     |
| VM → Cloud SQL PSA           | Tested                        |
| PSC                          | Completed                     |
| PSC endpoint                 | Completed                     |
| PSC DNS                      | Completed                     |
| VM → Cloud SQL PSC           | Tested                        |
| GKE Standard                 | Completed                     |
| Private GKE nodes            | Completed                     |
| Pod networking               | Tested                        |
| Service networking           | Tested                        |
| GKE → Cloud SQL PSA          | Tested                        |
| GKE → Cloud SQL PSC          | Tested                        |
| Workload Identity            | Completed                     |
| IAM                          | Completed                     |
| Cloud SQL IAM authentication | Completed                     |
| Auth Proxy + IAM + PSA       | Tested successfully           |
| Auth Proxy + IAM + PSC       | **Investigation remaining**   |
| Cloud Armor                  | Studied/configured previously |
| Apigee                       | Studied/configured previously |

---

# 34. Tomorrow's Plan

Start from:

```text
Cloud SQL Auth Proxy + PSC
```

Then continue:

### Step 1

Fix:

```text
GKE
→
Cloud SQL Auth Proxy
→
PSC
→
Cloud SQL
```

### Step 2

Build the application deployment:

```text
Deployment
+
Service
+
KSA
```

### Step 3

Secure the application:

```text
Workload Identity
+
Secret Manager
+
Network Policy
+
least-privilege IAM
```

### Step 4

Expose the application:

```text
GKE
→
Gateway / HTTPS Load Balancer
→
Cloud Armor
→
Internet
```

### Step 5

Add API management:

```text
Client
→
Apigee
→
Cloud Armor / LB
→
GKE API
```

### Step 6

Then move into advanced security:

```text
VPC Service Controls
        +
Private Service Connect
        +
IAM
        +
GKE
        +
Cloud SQL
        +
Cloud Armor
        +
Apigee
```

This will give us a realistic **Senior GCP Infrastructure/Security/DevSecOps interview architecture** rather than isolated service demos.
