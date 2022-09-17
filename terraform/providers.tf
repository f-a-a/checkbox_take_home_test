provider "aws" {
  region = "ap-southeast-1"
}

provider "kubernetes" {
  host                   = module.compute.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.compute.eks_cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.compute.eks_cluster_id]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = module.compute.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(module.compute.eks_cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.compute.eks_cluster_id]
      command     = "aws"
    }
  }
}
