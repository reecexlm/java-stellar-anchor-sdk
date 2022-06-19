resource "aws_acm_certificate" "cert" {
  domain_name               = "www.${data.aws_route53_zone.anchor_zone.name}"
  validation_method         = "DNS"
lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  name    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.aws_route53_zone.anchor_zone.zone_id}"
  records = ["${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "acm_certificate_validation" {
 certificate_arn = aws_acm_certificate.cert.arn
 validation_record_fqdns = [for record in aws_route53_record.sep : record.fqdn]
}

output "validation_records" {
  value = aws_acm_certificate_validation.acm_certificate_validation.validation_record_fqdns
}
