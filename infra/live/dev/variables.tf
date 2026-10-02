variable "project_id" {
  description = "Your GCP project ID."
  type        = string
}

variable "region" {
  description = "Primary region for this project."
  type        = string
  default     = "us-central1"
}