#!/usr/bin/env bash
REGION=$(ec2-metadata --availability-zone | sed -n 's/.*placement: \([a-zA-Z-]*[0-9]\).*/\1/p');
echo "region:$REGION"

catch_error () {
    INSTANCE_ID=$(ec2-metadata --instance-id | sed -n 's/.*instance-id: \(i-[a-f0-9]\{17\}\).*/\1/p')
    echo "An error occurred: $1"
    aws sns publish --topic-arn "arn:aws:sns:$REGION:992382682634:errors" --message "$1" --subject "$INSTANCE_ID" --region $REGION
}
main () {
    set -euxo pipefail
    echo "Start user data"
    REGION=$(ec2-metadata --availability-zone | sed -n 's/.*placement: \([a-zA-Z-]*[0-9]\).*/\1/p');
    aws s3 cp s3://resource-opinion-stg/get-pip.py - | python3
    export VAULT_PASSWORD="{{ vault_password }}"
    aws s3 sync s3://bootstrap-opinion-stg/playbooks/ansible-opinion /tmp/ansible-opinion --region $REGION && cd /tmp/ansible-opinion
    echo "$VAULT_PASSWORD" > /tmp/ansible-opinion/secret
    bash main.sh -r $REGION
    rm /tmp/ansible-opinion/secret
    echo "End user data"
}
trap 'catch_error "$ERROR"' ERR
{ ERROR=$(main 2>&1 1>&$out); } {out}>&1