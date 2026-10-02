output "network_id" {
  description = "Self link / ID of the VPC network."
  value       = google_compute_network.this.id
}

output "network_name" {
  value = google_compute_network.this.name
}

output "subnet_ids" {
  description = "Map of subnet key -> subnet self link, for use by GKE/Cloud SQL modules."
  value       = { for k, v in google_compute_subnetwork.this : k => v.id }
}

output "subnet_names" {
  value = { for k, v in google_compute_subnetwork.this : k => v.name }
}

output "pods_range_names" {
  description = "Secondary range names for pods, keyed by env — GKE module needs these."
  value       = { for k, v in var.subnets : k => "${k}-pods" }
}

output "services_range_names" {
  value = { for k, v in var.subnets : k => "${k}-services" }
}

output "router_name" {
  value = google_compute_router.this.name
}