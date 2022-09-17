module "network" {
  source = "./network"
}

module "compute" {
  source = "./compute"

  vpc_id                 = module.network.vpc_id
  private_subnet_ids     = module.network.private_subnet_ids
  platform_subnet_ids    = module.network.platform_subnet_ids
  database_subnet_ids    = module.network.database_subnet_ids
  application_subnet_ids = module.network.application_subnet_ids
}
