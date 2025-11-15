variable "instance_count" {
  description = "Number of instances"
  type        = number
  validation {
    condition     = var.instance_count >= 1
    error_message = "instance_count must be >= 1"
  }

}
variable "machine_type" {
  description = "GCP machine type"
  type        = string

}
variable "image_name" {
  description = "Custom image name built by Packer (required when use_latest_image is false)"
  type        = string
  default     = ""
}
variable "use_latest_image" {
  description = "If true, uses the latest image from custom-apache family. If false, uses image_name variable"
  type        = bool
  default     = false
}
variable "zone" {
  description = "GCP zone"
  type        = string

}
