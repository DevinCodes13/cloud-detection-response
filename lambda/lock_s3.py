"""
CDR auto-response: re-enable S3 Block Public Access flagged by GuardDuty.

1. Ignore GuardDuty sample findings (notify only).
2. Only act on buckets whose name starts with ALLOWED_BUCKET_PREFIX.
3. Turn all four Block Public Access settings back on.
4. Email the alert topic with a summary.
"""
import json
import os

import boto3

s3 = boto3.client("s3")
sns = boto3.client("sns")

TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]
ALLOWED_PREFIX = os.environ.get("ALLOWED_BUCKET_PREFIX", "cdr-")


def notify(subject, body):
    sns.publish(TopicArn=TOPIC_ARN, Subject=subject[:100], Message=body)


def handler(event, context):
    finding = event["detail"]
    ftype = finding["type"]
    severity = finding["severity"]
    buckets = [b.get("name") for b in finding.get("resource", {}).get("s3BucketDetails", [])]
    is_sample = finding.get("service", {}).get("additionalInfo", {}).get("sample", False)

    print(json.dumps({"finding": ftype, "severity": severity,
                      "buckets": buckets, "sample": is_sample}))

    if is_sample:
        notify(f"[CDR] Sample finding: {ftype}",
               f"GuardDuty sample finding for bucket(s) {buckets} (severity {severity}).\n"
               "Pipeline works. No action taken because this is a sample.")
        return {"action": "none", "reason": "sample finding"}

    locked, skipped = [], []
    for name in buckets:
        if not name or not name.startswith(ALLOWED_PREFIX):
            skipped.append(name)
            continue
        s3.put_public_access_block(
            Bucket=name,
            PublicAccessBlockConfiguration={
                "BlockPublicAcls": True,
                "IgnorePublicAcls": True,
                "BlockPublicPolicy": True,
                "RestrictPublicBuckets": True,
            },
        )
        locked.append(name)

    notify(f"[CDR] S3 response: {ftype}",
           f"Finding: {ftype}\nSeverity: {severity}\n"
           f"Re-locked (Block Public Access on): {', '.join(locked) or 'none'}\n"
           f"Out of scope, manual review: {', '.join(str(s) for s in skipped) or 'none'}")
    return {"action": "locked", "locked": locked, "skipped": skipped}
