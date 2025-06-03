provider "google" {
  credentials = file(var.gcp_credential_file)

  project = var.gcp_project
  region  = var.gcp_region
  zone    = var.gcp_region_zone
}
