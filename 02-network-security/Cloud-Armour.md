# GCP Cloud Armor & WAF — Hands-On Interview Guide

## 1. What is Cloud Armor?

**Cloud Armor is Google Cloud's edge security service** used to protect applications exposed through supported Google Cloud load balancers.

Think of it as a security guard sitting **before your application**.

```text
Internet
   |
   | HTTP/HTTPS request
   v
+----------------------+
| External Load Balancer|
+----------------------+
          |
          v
+----------------------+
|     Cloud Armor      |
|                      |
| WAF                  |
| DDoS protection      |
| Rate limiting        |
| IP filtering         |
| Geo filtering        |
| Custom rules         |
+----------------------+
          |
          v
     Application
```

The important idea:

> **Cloud Armor tries to stop malicious traffic before it reaches the application backend.**

---

# 2. Why do we need Cloud Armor?

Without Cloud Armor:

```text
Attacker
   |
   v
Load Balancer
   |
   v
Application
   |
   v
Database
```

An attacker can send:

* SQL injection attempts
* XSS payloads
* malicious requests
* excessive requests
* suspicious IP traffic
* automated attacks
* application-layer floods

With Cloud Armor:

```text
Attacker
   |
   v
Load Balancer
   |
   v
Cloud Armor
   |
   +---- BLOCK ---> malicious request
   |
   v
Application
```

The application receives only requests that pass the configured security policy.

---

# 3. Cloud Armor vs WAF

These terms are related but not identical.

### Cloud Armor

Cloud Armor is the **Google Cloud security service**.

It provides capabilities such as:

* WAF
* DDoS protection
* rate limiting
* IP-based rules
* geographic rules
* custom security rules
* adaptive protection capabilities
* security policies

### WAF

WAF means:

> **Web Application Firewall**

A WAF specifically protects web applications from common application-layer attacks.

Examples:

* SQL injection
* XSS
* Local File Inclusion
* Remote File Inclusion
* command injection
* protocol attacks

So:

```text
Cloud Armor
   |
   +-- WAF
   +-- DDoS protection
   +-- Rate limiting
   +-- IP rules
   +-- Geo rules
   +-- Custom rules
```

---

# 4. Where does Cloud Armor sit?

A common architecture is:

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
Backend
```

For a Cloud Run application:

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
Serverless NEG
   |
   v
Cloud Run
```

The **Serverless NEG** connects the load balancer to Cloud Run.

An important security requirement is preventing users from simply bypassing the protected load balancer and accessing the backend directly.

For Cloud Run, this means configuring ingress appropriately so traffic is forced through the intended load-balancing path.

---

# 5. What is a Cloud Armor Security Policy?

A **security policy** contains the rules that determine whether a request should be allowed, denied, redirected, rate-limited, etc.

Conceptually:

```text
Cloud Armor Security Policy

Priority 1  -> Block malicious IP
Priority 2  -> Block SQL injection
Priority 3  -> Block XSS
Priority 4  -> Rate limit suspicious clients
Priority 5  -> Allow trusted traffic
Default      -> Allow
```

Rules are evaluated according to their priority.

A lower numerical priority is evaluated first.

For example:

```text
Priority 100
Priority 200
Priority 300
Priority 1000
Default
```

Priority `100` gets evaluated before `200`.

---

# 6. WAF — Web Application Firewall

WAF rules inspect HTTP requests and look for patterns associated with known attacks.

For example:

```http
POST /api/login
Content-Type: application/json

{
  "username": "' OR '1'='1",
  "password": "anything"
}
```

A WAF can detect patterns associated with SQL injection.

The important point:

> The WAF is inspecting the HTTP request, not simply looking at the source IP.

---

# 7. SQL Injection

## What is SQL Injection?

SQL injection occurs when an attacker manipulates application input so that it can influence a backend SQL query.

Imagine an unsafe application:

```text
SELECT * FROM users
WHERE username = '<username>'
AND password = '<password>';
```

A malicious user may provide:

```text
' OR '1'='1
```

Conceptually, the resulting SQL could become:

```sql
SELECT * FROM users
WHERE username = '' OR '1'='1'
AND password = '';
```

The attacker is trying to alter the intended SQL logic.

---

# 8. SQL Injection API Example

Suppose our API is:

```http
POST /api/login
```

Normal request:

```json
{
  "username": "devraj",
  "password": "mypassword"
}
```

Malicious test request:

```json
{
  "username": "' OR '1'='1",
  "password": "anything"
}
```

Or a URL/query-string example:

```text
/api/users?id=1' OR '1'='1
```

The WAF examines the request and can identify SQL-injection patterns.

When the relevant WAF rule is configured in **enforcement mode**, Cloud Armor can reject the request before it reaches the backend.

---

# 9. What actually happens during the SQL Injection test?

The flow is:

```text
Attacker
   |
   | POST /api/login
   | username=' OR '1'='1
   v
Load Balancer
   |
   v
Cloud Armor
   |
   | Inspect request
   |
   | SQLi pattern detected
   |
   X
   |
 BLOCK
```

The request does **not need to reach the application** for Cloud Armor to block it.

That is one of the major advantages of edge WAF protection.

---

# 10. OWASP and Preconfigured WAF Rules

Cloud Armor provides **preconfigured WAF rules** based on the OWASP Core Rule Set (CRS) concepts.

These rules are designed to detect common web attacks.

Important categories to understand:

### SQL Injection

```text
SQLi
```

Attempts to manipulate SQL queries.

### Cross-Site Scripting

```text
XSS
```

Attempts to inject executable browser-side content.

Example concept:

```html
<script>alert(1)</script>
```

### Local File Inclusion

```text
LFI
```

Attempts to access local files through application input.

Example concept:

```text
../../../../etc/passwd
```

### Remote File Inclusion

```text
RFI
```

Attempts to make an application load content from a remote location.

### Remote Code Execution / Command Injection

Attempts to cause the application or underlying system to execute unintended commands.

---

# 11. XSS Example

Suppose an API accepts:

```json
{
  "comment": "<script>alert('XSS')</script>"
}
```

The WAF can inspect the request for XSS signatures.

Conceptually:

```text
Client
  |
  v
Cloud Armor
  |
  | XSS pattern detected
  |
  X
BLOCK
```

Again, this is an **application-layer attack**, not simply a network-layer attack.

---

# 12. LFI Example

An attacker may try:

```text
/api/file?name=../../../../etc/passwd
```

The intention is to escape the intended application directory and access a local file.

A WAF rule can inspect the request for patterns associated with LFI.

---

# 13. WAF Detection vs Application Validation

This is very important in interviews.

Cloud Armor should **not be considered a replacement for secure application development**.

You want multiple layers:

```text
Cloud Armor WAF
      |
      v
Application validation
      |
      v
Parameterized SQL
      |
      v
Database
```

For SQL injection:

### Bad

```text
String concatenation
        +
User input
        =
SQL query
```

### Good

```text
User input
    |
    v
Parameterized query
    |
    v
Database
```

Cloud Armor provides an additional defensive layer.

---

# 14. Preview Mode vs Enforcement Mode

This is one of the most important Cloud Armor concepts.

## Preview

The rule is evaluated, but the request is not blocked by that rule.

Conceptually:

```text
Request
   |
   v
WAF rule
   |
   | MATCH
   |
   v
ALLOW
   |
   v
Backend
```

But the match is logged.

This is extremely useful when introducing WAF rules into production.

---

## Enforcement

The rule actively takes the configured action.

For example:

```text
Request
   |
   v
WAF
   |
   | MATCH
   |
   X
 DENY
```

---

# 15. Why use Preview first?

A legitimate request can sometimes resemble an attack.

For example:

```text
search?q=select
```

may be perfectly legitimate.

A poorly tuned rule could generate false positives.

Therefore:

```text
Deploy rule
     |
     v
Preview
     |
     v
Observe logs
     |
     v
Tune rule
     |
     v
Enforce
```

This is a strong senior-level answer.

---

# 16. WAF Rule Tuning

WAF rules may generate false positives.

For example:

```text
Legitimate API request
        |
        v
WAF
        |
        | Looks suspicious
        v
False positive
```

Instead of immediately disabling the WAF, investigate:

* Which rule matched?
* Which request field matched?
* Which attack signature matched?
* Is the traffic legitimate?
* Can the rule be scoped?
* Can specific signatures be excluded?
* Can the rule be moved to preview?

This is called **WAF tuning**.

---

# 17. Rule Priorities

Example:

```text
Priority 100
Block malicious IP

Priority 200
Allow trusted partner

Priority 300
Block SQL injection

Priority 400
Block XSS

Priority 500
Rate limit API

Default
Allow
```

Cloud Armor evaluates the rules according to priority.

Interview question:

> Why is rule priority important?

Answer:

> Because multiple rules can potentially match the same request. Cloud Armor evaluates the policy in priority order, so rule ordering determines which action is applied.

---

# 18. IP-Based Blocking

Cloud Armor can also block specific IP addresses or IP ranges.

Example:

```text
203.0.113.10
```

If that source is known to be malicious:

```text
Source IP
   |
   v
Cloud Armor
   |
   | IP matches deny rule
   |
   X
BLOCK
```

This is different from WAF inspection.

WAF:

```text
"What does the request contain?"
```

IP rule:

```text
"Who is sending the request?"
```

---

# 19. Allowlisting

You can also allow trusted traffic.

For example:

```text
Corporate IP range
       |
       v
Cloud Armor
       |
       v
ALLOW
```

However, be careful with broad allow rules.

A senior engineer should ask:

* Is the IP range stable?
* Is it behind NAT?
* Can the source be spoofed?
* Does this bypass WAF protections?
* Is the allow rule too broad?

---

# 20. Geographic Rules

Cloud Armor can use geographic information about the source.

Conceptually:

```text
Request
   |
   v
Cloud Armor
   |
   +--> Country A --> ALLOW
   |
   +--> Country B --> DENY
```

This can be useful when an application legitimately operates only in certain geographic regions.

But geo-blocking should not be treated as a complete security control.

---

# 21. Rate Limiting

WAF protects against malicious **content**.

Rate limiting protects against excessive **request volume**.

Example:

```text
Client
  |
  | 10,000 requests/sec
  v
Cloud Armor
  |
  | Rate limit exceeded
  |
  X
BLOCK / THROTTLE
```

Example API:

```text
POST /api/login
```

An attacker may repeatedly call:

```text
/api/login
/api/login
/api/login
/api/login
...
```

Even if every request is syntactically valid.

The problem is **volume**, not necessarily malicious payload content.

---

# 22. WAF vs Rate Limiting

| Protection      | Main purpose                     |
| --------------- | -------------------------------- |
| WAF             | Detect malicious request content |
| Rate limiting   | Control excessive request volume |
| IP deny rule    | Block known sources              |
| Geo rule        | Control geographic access        |
| DDoS protection | Mitigate large-scale attacks     |

Real applications commonly use multiple controls together.

---

# 23. DDoS Protection

DDoS means:

> **Distributed Denial of Service**

The attacker attempts to overwhelm a service with huge amounts of traffic.

```text
Attacker 1 ----\
Attacker 2 -----\
Attacker 3 ------> Load Balancer -> Application
Attacker 4 -----/
Attacker 5 ----/
```

The objective is usually:

```text
Exhaust:
- bandwidth
- connections
- CPU
- memory
- application resources
```

---

# 24. Network-Layer vs Application-Layer Attacks

This distinction is important.

### Network/transport attack

Examples:

```text
L3/L4 DDoS
```

Targets network or transport resources.

### Application-layer attack

Examples:

```text
HTTP flood
SQL injection
XSS
API abuse
```

Cloud Armor provides protection mechanisms for traffic reaching supported Google Cloud load-balancing architectures, while Google's broader network infrastructure also provides large-scale DDoS defenses.

Interview answer:

> Cloud Armor is not simply a firewall. It provides application-layer protections such as WAF and rate limiting, while Google Cloud's edge/network infrastructure provides DDoS resilience.

---

# 25. HTTP Flood

An attacker might send:

```text
GET /api/products
GET /api/products
GET /api/products
GET /api/products
...
```

Every request could technically be valid.

But thousands or millions of requests can consume application resources.

Therefore:

```text
WAF
+
Rate limiting
+
DDoS protection
```

are complementary.

---

# 26. Adaptive Protection

Cloud Armor also provides advanced protection capabilities that can help identify unusual application traffic patterns.

Conceptually:

```text
Normal traffic
      |
      v
Baseline

Sudden abnormal behavior
      |
      v
Detection
      |
      v
Security recommendation / mitigation
```

This is useful because not every attack can be predicted by a static rule.

---

# 27. Logging

Security controls are only useful if you can investigate what happened.

When testing WAF rules, inspect load-balancer/Cloud Armor-related logs.

You want to answer:

```text
Who?
 |
 +-- source IP

What?
 |
 +-- URL
 +-- HTTP method
 +-- request characteristics

Why?
 |
 +-- matched security rule

Action?
 |
 +-- allow
 +-- deny
 +-- rate limited
```

---

# 28. WAF Troubleshooting Workflow

When a legitimate request is blocked:

```text
1. Check Cloud Armor logs
          |
          v
2. Identify matched rule
          |
          v
3. Identify signature/category
          |
          v
4. Reproduce request
          |
          v
5. Determine false positive
          |
          v
6. Tune/exclude/scoped rule
          |
          v
7. Test again
```

Never immediately disable the entire WAF.

---

# 29. How I Tested SQL Injection

The hands-on learning flow was:

```text
Normal API request
        |
        v
Confirm API works
        |
        v
Create SQLi test payload
        |
        v
Send malicious request
        |
        v
Cloud Armor WAF
        |
        v
Rule matches
        |
        v
Request denied
        |
        v
Check logs
```

This is much better for an interview than simply saying:

> "I know Cloud Armor."

You can explain the complete request lifecycle.

---

# 30. Security Policy Mental Model

Remember:

```text
                Cloud Armor
                     |
        +------------+------------+
        |            |            |
       WAF       Rate Limit      IP Rules
        |            |            |
      SQLi         Abuse        Bad IP
       XSS        Flooding      Allowlist
       LFI
       RFI
```

---

# 31. Cloud Armor vs Traditional Firewall

A network firewall generally thinks about:

```text
Source IP
Destination IP
Protocol
Port
```

Example:

```text
10.0.0.0/8 -> TCP/443 -> ALLOW
```

Cloud Armor WAF thinks more about:

```text
HTTP request
    |
    +-- URL
    +-- headers
    +-- parameters
    +-- request body
    +-- attack signatures
```

Therefore:

> **Firewall controls network traffic; WAF controls malicious web/application traffic.**

They complement each other.

---

# 32. Cloud Armor vs Apigee

This is a common interview question.

### Cloud Armor

Security at the edge:

```text
WAF
DDoS
Rate limiting
IP filtering
Geo controls
```

### Apigee

API management:

```text
API products
API consumers
OAuth/API keys
quotas
developer portal
API analytics
API policies
API lifecycle
```

Simple mental model:

```text
Cloud Armor
   =
"Is this request dangerous?"

Apigee
   =
"Is this API consumer allowed to use this API, and how?"
```

They can be used together.

---

# 33. Example Production Architecture

```text
                    INTERNET
                       |
                       v
              +----------------+
              | Global External|
              | HTTPS LB        |
              +----------------+
                       |
                       v
              +----------------+
              | Cloud Armor    |
              |                |
              | WAF             |
              | DDoS            |
              | Rate limiting   |
              | IP rules        |
              +----------------+
                       |
                       v
                 Serverless NEG
                       |
                       v
                   Cloud Run
                       |
                       v
                    GKE/API
                       |
                       v
                  Cloud SQL
```

Depending on the architecture, Apigee can also be introduced for API-management requirements.

---

# 34. Defense in Depth

Cloud Armor should be one layer of security, not the only layer.

A strong GCP architecture can look like:

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
                GKE / Cloud Run
                   |
          +--------+--------+
          |                 |
          v                 v
       IAM/WIF         Network Policy
          |
          v
       Service Account
          |
          v
       Cloud SQL
          |
          v
    PSA / PSC private path
```

Security controls are layered.

---

# 35. Important Interview Questions

## Q1. What is Cloud Armor?

> Cloud Armor is Google Cloud's edge security service that provides WAF, DDoS protection, rate limiting, IP/geo-based controls and custom security policies for supported load-balancing architectures.

---

## Q2. What is WAF?

> A Web Application Firewall inspects web requests and protects applications against common application-layer attacks such as SQL injection and XSS.

---

## Q3. Give an example of SQL injection.

Example:

```json
{
  "username": "' OR '1'='1",
  "password": "anything"
}
```

The attacker is attempting to manipulate the application's SQL logic.

---

## Q4. Does Cloud Armor replace secure coding?

**No.**

You still need:

* parameterized queries
* input validation
* output encoding
* authentication
* authorization
* secure application design

Cloud Armor is an additional security layer.

---

## Q5. What is preview mode?

> Preview mode evaluates the rule and logs matches without enforcing the configured deny action, making it useful for testing and tuning WAF policies before production enforcement.

---

## Q6. Why is WAF tuning necessary?

> Because legitimate requests can sometimes match attack signatures. We use logs and preview mode to identify false positives and tune the policy without unnecessarily blocking valid users.

---

## Q7. WAF vs DDoS?

> WAF primarily protects against malicious application-layer request patterns, while DDoS protection addresses large-scale traffic and availability attacks. Rate limiting helps control excessive request volume.

---

## Q8. Why put Cloud Armor in front of Cloud Run?

> It allows the application to receive protection such as WAF, rate limiting and edge security before traffic reaches Cloud Run. The backend should also be configured so users cannot bypass the protected load-balancing path through the direct Cloud Run endpoint.

---

## Q9. What happens if users can directly access the backend?

You can have:

```text
Internet
   |
   +---------> Cloud Armor -> LB -> Backend
   |
   +---------> Direct Backend
```

The second path can bypass Cloud Armor.

A secure design should eliminate that bypass where appropriate.

---

# 36. Senior Consultant Answer

If asked:

> "How would you secure a public GCP application?"

A strong answer:

> "I would first expose the application through a supported external HTTPS load-balancing architecture and put Cloud Armor at the edge. I would configure WAF protections for common application attacks such as SQL injection and XSS, use preview mode initially to identify false positives, then move validated rules into enforcement. I would add rate limiting for API abuse and use appropriate IP or geographic controls where required. I would also ensure the backend cannot bypass the protected load-balancing path. Behind that, I would use IAM, workload identity, network controls, private service connectivity and secure database authentication. Finally, I would enable logging and monitoring so security events can be investigated."

That demonstrates **architecture + security + operations**, rather than just product knowledge.

---

# 37. Most Important Things to Remember

### Cloud Armor

```text
EDGE SECURITY
```

### WAF

```text
WEB APPLICATION ATTACK PROTECTION
```

### SQL Injection

```text
Manipulate SQL through application input
```

### XSS

```text
Inject malicious browser-side content
```

### Rate Limiting

```text
Control excessive request volume
```

### DDoS

```text
Protect service availability from traffic attacks
```

### Preview

```text
Detect + log, don't enforce
```

### Enforcement

```text
Detect + take configured action
```

### WAF tuning

```text
Reduce false positives without removing protection
```

### Defense in depth

```text
Cloud Armor
+
Application security
+
IAM
+
Network security
+
Private connectivity
+
Logging/monitoring
```

---

# 38. The One-Line Mental Model

Remember this for the interview:

> **Cloud Armor protects the application at the edge; WAF identifies malicious web requests, rate limiting controls abusive request volume, DDoS protection helps maintain availability, and security policies determine what traffic is allowed or denied.**

---

# 39. Hands-On Achievement

The important part of this lab was not simply creating a Cloud Armor policy.

The practical flow was:

```text
Create application
       |
       v
Expose through Load Balancer
       |
       v
Attach Cloud Armor
       |
       v
Configure WAF
       |
       v
Test legitimate request
       |
       v
Test malicious SQLi payload
       |
       v
Observe WAF match
       |
       v
Request denied
       |
       v
Review logs
       |
       v
Understand why it was blocked
```

This is the level of understanding you should describe in a senior GCP security interview.
