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
  description = "Custom image name built by Packer (required)"
  type        = string
  # No default - must be provided via command line or tfvars
}
variable "zone" {
  description = "GCP zone"
  type        = string

}
