"""
CDR auto-response: disable an IAM access key flagged by GuardDuty.

1. Ignore GuardDuty sample findings (notify only).
2. Only act on IAM users whose name starts with ALLOWED_USER_PREFIX.
   Root, roles, and every other user are reported for manual review,
   so the responder can never lock out the admin or Terraform identities.
3. Set the access key to Inactive (reversible, nothing is deleted).
4. Email the alert topic with a summary.
"""
import json
import os

import boto3

iam = boto3.client("iam")
sns = boto3.client("sns")

TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]
ALLOWED_PREFIX = os.environ.get("ALLOWED_USER_PREFIX", "cdr-")


def notify(subject, body):
    sns.publish(TopicArn=TOPIC_ARN, Subject=subject[:100], Message=body)


def handler(event, context):
    finding = event["detail"]
    ftype = finding["type"]
    severity = finding["severity"]
    key = finding.get("resource", {}).get("accessKeyDetails", {})
    key_id = key.get("accessKeyId")
    user = key.get("userName")
    user_type = key.get("userType")
    is_sample = finding.get("service", {}).get("additionalInfo", {}).get("sample", False)

    print(json.dumps({"finding": ftype, "severity": severity, "user": user,
                      "userType": user_type, "keyId": key_id, "sample": is_sample}))

    if is_sample:
        notify(f"[CDR] Sample finding: {ftype}",
               f"GuardDuty sample finding for user {user} (severity {severity}).\n"
               "Pipeline works. No action taken because this is a sample.")
        return {"action": "none", "reason": "sample finding"}

    if user_type != "IAMUser" or not user or not key_id:
        notify(f"[CDR] Manual review: {ftype}",
               f"Identity type {user_type} ({user}) is not an IAM user key.\n"
               "No automatic action taken. Investigate manually.")
        return {"action": "none", "reason": "not an IAM user key"}

    if not user.startswith(ALLOWED_PREFIX):
        notify(f"[CDR] Out of scope: {user}",
               f"{ftype} on key {key_id} for user {user}.\n"
               f"User is outside the '{ALLOWED_PREFIX}' scope, so no action was taken.\n"
               "Manual review needed.")
        return {"action": "none", "reason": "out of scope"}

    iam.update_access_key(UserName=user, AccessKeyId=key_id, Status="Inactive")

    notify(f"[CDR] Disabled access key for {user}",
           f"Finding: {ftype}\nSeverity: {severity}\nUser: {user}\n"
           f"Access key {key_id} set to Inactive.\n\n"
           "To restore: investigate, rotate the key, then re-enable or delete it.")
    return {"action": "disabled", "user": user, "key": key_id}
