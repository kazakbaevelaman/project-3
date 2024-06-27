#!/bin/bash

# Variables
region="us-east-2"
vpc_cidr="10.0.0.0/16"
subnet1_id="10.0.1.0/24"
ami_id="ami-033fabdd332044f06" # Amazon Linux 2023 AMI
instance_type="t2.micro"
timestamp=$(date +%s)
bucket1_name="kai-zen-${timestamp}"
bucket2_name="kai-zen-${timestamp}"
my_file="test55.txt"
current_public_key=$(cat ~/.ssh/id_rsa.pub | base64)
my_key="my_key1"

# Debug: Print the current public key
echo "Current public key (base64 encoded): $current_public_key"

# Create VPC
vpc_id=$(aws ec2 create-vpc --cidr-block $vpc_cidr --region $region --query Vpc.VpcId --output text)
if [ $? -ne 0 ]; then
    echo "Failed to create VPC"
    exit 1
fi

# Create Subnet
subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block $subnet1_id --region $region --query Subnet.SubnetId --output text)
if [ $? -ne 0 ]; then
    echo "Failed to create subnet"
    exit 1
fi

# Create Internet Gateway
igw_id=$(aws ec2 create-internet-gateway --region $region --query InternetGateway.InternetGatewayId --output text)
if [ $? -ne 0 ]; then
    echo "Failed to create internet gateway"
    exit 1
fi

aws ec2 attach-internet-gateway --vpc-id $vpc_id --region $region --internet-gateway-id $igw_id
if [ $? -ne 0 ]; then
    echo "Failed to attach internet gateway"
    exit 1
fi

# Create Route Table and Route
rt_id=$(aws ec2 create-route-table --vpc-id $vpc_id --region $region --query RouteTable.RouteTableId --output text)
if [ $? -ne 0 ]; then
    echo "Failed to create route table"
    exit 1
fi

aws ec2 create-route --route-table-id $rt_id --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id --region $region
if [ $? -ne 0 ]; then
    echo "Failed to create route"
    exit 1
fi

aws ec2 associate-route-table --subnet-id $subnet_id --route-table-id $rt_id --region $region
if [ $? -ne 0 ]; then
    echo "Failed to associate route table"
    exit 1
fi

# Create Security Group and Authorize Ingress
sg_id=$(aws ec2 create-security-group --group-name EC2SecurityGroup --description "My Security Group" --region $region --vpc-id $vpc_id --query GroupId --output text)
if [ $? -ne 0 ]; then
    echo "Failed to create security group"
    exit 1
fi

aws ec2 authorize-security-group-ingress --group-id $sg_id --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $region
if [ $? -ne 0 ]; then
    echo "Failed to authorize security group ingress"
    exit 1
fi

# Import Key Pair
echo "Importing key pair..."
import_key_response=$(aws ec2 import-key-pair --key-name $my_key --public-key-material "$current_public_key")
if [ $? -ne 0 ]; then
    echo "Failed to import key pair"
    echo "$import_key_response"
    exit 1
fi
echo "Key pair imported successfully"

# Launch EC2 Instance
instance_id=$(aws ec2 run-instances --image-id $ami_id --count 1 --instance-type $instance_type --key-name $my_key --associate-public-ip-address --security-group-ids $sg_id --subnet-id $subnet_id --query 'Instances[0].InstanceId' --output text)
if [ $? -ne 0 ]; then
    echo "Failed to launch EC2 instance"
    exit 1
fi

# Wait for the instance to be in running state
aws ec2 wait instance-running --instance-ids $instance_id
if [ $? -ne 0 ]; then
    echo "Failed to wait for instance to run"
    exit 1
fi

# Retrieve Public IP Address of the instance
public_ip=$(aws ec2 describe-instances --instance-ids $instance_id --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
if [ $? -ne 0 ]; then
    echo "Failed to retrieve public IP address"
    exit 1
fi

echo "Public IP address: $public_ip"

# Connect to the instance via SSH
ssh -i ~/.ssh/id_rsa ec2-user@$public_ip


# Uncomment the following lines to create S3 buckets and copy files
# aws s3api create-bucket --bucket $bucket1_name --region $region --create-bucket-configuration LocationConstraint=$region
# aws s3api create-bucket --bucket $bucket2_name --region $region --create-bucket-configuration LocationConstraint=$region
# aws s3 cp $my_file s3://$bucket1_name
# aws s3 cp s3://$bucket1_name/$my_file s3://$bucket2_name
