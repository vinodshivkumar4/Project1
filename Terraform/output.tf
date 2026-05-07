output "public_ip" {
  value = aws_instance.nodeapp_vm.public_ip
}

output "private_key" {
  value     = tls_private_key.nodeapp_key.private_key_pem
  sensitive = true
}