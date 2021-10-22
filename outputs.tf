output "terraform_fqdn" {
  value = "${aws_route53_record.tfenode.*.name}.${terraform_remote_state.foundation.outputs.dns_domain}"
}
