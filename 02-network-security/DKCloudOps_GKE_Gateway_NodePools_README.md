# DKCloudOps — GKE, Node Pools, Control Plane & Gateway

## 1. GKE Mental Model

Google Kubernetes Engine (GKE) is Google Cloud's managed Kubernetes service.

```text
GKE Cluster
|
+-- Control Plane
|
+-- Data Plane / Node Pools
```

## 2. Control Plane

The control plane is the Kubernetes brain.

Conceptual components:

- API Server
- Scheduler
- Controller Manager
- etcd

Responsibilities:

- Kubernetes API
- scheduling pods
- maintaining desired state
- controllers/reconciliation
- cluster metadata/state

In GKE, Google manages the control plane.

## 3. Data Plane

The data plane is where application workloads run.

```text
Node Pool
   |
   +-- Node 1
   |    +-- Pod
   |    +-- Pod
   |
   +-- Node 2
        +-- Pod
```

Nodes run kubelet, container runtime, networking components and workload pods.

## 4. Node Pools

A node pool is a group of nodes sharing a common configuration.

Important settings:

- machine type
- disk size/type
- node count
- autoscaling
- service account
- Kubernetes version
- image type
- labels
- taints

Example:

```text
GKE Cluster
|
+-- system-pool
+-- app-pool
+-- ai-pool
```

Multiple pools help isolate workloads and optimize performance/cost.

## 5. Labels, Taints and Tolerations

Labels describe nodes and can be used by node selectors/affinity.

Taints repel pods.

```text
dedicated=payments:NoSchedule
```

A toleration lets an approved pod schedule onto that tainted node.

Mental model:

- Taint = keep normal pods away
- Toleration = this pod is allowed here

## 6. Control Plane vs Node Pool Upgrade

Typical sequence:

```text
Upgrade Control Plane
        |
        v
Upgrade Node Pools
        |
        v
Validate workloads
```

The control-plane and node versions are related but upgraded separately.

Node upgrades can drain/replace nodes, so application resilience matters.

## 7. Safe Node Upgrade Considerations

Use:

- multiple replicas
- PodDisruptionBudgets
- readiness probes
- liveness probes
- graceful termination
- surge upgrade settings

Conceptually:

```text
Old Node
   |
Pods drain
   |
New Node joins
   |
Pods reschedule
```

## 8. GKE Networking

Typical north-south flow:

```text
Internet
   |
   v
Load Balancer / Gateway
   |
   v
Kubernetes Service
   |
   v
Pods
```

Typical east-west flow:

```text
Pod -> Service -> Pod
```

## 9. Kubernetes Service Types

### ClusterIP

Internal-only service discovery inside the cluster.

### LoadBalancer

Creates/exposes a cloud load balancer.

### NodePort

Exposes a port on every node; generally not the preferred enterprise ingress design.

## 10. GKE Gateway API

Gateway API is the newer Kubernetes networking model.

Key resources:

```text
GatewayClass
Gateway
HTTPRoute
```

Mental model:

- GatewayClass = which controller/implementation
- Gateway = listener/load-balancer configuration
- HTTPRoute = routing rules to services

## 11. Gateway Traffic Flow

```text
Internet
   |
   v
Google Cloud Load Balancer
   |
   v
Gateway
   |
   v
HTTPRoute
   |
   v
Kubernetes Service
   |
   v
Pods
```

Example:

```text
/api/* -> backend-service
/*     -> frontend-service
```

## 12. Gateway vs Ingress

Gateway API adds:

- richer routing
- multiple listeners
- better role separation
- cross-namespace support
- cleaner platform-team/app-team ownership model

Example:

```text
Platform team -> Gateway
Application team -> HTTPRoute
```

## 13. HTTPS and Static IP

A production external Gateway typically uses:

```text
Reserved static public IP
      |
      v
Google Load Balancer
      |
      v
HTTPS listener
      |
      v
Gateway
```

DNS maps your domain to the static IP:

```text
dkcloudops.com -> reserved public IP
```

## 14. Cloud Armor

Cloud Armor protects traffic at the Google Cloud load-balancer edge.

```text
Internet
   |
   v
Cloud Armor
   |
   v
Load Balancer
   |
   v
GKE Gateway
   |
   v
Pods
```

Typical controls:

- IP allow/deny
- rate limiting
- WAF protections
- geo restrictions
- SQLi/XSS protections

## 15. Network Endpoint Groups (NEG)

GKE can use NEGs so the load balancer targets pod endpoints more directly.

```text
Load Balancer
   |
   v
NEG
   |
   v
Pod endpoints
```

This supports container-native load balancing.

## 16. Private GKE

A secure production design commonly uses:

- private nodes
- no public node IPs
- controlled control-plane access
- Private Google Access
- Cloud NAT for outbound internet access when required

```text
Private Node
   |
   v
Subnet
   |
   v
Cloud NAT
   |
   v
Internet
```

Cloud NAT provides outbound connectivity; it does not expose inbound services.

## 17. Workload Identity Federation for GKE

Avoid service-account JSON keys inside pods.

Preferred:

```text
Kubernetes Service Account
        |
        v
Workload Identity Federation
        |
        v
Google IAM identity
        |
        v
GCP API
```

This uses short-lived credentials.

## 18. Google IAM vs Kubernetes RBAC

Google IAM answers questions such as:

```text
Can this identity access/manage this GKE cluster or GCP resource?
```

Kubernetes RBAC answers:

```text
Can this subject create/update/list Kubernetes resources
inside this cluster/namespace?
```

Both are required for strong access control.

## 19. NetworkPolicy

NetworkPolicy governs east-west pod traffic.

Example:

```text
Frontend
   |
   | ALLOW
   v
Backend

Unknown pod
   |
   X DENY
```

A default-deny posture is common for sensitive workloads.

## 20. Pod Security

Restrict dangerous pod configurations such as:

- privileged mode
- host networking
- host PID
- hostPath
- unnecessary Linux capabilities
- root execution
- privilege escalation

Typical secure container settings include:

```text
runAsNonRoot: true
readOnlyRootFilesystem: true
allowPrivilegeEscalation: false
```

## 21. Secrets

Avoid embedding secrets in manifests or Git.

Prefer:

- Secret Manager
- Workload Identity
- external-secret integrations
- tightly controlled Kubernetes Secrets where appropriate

## 22. Image and Supply-Chain Security

```text
Source
   |
SAST / SCA
   |
Build
   |
Container scan
   |
Artifact Registry
   |
Binary Authorization
   |
GKE
```

Binary Authorization can prevent unapproved images from deploying.

## 23. Logging and Monitoring

Important signals include:

- pod logs
- restarts
- CPU/memory
- node health
- readiness failures
- load-balancer health
- latency
- error rate
- Kubernetes audit activity

Use Cloud Logging and Cloud Monitoring for centralized observability.

## 24. Security Architecture

```text
Internet
   |
   v
Cloud Armor
   |
   v
HTTPS Load Balancer
   |
   v
GKE Gateway
   |
   v
HTTPRoute
   |
   v
Service
   |
   v
Pods
   |
NetworkPolicy
   |
Workload Identity
   |
Google APIs
```

Cluster hardening:

```text
Private nodes
RBAC
Workload Identity Federation
Pod Security
NetworkPolicy
Artifact scanning
Binary Authorization
Audit logging
Least-privilege IAM
```

## 25. Control Plane vs Node Pool Interview Summary

> The GKE control plane manages Kubernetes state, scheduling and the Kubernetes API and is managed by Google. Node pools are the worker/data plane where application pods execute. Control-plane and node-pool versions are related but upgraded separately. Node pools can use different machine types, autoscaling, labels, taints and security profiles for different workload classes.

## 26. Gateway Interview Summary

> GKE Gateway API provides a modern Kubernetes-native way to configure Google Cloud load balancing. Gateway defines listeners and frontend infrastructure, while HTTPRoute defines application routing to Kubernetes Services. An external Gateway can use a reserved static IP, DNS and HTTPS, and Cloud Armor protects traffic at the load-balancer layer before requests reach the cluster.

## 27. Quick Mental Model

```text
GKE
|
+-- Control Plane
|      Kubernetes brain
|
+-- Node Pools
|      worker VMs
|
+-- Pods
|      applications
|
+-- Services
|      stable service discovery
|
+-- Gateway
|      traffic entry
|
+-- HTTPRoute
|      routing rules
|
+-- Cloud Armor
|      edge security
|
+-- Workload Identity
|      GCP authentication
|
+-- RBAC / NetworkPolicy / Pod Security
       authorization + isolation
```
