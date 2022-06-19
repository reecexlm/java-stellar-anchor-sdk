

locals {
  s_template_vars = {
    sep_endpoint = data.kubernetes_ingress_v1.sep.status.0.load_balancer.0.ingress.0.hostname
  }
  sep_template_vars = {
    reference_endpoint = data.kubernetes_ingress_v1.ref.status.0.load_balancer.0.ingress.0.hostname
    bootstrap_broker = "${element(split(",", data.aws_msk_cluster.anchor_msk.bootstrap_brokers), 0)}"
  }
}
resource "helm_release" "sep" {
  name             = "sep-server"
  #chart            = "./charts/sep"
  repository       = "http://anchorplatformhelmchart.s3-website.us-east-2.amazonaws.com"
  chart            = "sep"
  namespace        = "anchor-platform"
  version          = "0.3.17"
  create_namespace = true
  wait             = true
  reset_values     = true
  max_history      = 3
  timeout          = 600

    values = [templatefile("${path.module}/anchor-platform-sep-server-values.yaml",
    local.sep_template_vars)]
    depends_on = [resource.helm_release.ingress-nginx, resource.helm_release.cert-issuer, resource.helm_release.reference]
}

