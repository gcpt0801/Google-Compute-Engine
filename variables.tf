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
  description = "Optional: custom image name to use for boot disk. Leave empty to use default Ubuntu image."
  type        = string
  default     = ""
}
variable "zone" {
  description = "GCP zone"
  type        = string

}
