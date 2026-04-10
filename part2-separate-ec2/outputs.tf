output "flask_public_ip" {
  value = aws_instance.flask_server.public_ip
}

output "express_public_ip" {
  value = aws_instance.express_server.public_ip
}

output "flask_url" {
  value = "http://${aws_instance.flask_server.public_ip}:5000"
}

output "express_url" {
  value = "http://${aws_instance.express_server.public_ip}:3000"
}
