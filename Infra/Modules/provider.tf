terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "6.8.0"
    }
  }
}

provider "google" {
  project = "cts13-mukul"
  region  = "us-central1"
  zone    = "us-central1-c"
}