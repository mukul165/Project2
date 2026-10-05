variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "Region for the regional GKE cluster (control plane + nodes spread across its zones)."
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster."
  type        = string
  default     = "prj2-dev"
}

variable "network_id" {
  description = "Self link of the VPC network (from the vpc module's network_id output)."
  type        = string
}

variable "subnetwork_id" {
  description = "Self link of the subnet this cluster's nodes live in (from the vpc module's subnet_ids output)."
  type        = string
}

variable "pods_range_name" {
  description = "Secondary range name for pod IPs (from the vpc module's pods_range_names output)."
  type        = string
}

variable "services_range_name" {
  description = "Secondary range name for service IPs (from the vpc module's services_range_names output)."
  type        = string
}

variable "master_ipv4_cidr_block" {
  description = "A dedicated /28 CIDR for the GKE control plane's private IP range. Must not overlap any subnet."
  type        = string
  default     = "172.16.0.0/28"
}

variable "master_authorized_networks" {
  description = <<-EOT
    CIDR ranges allowed to reach the private cluster endpoint (e.g. your workstation's
    public IP). The control plane endpoint stays reachable from the public internet by
    default, but locked down to only these ranges.
  EOT
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
}

variable "release_channel" {
  description = "GKE release channel: RAPID, REGULAR, or STABLE."
  type        = string
  default     = "REGULAR"
}

variable "node_pools" {
  description = "Node pool configurations, keyed by pool name."
  type = map(object({
    machine_type   = string
    min_node_count = number
    max_node_count = number
    disk_size_gb   = number
    preemptible    = bool
    labels         = optional(map(string), {})
  }))
  default = {
    default-pool = {
      machine_type   = "e2-medium"
      min_node_count = 1
      max_node_count = 3
      disk_size_gb   = 50
      preemptible    = true
    }
  }
}