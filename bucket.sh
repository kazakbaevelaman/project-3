#!/bin/bash
region="us-east-2"
bucket1_name="kai-zen-55"
bucket2_name="kai-zen-56"
my_file="test55.txt"

aws s3api create-bucket --bucket $bucket1_name --region $region --create-bucket-configuration LocationConstraint=$region
aws s3api create-bucket --bucket $bucket2_name --region $region --create-bucket-configuration LocationConstraint=$region


aws s3 cp $my_file s3://$bucket1_name
aws s3 cp s3://$bucket1_name/$my_file s3://$bucket2_name
