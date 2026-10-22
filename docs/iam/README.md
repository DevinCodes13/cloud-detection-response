# IAM policies managed outside Terraform

These policies are the guardrails *on* the Terraform user, so they were
created by an MFA-authenticated administrator in the console rather than by
Terraform itself. A tool should not be able to write its own permissions.

Placeholders to replace before use: `<ACCOUNT_ID>`, `<CDR_VPC_ID>` (exists
only after the first `terraform apply`), and `<SUFFIX>` (the state bucket's
random suffix).

| Policy | Attached to | Purpose |
|---|---|---|
| `CDR-Terraform-State` | `CDR-Terraform` group | Read/write this project's state under `cdr/` only |
| `CDR-Terraform-Logging` | `CDR-Terraform` group | `cdr-*` buckets and trails, Flow Logs, GuardDuty detector |
| `CDR-Terraform-Compute` | `CDR-Terraform` group | Launch and manage only `Project`-tagged instances; SG swaps only inside this VPC; tag rules that keep the `Project` fence intact |
| `CDR-Terraform-Response` | `CDR-Terraform` group | Lambdas, EventBridge, SNS, and role creation **only** with a boundary attached; `PassRole` split by service |
| `CDR-Lambda-Boundary` | Nothing — used as a permissions boundary | The ceiling on every responder role |
| `CDR-EC2-Boundary` | Nothing — used as a permissions boundary | The ceiling on the instance role: Session Manager and nothing else |
| `AdminWithMFA` | The IAM administrator | Deny everything without MFA; deny everyone the ability to stop CloudTrail or delete GuardDuty |

## Notes

- The Terraform user also carries policies from the earlier VulnTrack
  project that cover general VPC and security-group creation. A fresh
  account would need equivalent `ec2:CreateVpc`, `CreateSubnet`,
  `CreateSecurityGroup` (and related) permissions, ideally added to the
  same group and scoped the same way.
- `AdminWithMFA` replaces an earlier version whose deny statement had no
  MFA condition at all — see the troubleshooting log in the main README.
