# packer-demo

## Source Repo
https://github.com/hashicorp/terraform-aws-vault-ent-starter

# Scenario 1 - Reducing Risk by Enforcing Standards
// Set AWS & HCP ENV

## HCP Packer requires a unique ID associated with a new image
export HCP_PACKER_BUILD_FINGERPRINT="hashicups-ubuntu-bionic-18.04-$(date +%s)"

## Build the Packer Image
cd $ASSETS_HOME/packer/development
packer init .
packer fmt .
packer validate .
packer build .

## Deploy the image using AWS CLI
- Lookup AMI ID from HCP Packer eg ami-0ee60e9b285814f54
export IMAGE_ID=ami-0ee60e9b285814f54

## We need to declare an AWS EC2 security group
aws ec2 create-security-group \
--group-name rkr-hashicups-demo \
--description "Hashicups Demo RKR"

## Obtain the unique ID for the new security group
export AWS_DEFAULT_SG=$(aws ec2 describe-security-groups \
--group-name rkr-hashicups-demo \
| jq -r '.SecurityGroups[].GroupId')

## Open HTTP port 80 to the whole world
aws ec2 authorize-security-group-ingress \
--group-id $AWS_DEFAULT_SG \
--protocol tcp \
--port 80 \
--cidr 0.0.0.0/0

## Launch a bare bones, free-range, glutten-free AWS EC2 instance
aws ec2 run-instances \
--image-id $IMAGE_ID \
--instance-type t2.micro \
--associate-public-ip-address \
--security-group-ids $AWS_DEFAULT_SG | jq -r

export EC2_INSTANCE_IP=$( aws ec2 describe-instances \
  --filters "Name=private-ip-address,Values=172.31.1.249" \
  | jq -r '.Reservations | .[].Instances | .[].PublicIpAddress')

export URL="http://${EC2_INSTANCE_IP}"

echo $URL

## Create Channel in Packer UI
Ensure there is a channel "dev"

## Build with Terraform
terraform init
terraform apply -auto-approve

## Cleanup
aws ec2 terminate-instances --instance-ids $EC_INSTANCE_ID
aws ec2 delete-security-group --group-id $AWS_DEFAULT_SG

# Scenario 2 - Use a Golden Image in a Workflow