# Cloud Detection & Response — architecture

How a threat moves from "something happened" to "it's contained," and where
each piece lives.

```mermaid
flowchart LR
  subgraph VPC["VPC 10.0.0.0/16 · us-east-1a"]
    direction TB
    subgraph PUB["Public subnet 10.0.1.0/24"]
      WEB["cdr-public-web<br/>no inbound · 443 out<br/>IMDSv2 · encrypted EBS"]
    end
    subgraph PRIV["Private subnet 10.0.2.0/24 · no internet route"]
      APP["cdr-private-app<br/>no inbound · 443 to endpoints only"]
      EP["Interface endpoints<br/>ssm · ssmmessages · ec2messages"]
      S3EP["S3 gateway endpoint"]
      APP --> EP
      APP --> S3EP
    end
    QSG["cdr-quarantine SG<br/>no rules at all"]
  end

  subgraph TELEMETRY["Telemetry"]
    CT["CloudTrail<br/>multi-region · validated"]
    FL["VPC Flow Logs"]
    DNS["DNS query logs"]
    LOGS[("cdr-logs bucket<br/>versioned · encrypted · HTTPS-only")]
  end

  GD{{"GuardDuty"}}
  EB["EventBridge rules"]

  subgraph RESPONDERS["Lambda responders · each capped by CDR-Lambda-Boundary"]
    ISO["cdr-isolate-ec2"]
    KEY["cdr-disable-keys"]
    LOCK["cdr-lock-s3"]
  end

  SNS["SNS cdr-alerts"] --> MAIL["Email report"]
  ADMIN["Admin (IAM + MFA)"] -->|Session Manager| EP
  ADMIN -->|Session Manager| WEB

  VPC -.-> FL
  CT --> LOGS
  FL --> LOGS
  CT --> GD
  FL --> GD
  DNS --> GD
  GD -->|findings| EB
  EB -->|EC2, severity ≥ 4| ISO
  EB -->|AccessKey, severity ≥ 4,<br/>not Policy:S3/*| KEY
  EB -->|Policy:S3/*| LOCK

  ISO -->|swap SGs, strip IAM role,<br/>snapshot, tag| QSG
  KEY -->|key → Inactive| IAMKEY["IAM access key<br/>(cdr-* users only)"]
  LOCK -->|Block Public Access on| BUCKET["S3 bucket<br/>(cdr-* only)"]
  ISO --> SNS
  KEY --> SNS
  LOCK --> SNS
```

## Notes

- **Everything the responders touch is scoped twice** — once in the Python
  (`Project` tag or `cdr-` prefix) and once in the role's IAM policy.
- **The quarantine security group has no rules**, so a quarantined instance
  can send and receive nothing new. Removing the instance profile at the
  same time takes away its AWS credentials.
- **Session Manager connections are outbound from the instance.** No arrow
  points *into* either server from the internet.
- The interface endpoints cost money while they exist and are toggled with
  `enable_ssm_endpoints`; the S3 gateway endpoint is free and always on.
