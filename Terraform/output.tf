# Keep the public_ip output
output "public_ip" {
  value = aws_instance.node_app_server.public_ip
}

# DELETE OR COMMENT OUT THE BLOCK BELOW:
# output "private_key" {
#   value     = tls_private_key.node_app_key.private_key_pem
#   sensitive = true
# }