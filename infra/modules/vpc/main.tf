# -----------------------------------------------------------------------------
# VPC network (custom mode — we define every subnet explicitly, no auto subnets)
# -----------------------------------------------------------------------------
resource "google_compute_network" "this" {
  project                 = var.project_id
  name                    = var.network_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# -----------------------------------------------------------------------------
# Subnets — one per environment, each with secondary ranges for GKE
# (GKE needs a pods range and a services range per subnet it uses)
# -----------------------------------------------------------------------------
resource "google_compute_subnetwork" "this" {
  for_each = var.subnets

  project       = var.project_id
  name          = "subnet-${each.key}"
  ip_cidr_range = each.value.ip_cidr_range
  region        = each.value.region
  network       = google_compute_network.this.id

  private_ip_google_access = each.value.private_ip_google_access

  secondary_ip_range {
    range_name    = "${each.key}-pods"
    ip_cidr_range = each.value.pods_cidr_range
  }

  secondary_ip_range {
    range_name    = "${each.key}-services"
    ip_cidr_range = each.value.services_cidr_range
  }

  dynamic "log_config" {
    for_each = var.enable_flow_logs ? [1] : []
    content {
      aggregation_interval = "INTERVAL_5_SEC"
      flow_sampling        = 0.5
      metadata             = "INCLUDE_ALL_METADATA"
    }
  }
}

# -----------------------------------------------------------------------------
# Cloud Router — required for Cloud NAT
# -----------------------------------------------------------------------------
resource "google_compute_router" "this" {
  project = var.project_id
  name    = "${var.network_name}-router"
  region  = var.region
  network = google_compute_network.this.id
}

# -----------------------------------------------------------------------------
# Cloud NAT — lets private nodes (no external IP) reach the internet
# for pulling images, calling external APIs, etc.
# -----------------------------------------------------------------------------
resource "google_compute_router_nat" "this" {
  project                            = var.project_id
  name                               = "${var.network_name}-nat"
  router                             = google_compute_router.this.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# -----------------------------------------------------------------------------
# Baseline firewall: deny all ingress by default, then explicitly allow
# the minimum needed (internal traffic, health checks, IAP for SSH).
# -----------------------------------------------------------------------------
resource "google_compute_firewall" "deny_all_ingress" {
  project   = var.project_id
  name      = "${var.network_name}-deny-all-ingress"
  network   = google_compute_network.this.id
  direction = "INGRESS"
  priority  = 65534

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_internal" {
  project   = var.project_id
  name      = "${var.network_name}-allow-internal"
  network   = google_compute_network.this.id
  direction = "INGRESS"
  priority  = 1000

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }

  # Only traffic originating from within our own subnet ranges
  source_ranges = [for s in var.subnets : s.ip_cidr_range]
}

resource "google_compute_firewall" "allow_health_checks" {
  project   = var.project_id
  name      = "${var.network_name}-allow-health-checks"
  network   = google_compute_network.this.id
  direction = "INGRESS"
  priority  = 1000

  allow {
    protocol = "tcp"
  }

  # GCP's health check IP ranges — required for LB backends to report healthy
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
}

resource "google_compute_firewall" "allow_iap_ssh" {
  project   = var.project_id
  name      = "${var.network_name}-allow-iap-ssh"
  network   = google_compute_network.this.id
  direction = "INGRESS"
  priority  = 1000

  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }

  # IAP's forwarding range — lets you SSH/RDP without a public IP or bastion
  source_ranges = ["35.235.240.0/20"]
}