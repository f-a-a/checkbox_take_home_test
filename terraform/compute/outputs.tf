output "eks_cluster_id" {
  value = module.eks_blueprints.eks_cluster_id
}

output "eks_cluster_endpoint" {
  value = module.eks_blueprints.eks_cluster_endpoint
}

output "eks_cluster_certificate_authority_data" {
  value = module.eks_blueprints.eks_cluster_certificate_authority_data
}

