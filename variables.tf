variable "location" {
  description = "GCP region or zone where the cluster is deployed"
  type        = string
  default     = "us-east1"
}


variable "project_id" {
  description = "Brandon's GCP"
  type        = string
}

variable "region" {
  description = "The region to deploy to"
  type        = string
  default     = "us-east1"
}
