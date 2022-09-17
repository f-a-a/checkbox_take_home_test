# ref: https://github.com/aws-ia/terraform-aws-eks-blueprints/tree/main/examples/fargate-serverless

resource "null_resource" "remove_default_coredns_deployment" {
  triggers = {}

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = base64encode(local.kubeconfig)
    }

    # We are removing the deployment provided by the EKS service and replacing it through the self-managed CoreDNS Helm addon
    # However, we are maintaing the existing kube-dns service and annotating it for Helm to assume control
    command = <<-EOT
      kubectl --namespace kube-system delete deployment coredns --kubeconfig <(echo $KUBECONFIG | base64 --decode)
    EOT
  }
}

resource "null_resource" "modify_kube_dns" {
  triggers = {}

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = base64encode(local.kubeconfig)
    }

    # We are maintaing the existing kube-dns service and annotating it for Helm to assume control
    command = <<-EOT
      echo "Setting implicit dependency on ${module.eks_blueprints.fargate_profiles["platform"].eks_fargate_profile_arn}"
      kubectl --namespace kube-system annotate --overwrite service kube-dns meta.helm.sh/release-name=coredns --kubeconfig <(echo $KUBECONFIG | base64 --decode)
      kubectl --namespace kube-system annotate --overwrite service kube-dns meta.helm.sh/release-namespace=kube-system --kubeconfig <(echo $KUBECONFIG | base64 --decode)
      kubectl --namespace kube-system label --overwrite service kube-dns app.kubernetes.io/managed-by=Helm --kubeconfig <(echo $KUBECONFIG | base64 --decode)
    EOT
  }

  depends_on = [
    null_resource.remove_default_coredns_deployment
  ]
}
