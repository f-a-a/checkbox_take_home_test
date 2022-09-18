module "eks_blueprints" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.9.0"

  cluster_name    = "app-cluster"
  cluster_version = "1.23"

  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids

  fargate_profiles = {
    platform = {
      fargate_profile_name = "platform"
      fargate_profile_namespaces = [
        {
          namespace = "kube-system"
        },
        {
          namespace = "secrets-store-csi-driver"
        },
        {
          namespace = "csi-secrets-store-provider-aws"
        },
        {
          namespace = "argocd"
        }
      ]
      subnet_ids = var.platform_subnet_ids
    }

    databases = {
      fargate_profile_name = "dbs"
      fargate_profile_namespaces = [
        {
          namespace = "db-redis"
        }
      ]
      subnet_ids = var.database_subnet_ids
    }

    apps = {
      fargate_profile_name = "apps"
      fargate_profile_namespaces = [
        {
          namespace = "app-shopping-cart"
        }
      ]
      subnet_ids = var.application_subnet_ids
    }
  }
}

module "eks_blueprints_kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons"

  eks_cluster_id       = module.eks_blueprints.eks_cluster_id
  eks_cluster_endpoint = module.eks_blueprints.eks_cluster_endpoint
  eks_oidc_provider    = module.eks_blueprints.oidc_provider
  eks_cluster_version  = module.eks_blueprints.eks_cluster_version

  enable_amazon_eks_vpc_cni            = true
  enable_amazon_eks_kube_proxy         = true
  enable_amazon_eks_aws_ebs_csi_driver = true

  enable_self_managed_coredns = true
  self_managed_coredns_helm_config = {
    compute_type       = "fargate"
    kubernetes_version = module.eks_blueprints.eks_cluster_version
  }

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
    null_resource.modify_kube_dns,
    aws_secretsmanager_secret.repository_ssh_key,
    aws_secretsmanager_secret_version.repository_ssh_key_secret_string
  ]
}
