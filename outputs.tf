output "terraform_fqdn" {
  value = aws_route53_record.tfenode.*.name
}
