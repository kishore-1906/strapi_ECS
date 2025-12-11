#!/bin/bash
yum update -y
yum install -y python3 git mysql
pip3 install flask boto3 pymysql

cd /home/ec2-user
git clone https://github.com/your-repo/job-app.git
cd job-app

python3 app.py

