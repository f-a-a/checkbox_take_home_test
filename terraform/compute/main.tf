module "eks_blueprints" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.9.0"

  cluster_name    = "app-cluster"
  cluster_version = "1.23"

  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids

  managed_node_groups = {
    platform = {
      node_group_name = "platform"
      instance_types  = ["m5.large"]
      subnet_ids      = var.platform_subnet_ids
    }

    databases = {
      node_group_name = "dbs"
      instance_types  = ["m5.large"]
      subnet_ids      = var.database_subnet_ids
    }

    apps = {
      node_group_name = "apps"
      instance_types  = ["m5.large"]
      subnet_ids      = var.application_subnet_ids
    }
  }
}

module "eks_blueprints_kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons"

  eks_cluster_id       = module.eks_blueprints.eks_cluster_id
  eks_cluster_endpoint = module.eks_blueprints.eks_cluster_endpoint
  eks_oidc_provider    = module.eks_blueprints.oidc_provider
  eks_cluster_version  = module.eks_blueprints.eks_cluster_version

  enable_amazon_eks_vpc_cni    = true
  enable_amazon_eks_coredns    = true
  enable_amazon_eks_kube_proxy = true

  enable_secrets_store_csi_driver = true
  secrets_store_csi_driver_helm_config = {
    values = [templatefile("${path.module}/values/secrets-store-csi-driver.yaml", {})]
  }
  enable_secrets_store_csi_driver_provider_aws = true

  enable_argocd = true
  argocd_helm_config = {
    values = [templatefile("${path.module}/values/argocd.yaml", {})]
  }
  argocd_applications = {
    platform = {
      path                = "kustomize/platform"
      repo_url            = "ssh://git@github.com/f-a-a/checkbox_assessment.git"
      type                = "kustomize"
      ssh_key_secret_name = aws_secretsmanager_secret.repository_ssh_key.name
    }
    apps = {
      path                = "kustomize/apps"
      repo_url            = "ssh://git@github.com/f-a-a/checkbox_assessment.git"
      type                = "kustomize"
      ssh_key_secret_name = aws_secretsmanager_secret.repository_ssh_key.name
    }
  }

  depends_on = [
    aws_secretsmanager_secret.repository_ssh_key,
    aws_secretsmanager_secret_version.repository_ssh_key_secret_string
  ]
}
