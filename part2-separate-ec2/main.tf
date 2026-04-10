terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "part2-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "part2-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
  tags                    = { Name = "part2-public-subnet" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "part2-public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "flask_sg" {
  name   = "part2-flask-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "express_sg" {
  name   = "part2-express-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "flask_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.flask_sg.id]

  user_data = <<-USERDATA
    #!/bin/bash
    apt-get update -y
    apt-get install -y python3 python3-pip
    pip3 install flask
    mkdir -p /home/ubuntu/flask-app
    cat > /home/ubuntu/flask-app/app.py <<PYEOF
from flask import Flask
app = Flask(__name__)

@app.route('/')
def home():
    return 'Flask Backend - Part 2 - Separate EC2!'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
PYEOF
    nohup python3 /home/ubuntu/flask-app/app.py > /var/log/flask.log 2>&1 &
  USERDATA

  tags = { Name = "part2-flask-server" }
}

resource "aws_instance" "express_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.express_sg.id]

  user_data = <<-USERDATA
    #!/bin/bash
    apt-get update -y
    apt-get install -y nodejs npm
    mkdir -p /home/ubuntu/express-app
    cd /home/ubuntu/express-app
    npm init -y
    npm install express
    cat > /home/ubuntu/express-app/app.js <<JSEOF
const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.send('Express Frontend - Part 2 - Separate EC2!');
});

app.listen(3000, '0.0.0.0', () => {
  console.log('Express running on port 3000');
});
JSEOF
    nohup node /home/ubuntu/express-app/app.js > /var/log/express.log 2>&1 &
  USERDATA

  tags = { Name = "part2-express-server" }
}
