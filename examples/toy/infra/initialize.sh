#! /bin/bash

# This script is run when the EC2 instance is launched
# It is responsible for download the python zipped modules from an S3 bucket
# and the input data file.
# Then it uses RabbitMQ to run all the modules and upload the results
# back to the S3 bucket

#### Install basic software ####
# sudo apt update -y
# sudo apt install awscli -y

#### Start RabbitMQ Server ####
sudo service rabbitmq-server start

cd /home/ubuntu

# Make a tmp directory to download all the python modules
mkdir tmp
cd tmp

# Download all the python zipped modules
for (( i=1; i<=${files}; i++ ))
do
   aws s3 cp s3://${s3_bucket_name}/$i.zip $i.zip
done

# Download the pipeline.zip module
aws s3 cp s3://${s3_bucket_name}/pipeline.zip pipeline.zip

cd /home/ubuntu

# Download the input data file
aws s3 cp s3://${s3_bucket_name}/${data_filename} ${data_filename}

# Copy the runner to execute the python zipped modules and run them
cp BOOM/bin/run.py run.py
python run.py

# Upload the results back to the S3 bucket
find . -type d -regex ".*[0-9]+s$" | while read i; do
    results_dir=$(basename "$i")
    aws s3 sync "$results_dir" s3://${s3_bucket_name}/"$results_dir"
done
