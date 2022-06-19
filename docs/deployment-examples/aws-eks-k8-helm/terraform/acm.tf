  locals {
      domain_name = data.aws_route53_zone.anchor_zone.name
  }
module "acm" {
    source  = "terraform-aws-modules/acm/aws"
    version = "~> 3.0"



  zone_id     = data.aws_route53_zone.anchor_zone.zone_id
  domain_name = local.domain_name

  subject_alternative_names = [
    "*.${local.domain_name}"
  ]

  wait_for_validation = true

  tags = {
    Name = data.aws_route53_zone.anchor_zone.name
  }
}