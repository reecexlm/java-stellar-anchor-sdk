resource "aws_acm_certificate" "sep" {
  domain_name               = "www.${data.aws_route53_zone.anchor_zone.name}"
  validation_method         = "DNS"
lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "acm_certificate_validation" {
 certificate_arn = aws_acm_certificate.sep.arn
 validation_record_fqdns = [for record in aws_route53_record.sep : record.fqdn]
}