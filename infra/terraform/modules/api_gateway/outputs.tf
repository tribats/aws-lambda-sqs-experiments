output "domain" {
  value = "${aws_route53_record.dns.fqdn}"
}
