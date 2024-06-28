#!/bin/bash

source config.sh

# Create the AWS configuration directory if it doesn't exist
mkdir -p ~/.aws

# Write to the AWS credentials file
cat <<EOL > ~/.aws/credentials
[default]
aws_access_key_id = $AWS_ACCESS_KEY_ID
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY
EOL

# Write to the AWS config file
cat <<EOL > ~/.aws/config
[default]
region = $region
output = json
EOL

#Copy logic 
aws s3 cp s3://$bucket1_name/$my_file s3://$bucket2_name
