module "acm" {
    source  = "terraform-aws-modules/acm/aws"
    version = "~> 3.0"

  domain_name = data.aws_route53_zone.anchor_zone.name
  zone_id     = data.aws_route53_zone.anchor_zone.zone_id

  subject_alternative_names = [
    "*.${local.domain_name}"
  ]

  wait_for_validation = true

  tags = {
    Name = data.aws_route53_zone.anchor_zone.name
  }
}