output "public_ip" {
  value = aws_instance.lab_vm.public_ip
}
output "public_dns" {
  value = aws_instance.lab_vm.public_dns
}
