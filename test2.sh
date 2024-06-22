#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

region="us-east-2"
vpc_cidr="10.0.0.0/16"
subnet1_cidr="10.0.1.0/24"
ami_id="ami-033fabdd332044f06"  # Amazon Linux 2023 AMI
instance_type="t2.micro"
key_name="key2"

# Create VPC
vpc_id=$(aws ec2 create-vpc --cidr-block $vpc_cidr --region $region --query Vpc.VpcId --output text)
echo "Created VPC with ID $vpc_id"

# Create Subnet
subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block $subnet1_cidr --region $region --query Subnet.SubnetId --output text)
echo "Created Subnet with ID $subnet_id"

# Create Internet Gateway
igw_id=$(aws ec2 create-internet-gateway --region $region --query InternetGateway.InternetGatewayId --output text)
echo "Created Internet Gateway with ID $igw_id"

# Attach Internet Gateway to VPC
aws ec2 attach-internet-gateway --vpc-id $vpc_id --region $region --internet-gateway-id $igw_id
echo "Attached Internet Gateway $igw_id to VPC $vpc_id"

# Create Route Table
rt_id=$(aws ec2 create-route-table --vpc-id $vpc_id --region $region --query RouteTable.RouteTableId --output text)
echo "Created Route Table with ID $rt_id"

# Create Route to Internet Gateway
aws ec2 create-route --route-table-id $rt_id --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id --region $region
echo "Created route to 0.0.0.0/0 via Internet Gateway $igw_id"

# Associate Route Table with Subnet
aws ec2 associate-route-table --subnet-id $subnet_id --route-table-id $rt_id --region $region
echo "Associated Route Table $rt_id with Subnet $subnet_id"

# Create Security Group
sg_id=$(aws ec2 create-security-group --group-name EC2SecurityGroup --description "Demo Security Group" --region $region --vpc-id $vpc_id --query GroupId --output text)
echo "Created Security Group with ID $sg_id"

# Authorize SSH access in Security Group
aws ec2 authorize-security-group-ingress --group-id $sg_id --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $region
echo "Authorized SSH access to Security Group $sg_id"

# Run EC2 Instance
INSTANCE_ID=$(aws ec2 run-instances --image-id $ami_id --count 1 --instance-type $instance_type --key-name $key_name --security-group-ids $sg_id --subnet-id $subnet_id --region $region --query 'Instances[0].InstanceId' --output text)
echo "Created EC2 Instance with ID $INSTANCE_ID"

