region="us-east-2"
vpc_cidr="10.0.0.0/16"
subnet1_id="10.0.1.0/24"
ami_id="ami-033fabdd332044f06"
instance_type="t2.micro"
timestamp=$(date +%s)
my_file="test55.txt"
current_public_key=$(cat ~/.ssh/id_rsa.pub | base64)
my_key="my_key-${timestamp}"
# Bucket names needs to be updated for every run
bucket1_name="kai-zen011"
bucket2_name="kai-zen022"


# Create and import aws keys 
#AWS_ACCESS_KEY_ID="<your-access-key>"
#AWS_SECRET_ACCESS_KEY="<your-secret-key>"

AWS_ACCESS_KEY_ID="AKIA2UC3CGAWZIW3RVOE"
AWS_SECRET_ACCESS_KEY="4UbhoWUM2stYrJUWoOn1mOvWxSsI/xA+79xNFeTR"