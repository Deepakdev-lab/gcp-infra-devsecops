# GCP Data Migration and Data Engineering – Practical Preparation Checklist

## Objective

This README focuses on practical **data migration, streaming ingestion, networking, and security** scenarios relevant to enterprise GCP environments.

Primary technologies:

- Storage Transfer Service
- Google Cloud Storage
- Dataflow
- Apache Beam
- Azure Event Hubs
- Apache Kafka
- Pub/Sub
- BigQuery
- IAM
- Private networking
- Encryption
- Logging and monitoring

---

# 1. Data Migration Use Cases

Prepare for three major migration patterns.

```text
1. Object / File Migration
   Source Storage
        ↓
   Storage Transfer Service
        ↓
   Google Cloud Storage

2. Streaming Migration
   Azure Event Hubs
        ↓
   Dataflow
        ↓
   BigQuery

3. Kafka Streaming
   Kafka
      ↓
   Apache Beam
      ↓
   Pub/Sub / BigQuery
```

---

# 2. Storage Transfer Service

## Use Case

Move large quantities of object/file data from another storage platform into Google Cloud Storage.

Possible sources include:

- AWS S3
- Azure Blob Storage
- HTTP/HTTPS locations
- On-premises file systems
- Another GCS bucket

## Architecture

```text
Source Storage
      ↓
Storage Transfer Service
      ↓
GCS Landing Bucket
      ↓
Validation
      ↓
Processed / Trusted Bucket
```

---

# 3. Storage Transfer Service – Practical Lab

## Hands-On Tasks

- Create source storage
- Create destination GCS bucket
- Enable required APIs
- Configure IAM
- Create transfer job
- Configure:
  - Scheduled transfer
  - One-time transfer
  - Incremental transfer
  - Delete-after-transfer option
- Run transfer
- Validate object count
- Validate checksum/integrity
- Review transfer logs
- Test failed transfer
- Retry failed objects

## Security Controls

- Dedicated service account
- Least-privilege IAM
- Public Access Prevention
- Uniform Bucket-Level Access
- CMEK where required
- Audit logging
- VPC Service Controls
- Retention policy if required

---

# 4. On-Premises to GCS Migration

## Recommended Architecture

```text
On-Prem Storage
      ↓
Storage Transfer Service Agent
      ↓
Private / Secure Connectivity
      ↓
Google Cloud Storage
```

Possible connectivity:

- Cloud VPN
- Cloud Interconnect
- Public internet with TLS
- Private Google Access where applicable

## Security Focus

- Encryption in transit
- Firewall controls
- Source authentication
- Dedicated migration identity
- Destination bucket IAM
- Logging
- Data integrity verification

---

# 5. Azure Event Hubs to BigQuery using Dataflow

## Architecture

```text
Azure Application
      ↓
Azure Event Hubs
      ↓
Dataflow
      ↓
Transformation
      ↓
BigQuery
```

Possible additional staging:

```text
Event Hubs
    ↓
Dataflow
    ↓
Pub/Sub
    ↓
Dataflow
    ↓
BigQuery
```

---

# 6. Event Hubs → Dataflow → BigQuery Practical Lab

## Tasks

1. Produce sample events to Azure Event Hubs
2. Configure authentication
3. Create Dataflow streaming pipeline
4. Connect to Event Hubs
5. Deserialize incoming messages
6. Validate schema
7. Transform records
8. Handle invalid events
9. Write valid data to BigQuery
10. Send malformed records to a dead-letter path
11. Monitor Dataflow metrics
12. Validate records in BigQuery

## Sample Event

```json
{
  "tracking_id": "FDX123456789",
  "event_type": "ARRIVED_AT_FACILITY",
  "location": "Toronto",
  "event_timestamp": "2026-09-11T10:30:00Z",
  "status": "IN_TRANSIT"
}
```

---

# 7. Apache Beam – Kafka to Pub/Sub / BigQuery

## Architecture Option A

```text
Kafka
  ↓
Apache Beam
  ↓
Pub/Sub
```

## Architecture Option B

```text
Kafka
  ↓
Apache Beam
  ↓
BigQuery
```

## Architecture Option C

```text
Kafka
  ↓
Apache Beam
  ↓
Pub/Sub
  ↓
Dataflow
  ↓
BigQuery
```

---

# 8. Beam Kafka Pipeline Concepts

Understand:

- `KafkaIO`
- `PubsubIO`
- `BigQueryIO`
- `PCollection`
- `ParDo`
- `DoFn`
- `Map`
- `Filter`
- Windowing
- Triggers
- Watermarks
- Checkpointing
- Dead-letter handling
- Exactly-once / at-least-once semantics
- Schema validation

---

# 9. Example Beam Flow

```text
Kafka Topic
   ↓
KafkaIO.read()
   ↓
Deserialize JSON
   ↓
Validate Event
   ↓
Transform
   ↓
PCollection
   ↓
 ┌─────────────┬──────────────┐
 ↓             ↓
Pub/Sub     BigQuery
```

---

# 10. Dataflow Security

## Identity

Run Dataflow using a dedicated Service Account.

Grant only required roles such as access to:

- Pub/Sub
- BigQuery
- GCS staging/temp buckets
- Logging
- Monitoring

Avoid broad roles such as:

```text
roles/editor
roles/owner
```

---

# 11. Dataflow Networking

## Recommended Enterprise Architecture

```text
Dataflow Workers
      │
      ├── Private IP only
      │
      ├── VPC Subnet
      │
      ├── Private Google Access
      │
      └── Controlled Egress
```

Prefer:

- No public IPs for workers
- Private IPs
- Private Google Access
- Dedicated subnet
- Firewall control
- Cloud NAT for required internet egress
- PSC/private service access where supported

---

# 12. Connecting Dataflow to External Sources

For sources such as Azure Event Hubs or external Kafka:

```text
Private Dataflow Workers
        ↓
Cloud NAT / VPN / Interconnect
        ↓
External Source
```

Potential designs:

### Internet-Based

```text
Dataflow
   ↓
Cloud NAT
   ↓
Internet
   ↓
Azure Event Hubs
```

### Private Enterprise Connectivity

```text
GCP VPC
   ↓
Cloud VPN / Interconnect
   ↓
Azure VNet / On-Prem
   ↓
Kafka / Event Hubs
```

---

# 13. Firewall Security

Only allow required:

- Source networks
- Destination networks
- Ports
- Protocols

Example:

```text
Dataflow Subnet
     ↓ TCP 9092
Kafka Cluster
```

Do not allow:

```text
0.0.0.0/0
```

unless absolutely necessary.

---

# 14. Pub/Sub Security

## Controls

- Dedicated publisher Service Account
- Dedicated subscriber Service Account
- Topic-level IAM
- Subscription-level IAM
- CMEK if required
- Message retention
- Dead-letter topic
- Retry policy
- Audit logging
- VPC Service Controls

## Example

```text
Producer SA
   ↓
Pub/Sub Topic
   ↓
Subscriber SA
   ↓
Dataflow
```

---

# 15. BigQuery Security

Apply:

- Dataset-level IAM
- Table-level IAM
- Row-level security
- Column-level security
- Policy Tags
- Authorized views
- CMEK
- Audit logs
- VPC Service Controls

Example:

```text
Raw Dataset
   ↓
Transformation
   ↓
Curated Dataset
   ↓
Analytics Dataset
```

---

# 16. Raw / Silver / Gold Data Model

Common data-lake terminology:

```text
RAW / BRONZE
Original unprocessed data

SILVER
Validated, cleaned, standardized data

GOLD
Business-ready aggregated data
```

Example:

```text
Kafka / Event Hubs
       ↓
Raw Events
       ↓
Dataflow Validation
       ↓
Silver Events
       ↓
Aggregation
       ↓
Gold Analytics
```

---

# 17. Data Validation

Validate:

- Schema
- Required fields
- Timestamp
- Data type
- Duplicate events
- Null values
- Invalid records
- Business rules

Example:

```text
Incoming Event
      ↓
Schema Validation
      ↓
 ┌───────────┐
Valid      Invalid
 ↓            ↓
BigQuery     DLQ
```

---

# 18. Dead-Letter Queue

Recommended design:

```text
Dataflow
   ↓
Validation
   ↓
 ┌───────────────┐
 │               │
Valid          Invalid
 ↓               ↓
BigQuery     Pub/Sub DLQ
```

Store:

- Original message
- Error reason
- Pipeline name
- Timestamp
- Source topic/partition

---

# 19. Monitoring and Observability

Monitor:

## Dataflow

- Worker CPU
- Throughput
- Backlog
- System lag
- Errors
- Failed bundles
- Autoscaling

## Pub/Sub

- Unacked messages
- Oldest unacked message
- Delivery latency
- Dead-letter messages

## BigQuery

- Failed insert jobs
- Query failures
- Slot utilization
- Dataset access

---

# 20. Logging Architecture

```text
Storage Transfer
Dataflow
Pub/Sub
BigQuery
Kafka
      ↓
Cloud Logging
      ↓
Log Router
      ↓
BigQuery / Pub/Sub / SIEM
```

---

# 21. Encryption

## At Rest

Use:

- Google-managed encryption by default
- CMEK for regulated workloads

## In Transit

Use:

- TLS
- VPN
- Interconnect
- Private connectivity

---

# 22. Secrets Management

Do not store:

- Event Hub connection strings
- Kafka credentials
- API tokens
- Passwords

inside source code.

Use:

```text
Secret Manager
      ↓
Dataflow / Pipeline
```

Where possible, prefer:

- Workload Identity
- Service Accounts
- Federation

over static credentials.

---

# 23. VPC Service Controls for Data Platforms

Protect services such as:

```text
Cloud Storage
BigQuery
Vertex AI
Secret Manager
```

Example:

```text
        VPC-SC
┌────────────────────────────┐
│                            │
│ GCS                        │
│ BigQuery                   │
│ Vertex AI                  │
│ Secret Manager             │
│                            │
└────────────────────────────┘
```

Use ingress/egress policies for approved external data movement.

---

# 24. Migration Security Checklist

Before migration:

- Classify data
- Identify PII
- Identify PCI/PHI
- Define residency requirements
- Design IAM
- Design encryption
- Design connectivity
- Define retention
- Enable logging

During migration:

- Validate authentication
- Monitor transfer
- Validate checksums
- Detect failed records
- Track migration metrics
- Protect staging data

After migration:

- Validate record count
- Validate integrity
- Remove temporary access
- Remove migration credentials
- Lock down destination
- Enable retention / lifecycle
- Document evidence

---

# 25. Migration Strategy

Use phases:

```text
DISCOVER
   ↓
ASSESS
   ↓
DESIGN
   ↓
PILOT
   ↓
MIGRATE
   ↓
VALIDATE
   ↓
CUTOVER
   ↓
OPTIMIZE
```

---

# 26. Important Interview Scenarios

## Scenario 1

**How would you migrate 100 TB from on-premises storage to GCS securely?**

Discuss:

- Storage Transfer Service
- Transfer Agent
- Network bandwidth
- VPN / Interconnect
- IAM
- Encryption
- Validation
- Incremental synchronization
- Cutover

---

## Scenario 2

**Azure Event Hubs needs to stream data into BigQuery.**

```text
Azure Event Hubs
      ↓
Dataflow
      ↓
Validation
      ↓
BigQuery
```

Discuss:

- Authentication
- Dataflow workers
- Private subnet
- NAT/VPN
- Secret Manager
- DLQ
- Monitoring
- IAM

---

## Scenario 3

**Kafka events must reach BigQuery.**

```text
Kafka
   ↓
Apache Beam
   ↓
Dataflow
   ↓
BigQuery
```

or:

```text
Kafka
   ↓
Apache Beam
   ↓
Pub/Sub
   ↓
Dataflow
   ↓
BigQuery
```

Discuss:

- KafkaIO
- PubsubIO
- BigQueryIO
- Schemas
- Streaming windows
- DLQ
- Security
- Networking

---

# 27. Practical Labs to Complete

## Lab 1

```text
Storage Transfer Service
Source → GCS
```

## Lab 2

```text
Event Hubs
   ↓
Dataflow
   ↓
BigQuery
```

## Lab 3

```text
Kafka
  ↓
Beam
  ↓
Pub/Sub
```

## Lab 4

```text
Kafka
  ↓
Beam / Dataflow
  ↓
BigQuery
```

## Lab 5

```text
Pub/Sub
   ↓
Dataflow
   ↓
BigQuery
   ↓
DLQ + Monitoring
```

---

# 28. Recommended Practical Order

```text
1. Storage Transfer Service
2. Pub/Sub → Dataflow → BigQuery
3. Kafka → Beam → Pub/Sub
4. Kafka → Beam → BigQuery
5. Azure Event Hubs → Dataflow → BigQuery
6. Private Dataflow Networking
7. DLQ + Retry Handling
8. IAM + Secret Manager
9. Monitoring + Alerting
10. VPC-SC for Data Services
```

---

# Final Architecture to Be Comfortable With

```text
                  ON-PREM / AZURE
                        │
            ┌───────────┴───────────┐
            │                       │
       Object Data             Streaming Data
            │                       │
            ▼                       ▼
 Storage Transfer Service     Event Hubs / Kafka
            │                       │
            ▼                       ▼
           GCS               Beam / Dataflow
            │                       │
            │                ┌──────┴───────┐
            │                ▼              ▼
            │             Pub/Sub        BigQuery
            │                │
            │                ▼
            │             Dataflow
            │                │
            └────────────────┴──────► BigQuery

SECURITY
──────────────────────────────────────────────
IAM
Service Accounts
Secret Manager
CMEK
VPC
Firewall
Cloud NAT
VPN / Interconnect
Private Google Access
VPC Service Controls
Cloud Logging
Cloud Monitoring
Security Command Center
```

The interview goal is not only to know the services, but to explain **why a specific migration pattern was chosen, how the network path works, how authentication works, how failures are handled, and how the data is protected end-to-end**.
