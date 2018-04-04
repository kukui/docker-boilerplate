#!/bin/bash
stackname=$1
ARNLIST=$(aws rds describe-db-instances --query "DBInstances[].DBInstanceArn" --output text)
for arn in $ARNLIST; do
    MATCH=$(aws rds list-tags-for-resource --resource-name $arn | jq -r '.TagList[] | select(.Key=="aws:cloudformation:stack-name") | select(.Value="dockerswarm") | .Value')
    if [[ "$MATCH" == "$stackname" ]]; then
        echo $(aws rds describe-db-instances | jq --arg arn $arn -r '.DBInstances[] | select(.DBInstanceArn==$arn) | .Endpoint.Address')
    fi
done
