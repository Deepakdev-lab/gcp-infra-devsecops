# GKE Secure Gateway Lab

## Overview

This lab demonstrates a secure, production-style application exposure pattern on Google Kubernetes Engine (GKE) using the **GKE Gateway API** and a **Google-managed Global External Application Load Balancer**.

The application runs inside GKE and is exposed externally through the Google-managed load balancer. The Kubernetes application Service remains `ClusterIP`, so the Pod is not directly exposed to the Internet.

### Current Architecture

```text
                         INTERNET
                            │
                            │ HTTP
                            ▼
                 ┌──────────────────────┐
                 │ Google Global        │
                 │ External Application │
                 │ Load Balancer        │
                 │                      │
                 │ Public IP            │
                 │ 35.190.12.178        │
                 └──────────┬───────────┘
                            │
                            ▼
                 ┌──────────────────────┐
                 │ GKE Gateway API      │
                 │ secure-gateway       │
                 │                      │
                 │ GatewayClass:        │
                 │ gke-l7-global-       │
                 │ external-managed     │
                 └──────────┬───────────┘
                            │
                            ▼
                 ┌──────────────────────┐
                 │ HTTPRoute            │
                 │ secure-demo-route    │
                 │ PathPrefix: /        │
                 └──────────┬───────────┘
                            │
                            ▼
                 ┌──────────────────────┐
                 │ ClusterIP Service    │
                 │ secure-demo:8080     │
                 └──────────┬───────────┘
                            │
                            ▼
                 ┌──────────────────────┐
                 │ GKE Pod              │
                 │ secure-demo          │
                 │ 10.60.1.2:8080       │
                 │                      │
                 │ Python 3.12 Alpine   │
                 └──────────────────────┘
```

---

# 1. Environment

## GCP Project

```text
Project ID:
project-a95e6dc6-f7fc-4043-bf9

Project Number:
565532451627
```

## GKE Cluster

```text
Cluster:
gke-secure-lab

Location:
us-east4-a

Network:
default

Cluster type:
Zonal
```

## Application Namespace

```text
secure-app
```

---

# 2. Python Demo Application

The lab application is intentionally lightweight and runs directly inside the Kubernetes Pod.

The container image is:

```text
python:3.12-alpine
```

No separate Docker image was created.

No ConfigMap is required.

The Python source code is passed directly to Python using:

```text
python -c "<application code>"
```

This makes the lab easy to reproduce while demonstrating Kubernetes networking and GKE Gateway functionality.

---

# 3. Kubernetes Deployment

## Deployment

The application is deployed using a Kubernetes Deployment.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-demo
  namespace: secure-app

spec:
  replicas: 1

  selector:
    matchLabels:
      app: secure-demo

  template:
    metadata:
      labels:
        app: secure-demo

    spec:
      containers:
      - name: app

        image: python:3.12-alpine

        ports:
        - name: http
          containerPort: 8080

        command:
        - python
        - -c
        - |
          import json
          from http.server import BaseHTTPRequestHandler, HTTPServer
          from urllib.parse import urlparse, parse_qs

          class Handler(BaseHTTPRequestHandler):

              def send_json(self, status, data):
                  body = json.dumps(data).encode()

                  self.send_response(status)
                  self.send_header("Content-Type", "application/json")
                  self.send_header("Content-Length", str(len(body)))
                  self.end_headers()
                  self.wfile.write(body)

              def do_GET(self):
                  parsed = urlparse(self.path)
                  path = parsed.path
                  query = parse_qs(parsed.query)

                  if path == "/":
                      self.send_json(200, {
                          "application": "FedEx Secure GKE Demo",
                          "status": "OK",
                          "environment": "private",
                          "service": "secure-demo"
                      })

                  elif path == "/health":
                      self.send_json(200, {
                          "status": "healthy"
                      })

                  elif path == "/api/data":
                      self.send_json(200, {
                          "message": "Secure API data response",
                          "shipment_id": "FX123456789",
                          "status": "IN_TRANSIT",
                          "origin": "Toronto",
                          "destination": "Chicago"
                      })

                  elif path == "/api/users":
                      self.send_json(200, {
                          "users": [
                              {"id": 1, "name": "Alice"},
                              {"id": 2, "name": "Bob"}
                          ]
                      })

                  elif path == "/api/admin":
                      self.send_json(200, {
                          "message": "Admin endpoint reached",
                          "note": "Cloud Armor can protect this path"
                      })

                  elif path == "/api/search":
                      q = query.get("q", [""])[0]

                      self.send_json(200, {
                          "query": q,
                          "message": "Search request received"
                      })

                  else:
                      self.send_json(404, {
                          "error": "Not Found",
                          "path": path
                      })

              def log_message(self, format, *args):
                  print("%s - %s" % (
                      self.address_string(),
                      format % args
                  ))

          server = HTTPServer(("0.0.0.0", 8080), Handler)

          print("Secure demo API listening on port 8080")

          server.serve_forever()

        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 250m
            memory: 256Mi

        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          timeoutSeconds: 2
          periodSeconds: 10
          failureThreshold: 3

        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 3
          timeoutSeconds: 2
          periodSeconds: 5
          failureThreshold: 3
```

Apply:

```bash
kubectl apply -f deployment.yaml
```

Verify:

```bash
kubectl get deployment -n secure-app
kubectl get pods -n secure-app -o wide
```

Expected:

```text
NAME          READY   UP-TO-DATE   AVAILABLE
secure-demo   1/1     1            1
```

---

# 4. Python API Endpoints

The embedded Python application provides several endpoints.

| Endpoint         | Purpose                                |
| ---------------- | -------------------------------------- |
| `/`              | Application status                     |
| `/health`        | Kubernetes health probe                |
| `/api/data`      | Demo shipment data                     |
| `/api/users`     | Demo user data                         |
| `/api/admin`     | Admin endpoint for Cloud Armor testing |
| `/api/search?q=` | Query parameter demonstration          |
| Any other path   | HTTP 404                               |

### Root endpoint

```bash
curl http://35.190.12.178/
```

Response:

```json
{
  "application": "FedEx Secure GKE Demo",
  "status": "OK",
  "environment": "private",
  "service": "secure-demo"
}
```

### Health endpoint

```bash
curl http://35.190.12.178/health
```

Expected:

```json
{
  "status": "healthy"
}
```

---

# 5. Kubernetes Health Probes

The application exposes:

```text
/health
```

for Kubernetes health checking.

### Liveness Probe

```text
GET /health
```

Used to determine whether the container is alive.

Configuration:

```text
initialDelaySeconds: 10
timeoutSeconds: 2
periodSeconds: 10
failureThreshold: 3
```

### Readiness Probe

```text
GET /health
```

Used to determine whether the Pod is ready to receive traffic.

Configuration:

```text
initialDelaySeconds: 3
timeoutSeconds: 2
periodSeconds: 5
failureThreshold: 3
```

Conceptually:

```text
                 Kubernetes
                     │
          ┌──────────┴──────────┐
          │                     │
          ▼                     ▼
      Liveness              Readiness
       /health               /health
          │                     │
          ▼                     ▼
   Container alive?       Receive traffic?
```

---

# 6. Kubernetes Service

The application is exposed internally through a `ClusterIP` Service.

```yaml
apiVersion: v1
kind: Service

metadata:
  name: secure-demo
  namespace: secure-app

spec:
  selector:
    app: secure-demo

  ports:
  - name: http
    port: 8080
    targetPort: 8080

  type: ClusterIP
```

Apply:

```bash
kubectl apply -f service.yaml
```

Check:

```bash
kubectl get svc -n secure-app
```

Current Service:

```text
secure-demo   ClusterIP   10.70.11.185   <none>   8080/TCP
```

The Service is intentionally **not**:

```text
LoadBalancer
```

and not:

```text
NodePort
```

This prevents the application from independently creating another external load-balancing entry point.

---

# 7. Validate Service → Pod Connectivity

The application was tested directly from inside the cluster.

```bash
kubectl run curl-test \
  -n secure-app \
  --rm -it \
  --image=curlimages/curl \
  --restart=Never \
  -- curl -i http://secure-demo:8080/
```

Successful response:

```text
HTTP/1.0 200 OK
```

with:

```json
{
  "application": "FedEx Secure GKE Demo",
  "status": "OK",
  "environment": "private",
  "service": "secure-demo"
}
```

This proves:

```text
Pod
 ↓
Service
 ↓
Service-to-Pod connectivity
```

---

# 8. GKE Gateway API

Gateway API was enabled:

```bash
gcloud container clusters update gke-secure-lab \
  --zone=us-east4-a \
  --gateway-api=standard \
  --project=project-a95e6dc6-f7fc-4043-bf9
```

Verify:

```bash
kubectl get gatewayclass
```

Selected GatewayClass:

```text
gke-l7-global-external-managed
```

This provisions a Google-managed **Global External Application Load Balancer**.

---

# 9. Gateway

Gateway configuration:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway

metadata:
  name: secure-gateway
  namespace: secure-app

spec:
  gatewayClassName: gke-l7-global-external-managed

  listeners:
  - name: http
    protocol: HTTP
    port: 80

    allowedRoutes:
      namespaces:
        from: Same
```

Apply:

```bash
kubectl apply -f gateway.yaml
```

Check:

```bash
kubectl get gateway -n secure-app
```

Current Gateway:

```text
NAME             CLASS                            ADDRESS         PROGRAMMED
secure-gateway   gke-l7-global-external-managed   35.190.12.178   True
```

Public IP:

```text
35.190.12.178
```

---

# 10. HTTPRoute

The application is connected to the Gateway using an `HTTPRoute`.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute

metadata:
  name: secure-demo-route
  namespace: secure-app

spec:
  parentRefs:
  - name: secure-gateway

  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /

    backendRefs:
    - name: secure-demo
      port: 8080
```

Apply:

```bash
kubectl apply -f httproute.yaml
```

Verify:

```bash
kubectl get httproute -n secure-app
```

The route successfully reached:

```text
ResolvedRefs=True
Accepted=True
Reconciled=True
```

Traffic flow:

```text
HTTP /
   ↓
secure-gateway
   ↓
secure-demo-route
   ↓
secure-demo:8080
```

---

# 11. GKE NEG

GKE automatically created a Network Endpoint Group for the Service.

Backend NEG:

```text
k8s1-5b6304fe-secure-app-secure-demo-8080-7c281a30
```

Zone:

```text
us-east4-a
```

Application endpoint:

```text
10.60.1.2:8080
```

Conceptually:

```text
Google LB
    ↓
GKE NEG
    ↓
10.60.1.2:8080
    ↓
secure-demo Pod
```

---

# 12. Backend Health

The Google Cloud backend was verified:

```bash
gcloud compute backend-services get-health \
  gkegw1-qm6k-secure-app-secure-demo-8080-wqi4f7l2fh2l \
  --global \
  --project=project-a95e6dc6-f7fc-4043-bf9
```

Result:

```text
healthState: HEALTHY
ipAddress: 10.60.1.2
port: 8080
```

This confirms the Google-managed load balancer can successfully reach the GKE backend.

---

# 13. End-to-End Validation

External request:

```bash
curl http://35.190.12.178/
```

Successful response:

```json
{
  "application": "FedEx Secure GKE Demo",
  "status": "OK",
  "environment": "private",
  "service": "secure-demo"
}
```

Complete working path:

```text
Internet
   ↓
35.190.12.178
   ↓
Global External Application Load Balancer
   ↓
GKE Gateway
   ↓
HTTPRoute
   ↓
ClusterIP Service
   ↓
GKE NEG
   ↓
GKE Pod
   ↓
Python Application
```

---

# 14. Why ClusterIP?

The application Service remains:

```text
ClusterIP
```

instead of:

```text
LoadBalancer
```

or:

```text
NodePort
```

The desired architecture is:

```text
Internet
   ↓
Google External ALB
   ↓
GKE Gateway
   ↓
ClusterIP Service
   ↓
Private Pod
```

This provides a single controlled external entry point.

---

# 15. Current Security Posture

Currently implemented:

* GKE Gateway API
* Google-managed Global External Application Load Balancer
* ClusterIP backend
* Private Pod IP
* GKE NEG
* Google-managed health checking
* Kubernetes readiness probe
* Kubernetes liveness probe
* No direct Pod public IP
* No NodePort exposure
* No Kubernetes LoadBalancer Service

The application itself is therefore not directly exposed through a Kubernetes public Service.

---

# 16. Pending — HTTPS / TLS

Current:

```text
Internet
   ↓
HTTP :80
   ↓
GKE Gateway
```

Target:

```text
Internet
   ↓
HTTPS :443
   ↓
TLS Certificate
   ↓
Google Global External ALB
   ↓
GKE Gateway
```

Planned:

* HTTPS Gateway listener
* TLS certificate
* Port 443
* HTTP → HTTPS redirect
* TLS validation
* Test using `curl -I` and browser

Status:

```text
PENDING
```

---

# 17. Pending — Cloud Armor / WAF

Cloud Armor will provide the external Layer 7 security layer.

Target:

```text
Internet
   ↓
Global External Application Load Balancer
   ↓
Cloud Armor
   │
   ├── WAF
   ├── SQL Injection protection
   ├── XSS protection
   ├── Rate limiting
   ├── IP filtering
   └── DDoS protection
   ↓
GKE Gateway
   ↓
HTTPRoute
   ↓
ClusterIP
   ↓
Private Pod
```

The planned GKE integration is through:

```text
GCPBackendPolicy
```

associated with the `secure-demo` Service.

The existing `/api/admin` endpoint was intentionally included as a convenient endpoint for security-policy testing.

Planned validation:

```text
Normal request
     ↓
HTTP 200

Malicious request
     ↓
Cloud Armor
     ↓
HTTP 403
```

Status:

```text
PENDING
```

---

# 18. Pending — Custom Domain

Current endpoint:

```text
http://35.190.12.178
```

Target:

```text
https://api.example.com
```

Planned architecture:

```text
api.example.com
       │
       ▼
    Cloud DNS
       │
       ▼
35.190.12.178
       │
       ▼
Global External ALB
       │
       ▼
HTTPS Gateway
```

Planned:

* Custom domain
* DNS A/AAAA record as appropriate
* TLS certificate for domain
* HTTPS Gateway listener
* DNS validation
* End-to-end HTTPS test

Status:

```text
PENDING
```

---

# 19. Final Target Architecture

After the pending security enhancements:

```text
                         INTERNET
                            │
                            │ HTTPS
                            ▼
                    api.example.com
                            │
                            ▼
             ┌────────────────────────────┐
             │ Google Global External ALB │
             │                            │
             │ TLS termination            │
             │ Global routing             │
             └─────────────┬──────────────┘
                           │
                           ▼
             ┌────────────────────────────┐
             │       Cloud Armor          │
             │                            │
             │ WAF                        │
             │ SQLi / XSS                 │
             │ Rate limiting              │
             │ IP rules                   │
             │ DDoS protection            │
             └─────────────┬──────────────┘
                           │
                           ▼
                  ┌─────────────────┐
                  │ GKE Gateway API │
                  │                 │
                  │ HTTPS :443      │
                  └────────┬────────┘
                           │
                           ▼
                    HTTPRoute /
                           │
                           ▼
                  ┌─────────────────┐
                  │ ClusterIP       │
                  │ secure-demo     │
                  │ :8080           │
                  └────────┬────────┘
                           │
                           ▼
                     Private Pod
                     10.60.1.2
                     :8080
                           │
                           ▼
                    Python 3.12
                    Demo API
```

---

# 20. Validation Checklist

## Completed

* [x] GKE cluster created
* [x] Gateway API enabled
* [x] GatewayClass selected
* [x] `secure-app` namespace created
* [x] Python application deployed
* [x] Python application embedded directly in Deployment
* [x] `/health` endpoint implemented
* [x] Liveness probe configured
* [x] Readiness probe configured
* [x] Resource requests/limits configured
* [x] ClusterIP Service created
* [x] Pod connectivity validated
* [x] Gateway created
* [x] Global External Application Load Balancer provisioned
* [x] HTTPRoute created
* [x] HTTPRoute accepted
* [x] HTTPRoute reconciled
* [x] GKE NEG created
* [x] Backend health verified
* [x] External HTTP request validated
* [x] Application returned HTTP 200

## Pending

* [ ] HTTPS listener
* [ ] TLS certificate
* [ ] HTTP → HTTPS redirect
* [ ] Cloud Armor policy
* [ ] Cloud Armor WAF rules
* [ ] GCPBackendPolicy
* [ ] Cloud Armor deny testing
* [ ] Cloud Armor logging validation
* [ ] Custom domain
* [ ] Cloud DNS record
* [ ] HTTPS validation using custom domain

---

# 21. Interview Takeaways

### Why Gateway API?

Gateway API provides a Kubernetes-native model for defining Layer 7 traffic routing while GKE manages the underlying Google Cloud load-balancing infrastructure.

### Why `gke-l7-global-external-managed`?

It provisions a Google-managed Global External Application Load Balancer suitable for Internet-facing applications.

### Why ClusterIP?

The Kubernetes Service does not need to independently expose the application. The Gateway provides the controlled external entry point.

### Why NEG?

GKE uses Network Endpoint Groups to connect the Google Cloud Load Balancer to Kubernetes application endpoints.

### Why are Pods still private?

The Pod uses a private IP:

```text
10.60.1.2
```

Clients access the application through:

```text
Public LB
   ↓
Gateway
   ↓
Service
   ↓
Pod
```

rather than connecting directly to the Pod.

### Does the GKE region need to match the Global Load Balancer?

No.

This lab uses:

```text
GKE:
us-east4-a

Load Balancer:
Global
```

This is a valid architecture.

---

# 22. Current Status

```text
┌────────────────────────────────────────────┐
│          GKE SECURE GATEWAY LAB            │
├────────────────────────────────────────────┤
│                                            │
│  GKE Cluster                         ✅    │
│  Python Demo API                     ✅    │
│  Health Probes                       ✅    │
│  ClusterIP                           ✅    │
│  Gateway API                         ✅    │
│  Global External ALB                 ✅    │
│  HTTPRoute                           ✅    │
│  GKE NEG                             ✅    │
│  Backend Health                      ✅    │
│  External HTTP                       ✅    │
│                                            │
│  HTTPS / TLS                        🔴    │
│  Cloud Armor / WAF                  🔴    │
│  Custom Domain                      🔴    │
│                                            │
└────────────────────────────────────────────┘
```

Current working endpoint:

```text
http://35.190.12.178
```

The next phase is to harden this working baseline by implementing:

```text
1. HTTPS / TLS
2. Cloud Armor / WAF
3. Custom Domain + Cloud DNS
```

The existing working GKE routing should be preserved while these security layers are added incrementally.
