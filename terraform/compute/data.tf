# ref: https://github.com/aws-ia/terraform-aws-eks-blueprints/tree/main/examples/fargate-serverless

data "aws_eks_cluster_auth" "this" {
  name = module.eks_blueprints.eks_cluster_id
}
