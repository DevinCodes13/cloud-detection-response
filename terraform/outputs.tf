output "public_web_ip" {
  value = aws_instance.public_web.public_ip
}

output "public_web_id" {
  value = aws_instance.public_web.id
}

output "private_app_ip" {
  value = aws_instance.private_app.private_ip
}

output "private_app_id" {
  value = aws_instance.private_app.id
}
