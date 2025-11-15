variable "project" {
  type = string
}

variable "image_name" {
  type    = string
  default = "custom-apache-image"
}

source "googlecompute" "apache" {
  project             = var.project
  zone                = "us-central1-a"
  machine_type        = "e2-medium"
  source_image_family = "ubuntu-2204-lts"
  disk_size           = 10
  image_name          = var.image_name
}

build {
  name    = "apache-image-build"
  sources = ["source.googlecompute.apache"]

  provisioner "shell" {
    inline = [
      "set -e",
      "apt-get update",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y apache2",
      "systemctl enable apache2",
      "systemctl stop apache2"
    ]
  }
}
