output "network_id" {
  value = module.vpc.network_id
}

output "subnet_ids" {
  value = module.vpc.subnet_ids
}

output "pods_range_names" {
  value = module.vpc.pods_range_names
}

output "services_range_names" {
  value = module.vpc.services_range_names
}