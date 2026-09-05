# Logging and Monitoring

## Definition

Observability provides evidence about what happened, whether the system is healthy, and whether activity is suspicious. Security monitoring combines logs, metrics, alerts, and investigation workflows.

## GCP resource mapping

| Security concept | GCP resource or service | Practical use |
|---|---|---|
| Centralized logs | Cloud Logging | Search, route, retain, and analyze logs |
| Administrative evidence | Admin Activity Audit Logs | See changes to project and resources |
| Data access evidence | Data Access Audit Logs | Track access to data where enabled |
| Metrics and dashboards | Cloud Monitoring | Track health, capacity, and security signals |
| Detection findings | Security Command Center | Aggregate posture and threat findings |
| Alerting | Monitoring alert policies and notification channels | Notify on suspicious or unhealthy behavior |
| Long-term evidence | Log buckets and sinks | Route logs to dedicated storage or analysis |
| Investigation | Logs Explorer and Cloud Asset Inventory | Examine events and resource state |

## Rules to practice

- Decide what must be retained before configuring sinks.
- Protect log buckets from unauthorized deletion or broad access.
- Alert on high-risk events such as IAM policy changes and public exposure.
- Use labels and structured application logs so incidents are searchable.
- Treat logs as sensitive data.

## Lab outcome

Create a dashboard and alert for a meaningful signal, then verify that an administrative change appears in Audit Logs.
