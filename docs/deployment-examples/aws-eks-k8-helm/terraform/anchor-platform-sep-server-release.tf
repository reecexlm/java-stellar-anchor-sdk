data "kubernetes_ingress" "sep" {
  metadata {
    name = "sep-server-ingress"
    namespace = "anchor-platform"
  }
  depends_on = [resource.helm_release.sep] 
}

data "kubernetes_service" "ingress_reference" {
    metadata {
      name = "reference-server-service"
      namespace = "anchor-platform"
    }
}

data "kubernetes_service" "ingress_sep" {
    metadata {
      name = "reference-server-service"
      namespace = "anchor-platform"
    }
}

output "k8s_service_sep" {
  value = data.kubernetes_service.ingress_sep.status.0.load_balancer.0.ingress.0.hostname
}
#data "kubernetes_ingress" "reference" {
#  metadata {
#    name = "reference-server-ingress"
#    namespace = "anchor-platform"
#  }
#  depends_on = [resource.helm_release.reference]
#}

locals {
  s_template_vars = {
    #sep_endpoint = data.kubernetes_ingress.sep.status.0.load_balancer.0.ingress.0.hostname
    sep_endpoint = "abc.com"
  }
  sep_template_vars = {
    #reference_endpoint = data.kubernetes_ingress.reference.status.0.load_balancer.0.ingress.0.hostname
    reference_endpoint = "abc.com"
    #bootstrap_broker = "${element(split(",", data.aws_msk_cluster.anchor_msk.bootstrap_brokers), 0)}"
  }
}
resource "helm_release" "sep" {
  name             = "sep-server"
  chart            = "./charts/sep"
  namespace        = "anchor-platform"
  version          = "17.1.3"
  create_namespace = true
  wait             = true
  wait_for_jobs    = true
  reset_values     = true
  max_history      = 3
  timeout          = 600

    values = [templatefile("${path.module}/anchor-platform-sep-server-values.yaml",
    local.sep_template_vars)]
    depends_on = [resource.helm_release.ingress-nginx, resource.helm_release.reference]
}

