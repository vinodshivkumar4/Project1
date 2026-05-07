output "public_ip" {
  description = "Public IP of the Node.js Server"
  value       = aws_instance.node_app_server.public_ip
}

output "private_key" {
  description = "Private key for SSH access"
  value       = tls_private_key.node_app_key.private_key_pem
  sensitive   = true
}