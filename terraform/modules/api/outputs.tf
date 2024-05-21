output "instance_ids" {
  value = aws_instance.app.*.id
}

output "lb_dns_name" {
  value = aws_lb.lb.dns_name
}