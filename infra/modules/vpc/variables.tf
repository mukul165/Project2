variable "project_id" {
  description = "GCP project ID where the VPC will be created."
  type        = string
}

variable "region" {
  description = "Primary region for the Cloud Router / NAT and regional resources."
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network."
  type        = string
  default     = "devops-vpc"
}

variable "subnets" {
  description = <<-EOT
    Map of subnets to create, keyed by a short name (e.g. "dev", "staging", "prod").
    Each subnet gets its own primary range plus secondary ranges for GKE pods/services.
  EOT
  type = map(object({
    ip_cidr_range         = string
    region                = string
    pods_cidr_range       = string
    services_cidr_range   = string
    private_ip_google_access = optional(bool, true)
  }))
}

variable "enable_flow_logs" {
  description = "Whether to enable VPC flow logs on each subnet (useful for Cloud IDS / troubleshooting)."
  type        = bool
  default     = false
}