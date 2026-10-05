# -----------------------------------------------------------------------------
# GKE cluster — regional, private nodes, subnet-level separation per environment,
# Dataplane V2 for built-in NetworkPolicy enforcement, Workload Identity enabled.
#
# Node pools are managed as separate resources below — the default pool created
# with the cluster is deleted immediately (remove_default_node_pool = true) so
# every real node pool has full, independent control over machine type,
# autoscaling, and labels.
# -----------------------------------------------------------------------------
resource "google_container_cluster" "this" {
  project  = var.project_id
  name     = var.cluster_name
  location = var.region # regional cluster — control plane replicated across 3 zones

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.network_id
  subnetwork = var.subnetwork_id

  networking_mode = "VPC_NATIVE" # required to use the secondary ranges below
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  # Private nodes: no public IPs on any node. They reach the internet only
  # through the Cloud NAT already built in the vpc module. The control plane
  # endpoint itself stays public but locked to master_authorized_networks,
  # so kubectl still works from your laptop.
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.master_authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  # Workload Identity — Kubernetes service accounts impersonate GCP service
  # accounts without any downloaded key files.
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  release_channel {
    channel = var.release_channel
  }

  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }
  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
  }

  # Dataplane V2 (Cilium-based) — gives built-in NetworkPolicy enforcement
  # for free, without needing to install Calico separately. Istio can still
  # run alongside it for mTLS/traffic management.
  datapath_provider = "ADVANCED_DATAPATH"

  deletion_protection = false # flip to true once this is a long-lived cluster
}

# -----------------------------------------------------------------------------
# Node pool(s) — one per entry in var.node_pools, autoscaling, Workload
# Identity metadata mode enabled on every node (required for WI to function).
# -----------------------------------------------------------------------------
resource "google_container_node_pool" "this" {
  for_each = var.node_pools

  project  = var.project_id
  name     = each.key
  location = var.region
  cluster  = google_container_cluster.this.name

  autoscaling {
    min_node_count = each.value.min_node_count
    max_node_count = each.value.max_node_count
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = each.value.machine_type
    disk_size_gb = each.value.disk_size_gb
    disk_type    = "pd-standard"
    preemptible  = each.value.preemptible

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    labels = each.value.labels

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }
}