#!/bin/bash
source config.sh

# Create VPC
vpc_id=$(aws ec2 create-vpc --cidr-block $vpc_cidr --region $region --query Vpc.VpcId --output text)


# Create Subnet
subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block $subnet1_id --region $region --query Subnet.SubnetId --output text)


# Create Internet Gateway
igw_id=$(aws ec2 create-internet-gateway --region $region --query InternetGateway.InternetGatewayId --output text)


aws ec2 attach-internet-gateway --vpc-id $vpc_id --region $region --internet-gateway-id $igw_id

# Create Route Table and Route
rt_id=$(aws ec2 create-route-table --vpc-id $vpc_id --region $region --query RouteTable.RouteTableId --output text)


aws ec2 create-route --route-table-id $rt_id --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id --region $region


aws ec2 associate-route-table --subnet-id $subnet_id --route-table-id $rt_id --region $region


# Create Security Group and Authorize Ingress
sg_id=$(aws ec2 create-security-group --group-name EC2SecurityGroup --description "My Security Group" --region $region --vpc-id $vpc_id --query GroupId --output text)

# Opens port 22 
aws ec2 authorize-security-group-ingress --group-id $sg_id --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $region


# Import Key Pair
echo "Importing key pair..."
import_key_response=$(aws ec2 import-key-pair --key-name $my_key --public-key-material "$current_public_key")


# Launch EC2 Instance
instance_id=$(aws ec2 run-instances --image-id $ami_id --count 1 --instance-type $instance_type --key-name $my_key --associate-public-ip-address --security-group-ids $sg_id --subnet-id $subnet_id  --query 'Instances[0].InstanceId' --output text)

# Create 2 S3 bucket 
aws s3api create-bucket --bucket $bucket1_name --region $region --create-bucket-configuration LocationConstraint=$region
aws s3api create-bucket --bucket $bucket2_name --region $region --create-bucket-configuration LocationConstraint=$region


aws s3 cp $my_file s3://$bucket1_name

# Wait for the instance to be in running state
aws ec2 wait instance-running --instance-ids $instance_id


# Retrieve Public IP Address of the instance
public_ip=$(aws ec2 describe-instances --instance-ids $instance_id --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

#Copy files to new instance 
scp -i $my_key bucket.sh ec2-user@$public_ip:~/bucket.sh
scp -i $my_key config.sh ec2-user@$public_ip:~/config.sh

#SSH 
ssh -i ~/.ssh/id_rsa ec2-user@$public_ip



