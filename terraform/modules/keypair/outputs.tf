output "key_name" {
  description = "The name of the keypair"
  value       = aws_key_pair.kp.key_name
} 