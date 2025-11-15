# Data source to get the latest image from the custom-apache family
data "google_compute_image" "latest_custom_apache" {
  family  = "custom-apache"
  project = "gcp-terraform-demo-474514"
}

# Validation: Ensure either use_latest_image is true OR image_name is provided
locals {
  validate_image_config = (
    var.use_latest_image == true || var.image_name != "" ?
    true :
    tobool("ERROR: Either set use_latest_image=true OR provide image_name")
  )
}

resource "google_compute_instance" "default" {
  count        = var.instance_count
  name         = "apacheweb-instance-${count.index + 1}"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["http-server"]

  boot_disk {
    initialize_params {
      image = var.use_latest_image ? data.google_compute_image.latest_custom_apache.self_link : var.image_name
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata_startup_script = file("${path.module}/startup.sh")
}

resource "google_compute_firewall" "http" {
  name    = "allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

output "instance_ips" {
  description = "External IP addresses of the instances"
  value       = google_compute_instance.default[*].network_interface[0].access_config[0].nat_ip
}

output "image_used" {
  description = "The image used for the instances"
  value       = var.use_latest_image ? data.google_compute_image.latest_custom_apache.name : var.image_name
}

output "image_source" {
  description = "How the image was selected"
  value       = var.use_latest_image ? "Latest from custom-apache family" : "Specific image from workflow"
}