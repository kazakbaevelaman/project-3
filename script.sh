#!/bin/bash

region="us-east-2"
vpc_cidr="10.0.0.0/16"
subnet1_id="10.0.1.0/24"
ami_id="ami-033fabdd332044f06" #->Amazon Linux 2023 AMI
instance_type="t2.micro"
bucket1_name="kai-zen-{{timestamp}}"
bucket2_name="kai-zen-{{timestamp}}"
my_file="test55.txt"


vpc_id=$(aws ec2 create-vpc --cidr-block $vpc_cidr --region $region --query Vpc.VpcId --output text)

subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block $subnet1_id --region $region --query Subnet.SubnetId --output text)

igw_id=$(aws ec2 create-internet-gateway --region $region --query InternetGateway.InternetGatewayId --output text)

aws ec2 attach-internet-gateway --vpc-id $vpc_id --region $region --internet-gateway-id $igw_id

rt_id=$(aws ec2 create-route-table --vpc-id $vpc_id --region $region --query RouteTable.RouteTableId --output text)

aws ec2 create-route --route-table-id $rt_id --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id --region $region

aws ec2 associate-route-table --subnet-id $subnet_id --route-table-id $rt_id --region $region

sg_id=$(aws ec2 create-security-group --group-name EC2SecurityGroup --description "My Security Group" --region $region --vpc-id $vpc_id  --query GroupId --output text)

aws ec2 authorize-security-group-ingress --group-id $sg_id --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $region

INSTANCE_ID=$(aws ec2 run-instances --image-id $ami_id --count 1 --instance-type $instance_type --key-name key2 --associate-public-ip-address --security-group-ids $sg_id --subnet-id $subnet_id --query 'Instances[0].InstanceId' --output text)
echo "Instance id -> "$INSTANCE_ID

aws ec2 wait instance-running --instance-ids $INSTANCE_ID

PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo "Public IP address: $PUBLIC_IP"


ssh -i "~/.ssh/id_rsa" ec2-user@$PUBLIC_IP -y


#aws s3api create-bucket --bucket $bucket1_name --region $region --create-bucket-configuration LocationConstraint=$region
#aws s3api create-bucket --bucket $bucket2_name --region $region --create-bucket-configuration LocationConstraint=$region
#aws s3 cp $my_file s3://$bucket1_name


#aws s3 cp s3://$bucket1_name/$my_file s3://$bucket2_name
