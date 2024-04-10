## Overview of this codebase:
This app is written in Python Flask by ChatGPT. Honestly, I'm not very proficient at coding, but I believe Flask is the easiest way to create a simple API. So here is my prompt:
```
Write a program using Python Flask to create a REST API that can store, list, retrieve, and delete files with four simple CRUD routes.
```
Terraform will provision AWS infrastructure including VPC, subnet, IGW, IAM, and EC2. It will then synchronize Nginx's files to the server and generate an Ansible inventory file. This file will be used in the ansible/ansible.run file to continue the installations for this server, including Jenkins, Nginx, and Docker.

To cover basic security measures, I want to enable TLS for Jenkins. That is the reason I use an Nginx SSL proxy for this case. To enable this server login to ECR, I use IAM instance role instead of User Access Key.

# HOW TO SET IT UP
## Prerequisites
Please make sure you already had sshkey in aws account. We will use that key to bring up ec2 instance.

## Setup local environment
Install ansible and terraform in MacOS:
```
brew install ansible
brew install warrensbox/tap/tfswitch
```
Use the command tfswitch -l to choose the newest stable version of Terraform.
Change your aws profile informations in the file ```terraform/terraform.tfvars```

Run tfcode:
```
cd terraform
terraform init
terraform plan
terraform apply --auto-approve
```
The file named ansible_inventory will be appear, this is inventory file for ansible. Now we use it:
```
cd ../ansible
sh ansible.run
```
In the output console, you can see the TASK [Jenkins init password] like this:
```
ok: [54.169.207.123] => {
    "output.stdout_lines": [
        "885de86ed5c343858c8b0688c92579d9"
    ]
}
```
Now you can accees to Jenkins https://54.169.207.123:8443 then use the ```Jenkins init password``` into it, then click to install recommended plugin.

Now you can create build job and deploy job by using 2 files ```jenkins/jenkinsfile.build```, ```jenkins/jenkinsfile.deploydev```

After deploy container successfully, you can access the app api port 6000:
```
cd /
appip='54.169.207.123'
curl -X POST -F "file=@requirements.txt" http://$appip:6000/files
curl -X POST -F "file=@readme.md" http://$appip:6000/files/abc
curl -X GET  http://$appip:6000/files
curl -X DELETE  http://$appip:6000/files/readme.md
```
The output should be like this:
```
{
  "message": "File uploaded successfully"
}
<!doctype html>
<html lang=en>
<title>405 Method Not Allowed</title>
<h1>Method Not Allowed</h1>
<p>The method is not allowed for the requested URL.</p>
[
  "requirements.txt"
]
{
  "error": "File not found"
}
```
