resource "google_container_cluster" "primary" {
  name     = "gke-cluster"
  location = var.zone

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.network_name
  subnetwork = var.subnetwork_name
  deletion_protection = false  # delete
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "primary-node-pool"
  cluster    = google_container_cluster.primary.name
  location   = var.zone
  node_count = 1

  node_config {
    machine_type = "e2-micro"  # Минимальный тип машины
    disk_size_gb = 20
    disk_type    = "pd-standard"  # HDD, а не SSD

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}

