terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.0.0"
    }
  }
  required_version = ">= 1.0.4"
}
provider "aws" {
  profile = var.profile
  region = var.region
}

# Create VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.my_vpc.id
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "public"
  }
}
# Create public subnet in the VPC
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.region}a"  # Update with your desired AZ
  map_public_ip_on_launch = true
}
resource "aws_route_table_association" "public1_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}
# Create IAM role for EC2 instance
resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "ssm-instance-profile"
  role = aws_iam_role.ssm_instance_role.name
}


resource "aws_iam_role" "ssm_instance_role" {
  name               = "ssm-instance-role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })

  inline_policy {
    name = "ssm-instance-policy"
    policy = jsonencode({
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": "ssm:StartSession",
          "Resource": "*"
        }
      ]
    })
  }
}
resource "aws_iam_role_policy_attachment" "attach_ecr_container_build_policy" {
  role       = aws_iam_role.ssm_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
}
# Create security group
resource "aws_security_group" "ec2_security_group" {
  vpc_id = aws_vpc.my_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6000
    to_port     = 6000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create EC2 instance
resource "aws_instance" "my_ec2_instance" {
  ami           = "ami-0910e4162f162c238"
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.public_subnet.id
  #associate_public_ip_address = true
  key_name      = var.keyname
  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  tags = {
    Name = "jenkins"
  }
}
resource "null_resource" "ansible_inventory1" {
  provisioner "remote-exec" {
    connection {
      host = aws_instance.my_ec2_instance.public_ip
      user = "ec2-user"
      private_key = file("/Users/ball/Documents/sshkey/phultv_np.rsa")
    }

    inline = ["echo 'connected!'"]
  }
  provisioner "local-exec" {
    command = "echo [my_ec2_instance] > ansible_inventory"
  }
  provisioner "local-exec" {
    command = "echo  ${aws_instance.my_ec2_instance.public_ip} >> ansible_inventory"
  }
  provisioner "local-exec" {
    command = "rsync -r -e 'ssh -i /Users/ball/Documents/sshkey/phultv_np.rsa -o StrictHostKeyChecking=no' ../jenkins/ ec2-user@${aws_instance.my_ec2_instance.public_ip}:/home/ec2-user/"
  }  
}
resource "aws_ecr_repository" "registry" {
  name                 = "pyapp"
  image_tag_mutability = "MUTABLE"
  tags = {
    Owner       = "DevopsTest"
    Environment = "dev"
    Terraform   = true
  }
}