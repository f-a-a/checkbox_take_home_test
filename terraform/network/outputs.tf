output "vpc_id" {
  value = module.vpc.vpc_attributes.id
}

output "private_subnet_ids" {
  value = [for value in module.vpc.private_subnet_attributes_by_az : value.id]
}

output "platform_subnet_ids" {
  value = [for value in module.vpc.private_subnet_attributes_by_az : value.id if length(regexall("platform-", value.tags["Name"])) > 0]
}

output "database_subnet_ids" {
  value = [for value in module.vpc.private_subnet_attributes_by_az : value.id if length(regexall("dbs-", value.tags["Name"])) > 0]
}

output "application_subnet_ids" {
  value = [for value in module.vpc.private_subnet_attributes_by_az : value.id if length(regexall("apps-", value.tags["Name"])) > 0]
}
