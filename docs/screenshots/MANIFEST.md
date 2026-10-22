# Screenshot index

Every file here was renamed from its original capture and checked for
sensitive data. Blurred everywhere it appeared: the AWS account number,
public IPs, the alert email address, and access key IDs.

**README** marks the images embedded in the main README.

## Phase 1 — Baseline

| File | Shows | |
|---|---|---|
| `p1-02-network-plan-11-to-add.png` | network plan 11 to add | **README** |
| `p1-03-network-apply-11-added.png` | network apply 11 added |  |
| `p1-04-cdr-vpc-console.png` | cdr vpc console |  |
| `p1-05-incident-iam-policy-quota-exceeded.png` | incident iam policy quota exceeded |  |
| `p1-06-cdr-terraform-group-2-policies.png` | cdr terraform group 2 policies |  |
| `p1-07-logging-plan-10-to-add.png` | logging plan 10 to add |  |
| `p1-08-logging-apply-trail-flowlog.png` | logging apply trail flowlog |  |
| `p1-09-cloudtrail-digests-all-regions.png` | cloudtrail digests all regions | **README** |
| `p1-10-trail-islogging-true.png` | trail islogging true |  |
| `p1-11-compute-plan-3-to-add.png` | compute plan 3 to add |  |
| `p1-12-cdr-terraform-group-3-policies.png` | cdr terraform group 3 policies |  |
| `p1-13-compute-apply-first-attempt.png` | compute apply first attempt |  |
| `p1-14-compute-apply-rsa-key.png` | compute apply rsa key |  |
| `p1-15-ssh-public-web-login.png` | ssh public web login |  |
| `p1-16-private-app-hop-curl-timeout.png` | private app hop curl timeout | **README** |
| `p1-17-ec2-instances-running.png` | ec2 instances running |  |
| `p1-18-flow-log-files-arriving.png` | flow log files arriving |  |

## Phase 2 — Automated response

| File | Shows | |
|---|---|---|
| `p2-01-cdr-terraform-group-4-policies.png` | cdr terraform group 4 policies |  |
| `p2-02-lambda-boundary-json.png` | lambda boundary json |  |
| `p2-03-response-plan-10-to-add.png` | response plan 10 to add |  |
| `p2-04-response-apply-complete.png` | response apply complete |  |
| `p2-05-sns-subscription-confirmation.png` | sns subscription confirmation |  |
| `p2-06-fire-sample-finding.png` | fire sample finding |  |
| `p2-07-guardduty-sample-finding.png` | guardduty sample finding |  |
| `p2-08-lambda-logs-after-clock-fix.png` | lambda logs after clock fix |  |
| `p2-09-sample-finding-email.png` | sample finding email | **README** |
| `p2-10-sample-via-eventbridge-email.png` | sample via eventbridge email |  |
| `p2-11-lambda-invocation-metrics.png` | lambda invocation metrics |  |
| `p2-12-decoy-dns-lookups.png` | decoy dns lookups | **README** |
| `p2-13-quarantine-email-HERO.png` | quarantine email HERO | **README** |
| `p2-14-quarantine-sg-only.png` | quarantine sg only | **README** |
| `p2-15-forensic-snapshot.png` | forensic snapshot | **README** |
| `p2-16-real-finding-details.png` | real finding details |  |
| `p2-17-ssh-timeout-quarantined.png` | ssh timeout quarantined | **README** |
| `p2-18-quarantine-tags.png` | quarantine tags | **README** |
| `p2-19-findings-archived.png` | findings archived | **README** |
| `p2-20-restore-plan-1-to-change.png` | restore plan 1 to change | **README** |
| `p2-21-incident-restore-denied.png` | incident restore denied | **README** |
| `p2-22-compute-policy-updated.png` | compute policy updated |  |
| `p2-23-restore-apply-complete.png` | restore apply complete |  |
| `p2-24-responders-plan-16-to-add.png` | responders plan 16 to add |  |
| `p2-25-responders-apply-16-added.png` | responders apply 16 added |  |
| `p2-26-test-bucket-locked-before.png` | test bucket locked before |  |
| `p2-27-test-bucket-unlocked.png` | test bucket unlocked |  |
| `p2-28-iam-sample-finding-email.png` | iam sample finding email |  |
| `p2-29-key-out-of-scope-email.png` | key out of scope email | **README** |
| `p2-30-test-user-key-active.png` | test user key active |  |
| `p2-31-test-user-key-inactive.png` | test user key inactive | **README** |
| `p2-32-key-disabled-email.png` | key disabled email |  |
| `p2-33-findings-resourcetype-accesskey.png` | findings resourcetype accesskey |  |
| `p2-34-eventbridge-rule-fix.png` | eventbridge rule fix |  |
| `p2-35-rule-fix-plan.png` | rule fix plan |  |
| `p2-36-test-bucket-unlocked-retest.png` | test bucket unlocked retest |  |
| `p2-37-s3-relock-email.png` | s3 relock email |  |
| `p2-38-s3-relocked-all-true.png` | s3 relocked all true | **README** |
| `p2-39-lock-s3-lambda-logs.png` | lock s3 lambda logs |  |

## Phase 3 — Zero Trust

| File | Shows | |
|---|---|---|
| `p3-01-incident-adminwithmfa-explicit-deny.png` | incident adminwithmfa explicit deny | **README** |
| `p3-02-endpoints-back-on-apply.png` | endpoints back on apply |  |
| `p3-03-fleet-manager-both-online.png` | fleet manager both online |  |
| `p3-04-ssh-timeout-zero-trust.png` | ssh timeout zero trust | **README** |
| `p3-05-ssm-private-app-dnf-via-s3.png` | ssm private app dnf via s3 | **README** |
| `p3-06-strip-profile-plan.png` | strip profile plan |  |
| `p3-07-decoy-via-session-manager.png` | decoy via session manager |  |
| `p3-08-real-finding-again.png` | real finding again |  |
| `p3-09-quarantined-no-iam-role.png` | quarantined no iam role | **README** |
| `p3-10-quarantine-tags-previous-profile.png` | quarantine tags previous profile | **README** |
| `p3-11-ssm-denied-no-instance-role.png` | ssm denied no instance role | **README** |
| `p3-12-fleet-manager-connection-lost.png` | fleet manager connection lost |  |
| `p3-13-restored-role-and-zt-sg.png` | restored role and zt sg |  |
| `p3-14-restored-tags.png` | restored tags |  |

## Not captured

- The first `terraform init` against the S3 backend (Oct 12)
- The Oct 20 evening Phase 3 session: the `terraform plan` removing the SSH
  rules (included in the README as a text excerpt from the real output),
  the CloudTrail `ConsoleLogin` event showing `MFAUsed: Yes`, and the
  AdminWithMFA before/after JSON
