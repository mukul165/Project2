module "vpc" {
  source = "../../modules/vpc"

  project_id   = var.project_id
  region       = var.region
  network_name = "devops-vpc"

  # Three subnets now so you don't have to re-architect networking later —
  # even though dev/staging/prod will initially all run in one GKE cluster
  # as separate namespaces, each gets its own IP space.
  subnets = {
    dev = {
      ip_cidr_range       = "10.10.0.0/20"
      region              = var.region
      pods_cidr_range     = "10.20.0.0/16"
      services_cidr_range = "10.30.0.0/20"
    }
    staging = {
      ip_cidr_range       = "10.11.0.0/20"
      region              = var.region
      pods_cidr_range     = "10.21.0.0/16"
      services_cidr_range = "10.31.0.0/20"
    }
    prod = {
      ip_cidr_range       = "10.12.0.0/20"
      region              = var.region
      pods_cidr_range     = "10.22.0.0/16"
      services_cidr_range = "10.32.0.0/20"
    }
  }

  enable_flow_logs = false
}