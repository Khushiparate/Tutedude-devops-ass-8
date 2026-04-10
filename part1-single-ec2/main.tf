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

resource "aws_security_group" "app_sg" {
  name        = "part1-app-sg"
  description = "Allow Flask and Express ports"

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

resource "aws_instance" "app_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = <<-USERDATA
    #!/bin/bash
    apt-get update -y
    apt-get install -y python3 python3-pip nodejs npm

    mkdir -p /home/ubuntu/flask-app
    cat > /home/ubuntu/flask-app/app.py <<PYEOF
from flask import Flask
app = Flask(__name__)

@app.route('/')
def home():
    return 'Flask Backend Running on Port 5000!'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
PYEOF

    pip3 install flask
    nohup python3 /home/ubuntu/flask-app/app.py > /var/log/flask.log 2>&1 &

    mkdir -p /home/ubuntu/express-app
    cd /home/ubuntu/express-app
    npm init -y
    npm install express

    cat > /home/ubuntu/express-app/app.js <<JSEOF
const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.send('Express Frontend Running on Port 3000!');
});

app.listen(3000, '0.0.0.0', () => {
  console.log('Express running on port 3000');
});
JSEOF

    nohup node /home/ubuntu/express-app/app.js > /var/log/express.log 2>&1 &
  USERDATA

  tags = {
    Name = "part1-single-app-server"
  }
}
