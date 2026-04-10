output "flask_ecr_url" {
  value = aws_ecr_repository.flask.repository_url
}

output "express_ecr_url" {
  value = aws_ecr_repository.express.repository_url
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "flask_url" {
  value = "http://${aws_lb.main.dns_name}:80"
}

output "express_url" {
  value = "http://${aws_lb.main.dns_name}:8080"
}
