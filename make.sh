#!/bin/bash

#
# variables
#

# AWS variables
AWS_PROFILE=default
AWS_REGION=us-east-1
# project name
PROJECT_NAME=free-knowledge
# apex domain name
APEX_DOMAIN=freeknowledge.tech
# terraform
export TF_VAR_region=$AWS_REGION
export TF_VAR_profile=$AWS_PROFILE
export TF_VAR_apex_domain=$APEX_DOMAIN

# the directory containing the script file
dir="$(cd "$(dirname "$0")"; pwd)"
cd "$dir"


log()   { echo -e "\e[30;47m ${1^^} \e[0m ${@:2}"; }        # $1 uppercase background white
info()  { echo -e "\e[48;5;28m ${1^^} \e[0m ${@:2}"; }      # $1 uppercase background green
warn()  { echo -e "\e[48;5;202m ${1^^} \e[0m ${@:2}" >&2; } # $1 uppercase background orange
error() { echo -e "\e[48;5;196m ${1^^} \e[0m ${@:2}" >&2; } # $1 uppercase background red


# log $1 in underline then $@ then a newline
under() {
    local arg=$1
    shift
    echo -e "\033[0;4m${arg}\033[0m ${@}"
    echo
}

usage() {
    under usage 'call the Makefile directly: make dev
      or invoke this file directly: ./make.sh dev'
}


upload() {
    cd "$dir/public"
    aws s3 sync --acl public-read . s3://www.$APEX_DOMAIN

    cd "$dir/extra"
    aws s3 sync --acl public-read . s3://www.$APEX_DOMAIN
}

create-user() {
    [[ -f "$dir/secrets.sh" ]] && { warn warn user already exists; return; }
    
    aws iam create-user \
        --user-name $PROJECT_NAME \
        --profile $AWS_PROFILE \
        1>/dev/null \
        2>/dev/null

    aws iam attach-user-policy \
        --user-name $PROJECT_NAME \
        --policy-arn arn:aws:iam::aws:policy/PowerUserAccess \
        --profile $AWS_PROFILE

    local key=$(aws iam create-access-key \
        --user-name $PROJECT_NAME \
        --query 'AccessKey.{AccessKeyId:AccessKeyId,SecretAccessKey:SecretAccessKey}' \
        --profile $AWS_PROFILE \
        2>/dev/null)
    cat > "$dir/secrets.sh" << EOF
AWS_ACCESS_IDS=$key
EOF
}

create-certificate() {
    cd "$dir"
    log create certificate
    CERTIFICATE_ARN=$(aws acm request-certificate \
        --domain-name $APEX_DOMAIN \
        --subject-alternative-names *.$APEX_DOMAIN \
        --validation-method DNS \
        --query CertificateArn \
        --region us-east-1 \
        --profile $AWS_PROFILE \
        --output text)
    log CERTIFICATE_ARN $CERTIFICATE_ARN

    RESOURCE_RECORD=$(aws acm describe-certificate \
        --certificate-arn $CERTIFICATE_ARN \
        --query 'Certificate.DomainValidationOptions[0].ResourceRecord' \
        --region us-east-1 \
        --profile $AWS_PROFILE)

    CNAME_NAME=$(echo "$RESOURCE_RECORD" | jq --raw-output '.Name')
    log CNAME_NAME $CNAME_NAME

    CNAME_VALUE=$(echo "$RESOURCE_RECORD" | jq --raw-output '.Value')
    log CNAME_VALUE $CNAME_VALUE

    log create CNAME.json
    cat > CNAME.json << EOF
{
  "Comment": " ",
  "Changes": [
    {
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "$CNAME_NAME",
        "Type": "CNAME",
        "TTL": 600,
        "ResourceRecords": [
          {
            "Value": "$CNAME_VALUE"
          }
        ]
      }
    }
  ]
}
EOF

    HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name \
        --dns-name $APEX_DOMAIN \
        --profile $AWS_PROFILE \
        --query 'HostedZones[0].Id' \
        --output text)
    log HOSTED_ZONE_ID $HOSTED_ZONE_ID

    aws route53 change-resource-record-sets \
        --hosted-zone-id $HOSTED_ZONE_ID \
        --change-batch file://CNAME.json \
        --profile $AWS_PROFILE \
        1>/dev/null

    CERTIFICATE_STATUS=$(aws acm describe-certificate \
        --certificate-arn $CERTIFICATE_ARN \
        --query 'Certificate.Status' \
        --region us-east-1 \
        --profile $AWS_PROFILE \
        --output text)
    log CERTIFICATE_STATUS $CERTIFICATE_STATUS

    log wait certificate-validated
    aws acm wait certificate-validated \
        --certificate-arn $CERTIFICATE_ARN \
        --region us-east-1 \
        --profile $AWS_PROFILE

    CERTIFICATE_STATUS=$(aws acm describe-certificate \
        --certificate-arn $CERTIFICATE_ARN \
        --query 'Certificate.Status' \
        --region us-east-1 \
        --profile $AWS_PROFILE \
        --output text)
    log CERTIFICATE_STATUS $CERTIFICATE_STATUS
}

tf-setup-backend() {
    cd "$dir"
    [[ -f settings.sh ]] && { error abort settings.sh already exisits; exit 0; }
    S3_BACKEND=$PROJECT_NAME-$(mktemp --dry-run XXXX | tr '[:upper:]' '[:lower:]')
    echo "S3_BACKEND=$S3_BACKEND" > "$dir/settings.sh"

    log create $S3_BACKEND bucket
    aws s3 mb s3://$S3_BACKEND --region $AWS_REGION
}

tf-init() {
    [[ ! -f "$dir/settings.sh" ]] && { error abort settings.sh not found; exit 0; }
    # set $S3_BACKEND
    source "$dir/settings.sh"

    cd "$dir/infra"
    terraform init \
        -input=false \
        -backend=true \
        -backend-config="region=$AWS_REGION" \
        -backend-config="bucket=$S3_BACKEND" \
        -backend-config="key=terraform" \
        -reconfigure
}

tf-validate() {
    cd "$dir/infra"
    terraform fmt -recursive
	terraform validate
}

tf-apply() {
    cd "$dir/infra"
    terraform plan \
        -out=terraform.plan

    terraform apply \
        -auto-approve \
        terraform.plan
}

tf-scale-up() {
    export TF_VAR_desired_count=3
    tf-apply
}

tf-scale-down() {
    export TF_VAR_desired_count=2
    tf-apply
}

tf-destroy() {
    cd "$dir/infra"
    terraform destroy \
        -auto-approve
}

# if `$1` is a function, execute it. Otherwise, print usage
# compgen -A 'function' list all declared functions
# https://stackoverflow.com/a/2627461
FUNC=$(compgen -A 'function' | grep $1)
[[ -n $FUNC ]] && { info execute $1; eval $1; } || usage;
exit 0
