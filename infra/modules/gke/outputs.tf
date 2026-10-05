output "cluster_name" {
  value = google_container_cluster.this.name
}

output "cluster_endpoint" {
  description = "Control plane endpoint IP (public or private depending on enable_private_endpoint)."
  value       = google_container_cluster.this.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Base64-encoded cluster CA cert — needed to build a kubeconfig without `gcloud container clusters get-credentials`."
  value       = google_container_cluster.this.master_auth.0.cluster_ca_certificate
  sensitive   = true
}

output "location" {
  value = google_container_cluster.this.location
}

output "workload_identity_pool" {
  value = google_container_cluster.this.workload_identity_config.0.workload_pool
}