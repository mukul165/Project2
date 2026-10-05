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
module "gke" {
  source = "../../modules/gke"

  project_id   = var.project_id
  region       = var.region
  cluster_name = "prj2-dev"

  network_id          = module.vpc.network_id
  subnetwork_id       = module.vpc.subnet_ids["dev"]
  pods_range_name     = module.vpc.pods_range_names["dev"]
  services_range_name = module.vpc.services_range_names["dev"]
  master_ipv4_cidr_block = "172.16.1.0/28"

  # TODO: replace with YOUR actual public IP (run: curl ifconfig.me) so you
  # can reach the control plane from your machine. Add your CI runner's IP
  # later too. Without an entry here, kubectl will be refused by the API
  # server even with valid credentials.
  master_authorized_networks = [
    {
      cidr_block   = "10.0.1.2/32"
      display_name = "my-workstation"
    }
  ]

  node_pools = {
    default-pool = {
      machine_type   = "e2-medium"
      min_node_count = 1
      max_node_count = 3
      disk_size_gb   = 50
      preemptible    = true
    }
  }
}