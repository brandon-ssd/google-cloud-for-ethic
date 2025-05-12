# main.tf
provider "google" {
  project = var.project_id
  region  = var.region
}

# Create GKE cluster
resource "google_container_cluster" "primary" {
  name     = "gke-demo-cluster"
  location = var.region

  # We can't create a cluster with no node pool defined, but we want to use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

# Node pool configuration
resource "google_container_node_pool" "primary_nodes" {
  name       = "primary-pool"
  cluster    = google_container_cluster.primary.name
  location   = var.location
  node_count = 1

  node_config {
    machine_type = "e2-medium"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  lifecycle {
    ignore_changes = [
      node_config[0].resource_labels,
      node_config[0].kubelet_config,
      node_config,
    ]
  }
}


# Configure Kubernetes provider
data "google_client_config" "default" {}

data "google_container_cluster" "primary" {
  name     = google_container_cluster.primary.name
  location = var.region
}

provider "kubernetes" {
  host  = "https://${data.google_container_cluster.primary.endpoint}"
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  )
}

# Deployment for weather app
resource "kubernetes_deployment" "weather_app" {
  depends_on = [google_container_node_pool.primary_nodes]

  metadata {
    name = "weather-app"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "weather-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "weather-app"
        }
      }

      spec {
        container {
          image = "gcr.io/${var.project_id}/my-weather-app:v2"
          name  = "weather-app"
          port {
            container_port = 5000
          }
        }
      }
    }
  }
}

# Load balancer service
resource "kubernetes_service" "weather_app" {
  depends_on = [google_container_node_pool.primary_nodes]

  metadata {
    name = "weather-app-lb"
  }

  spec {
    selector = {
      app = "weather-app"
    }

    port {
      port        = 80
      target_port = 5000
    }

    type = "LoadBalancer"
  }
}



terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.58.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.18.1"
    }
  }
}
