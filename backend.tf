terraform {
  backend "gcs" {
    bucket = "gke-terraform-state-lab" # name bucket where i will be save state terraform 
    prefix = "gke-cluster" #under catalogue in bucket 
  }
}
