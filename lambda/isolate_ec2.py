"""
CDR auto-response: isolate an EC2 instance flagged by GuardDuty.

1. Ignore GuardDuty sample findings (notify only).
2. Only act on instances tagged Project=cloud-detection-response.
3. Swap all security groups for the no-traffic quarantine group.
4. Snapshot every attached volume for forensics.
5. Tag the instance with what happened and its previous security groups.
6. Email the alert topic with a summary.
"""
import json
import os

import boto3

ec2 = boto3.client("ec2")
sns = boto3.client("sns")

QUARANTINE_SG = os.environ["QUARANTINE_SG_ID"]
TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]
PROJECT_TAG = "cloud-detection-response"


def notify(subject, body):
    sns.publish(TopicArn=TOPIC_ARN, Subject=subject[:100], Message=body)


def handler(event, context):
    finding = event["detail"]
    ftype = finding["type"]
    severity = finding["severity"]
    instance_id = finding["resource"]["instanceDetails"]["instanceId"]
    is_sample = finding.get("service", {}).get("additionalInfo", {}).get("sample", False)

    print(json.dumps({"finding": ftype, "severity": severity,
                      "instance": instance_id, "sample": is_sample}))

    if is_sample:
        notify(f"[CDR] Sample finding: {ftype}",
               f"GuardDuty sample finding for {instance_id} (severity {severity}).\n"
               "Pipeline works. No action taken because this is a sample.")
        return {"action": "none", "reason": "sample finding"}

    reservations = ec2.describe_instances(InstanceIds=[instance_id])["Reservations"]
    instance = reservations[0]["Instances"][0]
    tags = {t["Key"]: t["Value"] for t in instance.get("Tags", [])}

    if tags.get("Project") != PROJECT_TAG:
        notify(f"[CDR] Out of scope: {instance_id}",
               f"{ftype} on {instance_id}, which is not part of this project.\n"
               "No action taken. Manual review needed.")
        return {"action": "none", "reason": "out of scope"}

    if tags.get("cdr-status") == "quarantined":
        return {"action": "none", "reason": "already quarantined"}

    old_sgs = [g["GroupId"] for g in instance["SecurityGroups"]]
    ec2.modify_instance_attribute(InstanceId=instance_id, Groups=[QUARANTINE_SG])

    snapshots = []
    for mapping in instance.get("BlockDeviceMappings", []):
        volume_id = mapping["Ebs"]["VolumeId"]
        snap = ec2.create_snapshot(
            VolumeId=volume_id,
            Description=f"CDR forensic snapshot of {instance_id} ({ftype})"[:255],
            TagSpecifications=[{
                "ResourceType": "snapshot",
                "Tags": [
                    {"Key": "Project", "Value": PROJECT_TAG},
                    {"Key": "cdr-evidence-for", "Value": instance_id},
                ],
            }],
        )
        snapshots.append(snap["SnapshotId"])

    ec2.create_tags(Resources=[instance_id], Tags=[
        {"Key": "cdr-status", "Value": "quarantined"},
        {"Key": "cdr-finding", "Value": ftype[:255]},
        {"Key": "cdr-previous-sgs", "Value": ",".join(old_sgs)},
    ])

    notify(f"[CDR] Quarantined {instance_id}",
           f"Finding: {ftype}\nSeverity: {severity}\nInstance: {instance_id}\n"
           f"Previous security groups: {', '.join(old_sgs)}\n"
           f"Now in quarantine group: {QUARANTINE_SG}\n"
           f"Forensic snapshots: {', '.join(snapshots) or 'none'}\n\n"
           "To restore: investigate first, then run terraform apply.")
    return {"action": "quarantined", "instance": instance_id, "snapshots": snapshots}
