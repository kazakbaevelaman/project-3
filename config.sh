region="us-east-2"
vpc_cidr="10.0.0.0/16"
subnet1_id="10.0.1.0/24"
ami_id="ami-033fabdd332044f06"
instance_type="t2.micro"
timestamp=$(date +%s)
my_file="test55.txt"
current_public_key=$(cat ~/.ssh/id_rsa.pub | base64)
my_key="my_key-${timestamp}"

bucket1_name="kai-zen-myb8"
bucket2_name="kai-zen-myb9"


#Import aws keys 
