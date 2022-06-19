resource "aws_acm_certificate" "cert" {
  domain_name               = "www.${data.aws_route53_zone.anchor_zone.name}"
  validation_method         = "DNS"
lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.sep.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
}

resource "aws_acm_certificate_validation" "acm_certificate_validation" {
 certificate_arn = aws_acm_certificate.cert.arn
 validation_record_fqdns = [aws_route53_record.validation.fqdn]
}

output "validation_records" {
  value = aws_acm_certificate_validation.acm_certificate_validation.validation_record_fqdns
}
