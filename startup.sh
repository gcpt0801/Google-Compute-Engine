#!/bin/bash
set -e

# Update package lists and install Apache non-interactively
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y apache2

# Ensure Apache is enabled and started
systemctl enable --now apache2 || service apache2 start || true