instance_count = 2
machine_type   = "n2-standard-2"
zone           = "us-central1-a"
# image_name is provided by the workflow via -var flag
# Format: custom-apache-image-{github.run_id}