module "vpc" {
  source = "aws-ia/vpc/aws"

  name       = var.vpc_name
  cidr_block = "10.0.0.0/20"
  az_count   = 3

  subnets = {
    public = {
      name_prefix               = "ingress"
      netmask                   = 24
      nat_gateway_configuration = "single_az"
    }

    apps = {
      netmask                 = 24
      connect_to_public_natgw = true
    }

    databases = {
      name_prefix             = "dbs"
      netmask                 = 24
      connect_to_public_natgw = true
    }

    platform = {
      name_prefix             = "platform"
      netmask                 = 24
      connect_to_public_natgw = true
    }
  }
}
