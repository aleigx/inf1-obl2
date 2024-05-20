output "instance_ids" {
  value = aws_instance.app.*.id
}

output "ipv6s" {
  value = [ for instance in aws_instance.app : element(instance.ipv6_addresses, 0) ]
}

output "lb_dns_name" {
  value = aws_lb.lb.dns_name
}