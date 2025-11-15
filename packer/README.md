# Packer Template Documentation - Apache2 Custom Image for GCP

## Overview

This Packer template automates the creation of a custom Google Cloud Platform (GCP) machine image with Apache2 web server pre-installed. Instead of manually installing Apache2 every time you create a new VM instance, this template "bakes" Apache2 into a reusable machine image.

## What is Packer?

**Packer** is an open-source tool by HashiCorp that automates the creation of machine images. Think of it as a recipe that:
1. Spins up a temporary VM
2. Installs and configures software
3. Creates an image (snapshot) of that configured VM
4. Deletes the temporary VM
5. Saves the image for reuse

## File Structure

```
packer/
├── template.pkr.hcl    # Main Packer configuration file
└── README.md           # This documentation
```

## Template Breakdown

### 1. Variables Section

```hcl
variable "project_id" {
  type = string
}

variable "image_name" {
  type    = string
  default = "custom-apache-image"
}
```

**What it does:**
- Defines input variables that can be passed when running Packer
- `project_id`: Your GCP project ID (required - no default)
- `image_name`: Name for the final image (no default - must be provided)

**Why use variables?**
- Makes the template reusable across different projects
- Allows dynamic image naming (essential for CI/CD pipelines)

**CI/CD Integration:**
In the GitHub Actions workflow, image names are automatically generated using:
```yaml
image_name=custom-apache-image-${{ github.run_id }}
```
This creates unique, versioned images like:
- `custom-apache-image-19388339951`
- `custom-apache-image-19400123456`

Each workflow run produces a new image version that Terraform can use.

### 2. Packer Block

```hcl
packer {
  required_plugins {
    googlecompute = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}
```

**What it does:**
- Declares which Packer plugins are needed
- The `googlecompute` plugin enables Packer to work with Google Cloud Platform

**Plugin details:**
- **Name:** googlecompute
- **Version:** 1.0.0 or higher
- **Source:** Official HashiCorp repository on GitHub

### 3. Source Block

```hcl
source "googlecompute" "apache" {
  project_id          = var.project_id
  zone                = "us-central1-a"
  machine_type        = "e2-medium"
  source_image_family = "ubuntu-2204-lts"
  disk_size           = 10
  image_name          = var.image_name
  ssh_username        = "packer"
}
```

**What it does:**
- Defines the builder configuration for creating the image
- Specifies where and how to create the temporary VM

**Configuration explained:**

| Parameter | Value | Description |
|-----------|-------|-------------|
| `project_id` | `var.project_id` | Your GCP project ID (passed as variable) |
| `zone` | `us-central1-a` | GCP region/zone where temporary VM is created |
| `machine_type` | `e2-medium` | VM size (2 vCPUs, 4GB RAM) - balanced for building |
| `source_image_family` | `ubuntu-2204-lts` | Base OS image (Ubuntu 22.04 LTS) - always uses latest patch |
| `disk_size` | `10` | Disk size in GB for the temporary VM |
| `image_name` | `var.image_name` | Final name for your custom image |
| `ssh_username` | `packer` | Username Packer uses to SSH into the VM |

**Why these settings?**
- **e2-medium:** Cost-effective for build tasks, not too small or large
- **ubuntu-2204-lts:** Long-term support, widely used, stable
- **10GB disk:** Sufficient for Ubuntu + Apache2 + dependencies
- **packer username:** Standard convention, automatically created with sudo access

### 4. Build Block

```hcl
build {
  name    = "apache-image-build"
  sources = ["source.googlecompute.apache"]

  provisioner "shell" {
    inline = [
      "set -e",
      "sudo apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing software-properties-common",
      "sudo add-apt-repository universe -y",
      "sudo apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y apache2",
      "sudo systemctl enable apache2",
      "sudo systemctl stop apache2"
    ]
  }
}
```

**What it does:**
- Orchestrates the actual build process
- Runs provisioners (scripts) to configure the VM

**Build configuration:**
- **name:** Human-readable identifier for this build
- **sources:** References the `source.googlecompute.apache` block defined earlier

### 5. Provisioner - The Installation Script

The `provisioner "shell"` block runs a series of commands on the temporary VM. Let's break down each command:

#### Command 1: `set -e`
```bash
set -e
```
- **Purpose:** Exit immediately if any command fails
- **Why:** Prevents continuing with broken installation
- **Effect:** Build fails fast if something goes wrong

#### Command 2: Update Package Lists
```bash
sudo apt-get update
```
- **Purpose:** Refreshes the local package database
- **Why:** Ensures you get the latest package versions
- **What it does:** Downloads package information from Ubuntu repositories

#### Command 3: Upgrade Existing Packages
```bash
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
```
- **Purpose:** Updates all installed packages to latest versions
- **DEBIAN_FRONTEND=noninteractive:** Prevents prompts during installation
- **-y flag:** Automatically answers "yes" to all prompts
- **Why:** Ensures base image has latest security patches

#### Command 4: Install Software Properties
```bash
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing software-properties-common
```
- **Purpose:** Installs tools for managing software repositories
- **--fix-missing:** Continues if some packages are unavailable
- **Why needed:** Required for the next command to add repositories

#### Command 5: Add Universe Repository
```bash
sudo add-apt-repository universe -y
```
- **Purpose:** Enables the Ubuntu Universe repository
- **Why:** Some Apache2 dependencies are in Universe repo
- **What's Universe:** Contains community-maintained open-source software

#### Command 6: Update Package Lists (Again)
```bash
sudo apt-get update
```
- **Purpose:** Refresh package lists after adding new repository
- **Why:** Makes newly available packages visible to apt

#### Command 7: Install Apache2
```bash
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y apache2
```
- **Purpose:** Installs Apache2 web server and all dependencies
- **What gets installed:**
  - Apache2 core server
  - Configuration files
  - Default website
  - Required libraries
  - SSL/TLS support

#### Command 8: Enable Apache2 Service
```bash
sudo systemctl enable apache2
```
- **Purpose:** Configures Apache2 to start automatically on boot
- **Why:** When you launch a VM from this image, Apache2 will start automatically
- **Technical:** Creates systemd service symlinks

#### Command 9: Stop Apache2 Service
```bash
sudo systemctl stop apache2
```
- **Purpose:** Stops Apache2 before creating the image
- **Why:** 
  - Clean state for the image
  - No running processes consuming resources
  - Prevents potential issues when image is cloned

## How to Use This Template

### Prerequisites

1. **Install Packer**
   ```bash
   # On Linux/Mac
   brew install packer
   
   # On Windows
   choco install packer
   ```

2. **GCP Authentication**
   - Service account JSON key file
   - Set environment variable:
     ```bash
     export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
     ```

3. **Required GCP Permissions**
   - Compute Admin
   - Service Account User

### Running the Template

#### Step 1: Initialize Packer
```bash
cd packer
packer init .
```
**What happens:** Downloads the `googlecompute` plugin

#### Step 2: Validate the Template
```bash
packer validate \
  -var "project_id=your-gcp-project-id" \
  template.pkr.hcl
```
**What happens:** Checks for syntax errors and validates configuration

#### Step 3: Build the Image
```bash
packer build \
  -var "project_id=your-gcp-project-id" \
  -var "image_name=my-apache-image" \
  template.pkr.hcl
```

**What happens:**
1. Packer authenticates to GCP
2. Creates a temporary VM instance
3. Waits for VM to boot
4. Connects via SSH
5. Runs all provisioner commands
6. Stops the VM
7. Creates an image from the VM disk
8. Deletes the temporary VM
9. Outputs the image name

**Expected duration:** 3-5 minutes

### CI/CD Integration

This template is designed for GitHub Actions. The workflow:

1. Triggers on `workflow_dispatch` (manual trigger)
2. Authenticates to GCP
3. Runs Packer build with unique image name: `custom-apache-image-{run_id}`
4. Passes the same image name to Terraform
5. Deploys VMs with the newly built custom image

### Automatic Image Versioning

**Workflow logic:**
```yaml
# Step 1: Packer builds the image
packer build -var "image_name=custom-apache-image-${{ github.run_id }}"

# Step 2: Terraform uses the same image
terraform apply -var "image_name=custom-apache-image-${{ github.run_id }}"
```

**Result:** Every workflow run creates a new, versioned image:
- Run #12345: Creates `custom-apache-image-12345` → Terraform deploys VMs with this image
- Run #67890: Creates `custom-apache-image-67890` → Terraform deploys VMs with this image

**Benefits:**
- 🔄 **Immutable infrastructure:** Each deployment uses a specific image version
- 📦 **Version history:** Keep multiple image versions for rollback
- 🔍 **Traceability:** Match VMs to exact workflow run that created them
- ⚡ **No conflicts:** Parallel builds never overwrite each other

### Image Lifecycle

```
Workflow Triggered
       |
       v
[Packer Build]
   image: custom-apache-image-19388339951
       |
       v
[Image Stored in GCP]
   |
   +---> [Terraform Deploy] ---> VMs boot from this image
   |
   +---> [Available for future use]
   |
   +---> [Can be deleted manually when no longer needed]
```

## Understanding the Build Process

### Visual Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. Packer reads template.pkr.hcl                                │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. Creates temporary e2-medium VM in us-central1-a             │
│    - Base Image: ubuntu-2204-jammy (latest)                     │
│    - Disk: 10GB                                                 │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. Waits for VM to be ready and SSH accessible                 │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. Runs provisioner commands via SSH:                          │
│    ├─ Update package lists                                      │
│    ├─ Upgrade all packages                                      │
│    ├─ Add Universe repository                                   │
│    ├─ Install Apache2                                           │
│    ├─ Enable Apache2 auto-start                                 │
│    └─ Stop Apache2 service                                      │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. Creates machine image from VM disk                          │
│    - Name: custom-apache-image-{run_id}                        │
│    - Location: Global (usable in any region)                   │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ 6. Deletes temporary VM (cleanup)                              │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ 7. Image ready for use in Terraform/GCP Console               │
└─────────────────────────────────────────────────────────────────┘
```

## Common Issues & Troubleshooting

### Issue 1: "ssh_username must be specified"
**Error:** `An ssh_username must be specified`
**Cause:** Missing or malformed ssh_username parameter
**Solution:** Ensure `ssh_username = "packer"` is in the source block

### Issue 2: Permission Denied Errors
**Error:** `E: Could not open lock file /var/lib/apt/lists/lock`
**Cause:** Commands need sudo privileges
**Solution:** All apt-get commands should use `sudo`

### Issue 3: Dependency Issues
**Error:** `Package 'mime-support' has no installation candidate`
**Cause:** Universe repository not enabled
**Solution:** Add `sudo add-apt-repository universe -y` before installing Apache2

### Issue 4: Credentials Error
**Error:** `error getting credentials`
**Cause:** Invalid or missing GCP service account key
**Solution:** Verify `GOOGLE_APPLICATION_CREDENTIALS` environment variable points to valid JSON key

### Issue 5: Image Already Exists
**Error:** `A image with the same name already exists`
**Cause:** Reusing the same image name
**Solution:** Use unique names or delete old images:
```bash
gcloud compute images delete old-image-name
```

## Best Practices

### 1. Image Naming Convention
```bash
# In CI/CD: Use GitHub run ID for automatic versioning
custom-apache-image-${{ github.run_id }}  # Recommended

# Manual builds: Include timestamp or identifier
custom-apache-image-$(date +%s)
custom-apache-image-v1.2.3
```

**Why GitHub run_id?**
- ✅ Automatically unique for every workflow execution
- ✅ Traceable back to specific workflow run
- ✅ No manual intervention needed
- ✅ Terraform uses exact same image name in the same workflow

### 2. Keep Base Image Updated
- Use `source_image_family` instead of specific image version
- Regularly rebuild images to include security patches

### 3. Minimize Image Size
- Only install necessary packages
- Clean up after installation:
  ```bash
  sudo apt-get clean
  sudo rm -rf /var/lib/apt/lists/*
  ```

### 4. Test Before Production
- Build and test images in a dev environment first
- Verify Apache2 starts correctly on the final image

### 5. Version Control
- Keep Packer templates in Git
- Document changes in commit messages

## Advanced Customization

### Adding More Software

Add to the provisioner block:
```hcl
provisioner "shell" {
  inline = [
    "set -e",
    "sudo apt-get update",
    # ... existing commands ...
    "sudo apt-get install -y php libapache2-mod-php",  # Add PHP
    "sudo apt-get install -y mysql-client",             # Add MySQL client
  ]
}
```

### Custom Apache Configuration

```hcl
provisioner "file" {
  source      = "apache-config/custom-site.conf"
  destination = "/tmp/custom-site.conf"
}

provisioner "shell" {
  inline = [
    "sudo mv /tmp/custom-site.conf /etc/apache2/sites-available/",
    "sudo a2ensite custom-site",
    "sudo a2dissite 000-default"
  ]
}
```

### Using Different Base Images

```hcl
source "googlecompute" "apache" {
  # Debian instead of Ubuntu
  source_image_family = "debian-11"
  
  # Or specific Ubuntu version
  source_image = "ubuntu-2204-jammy-v20241111"
}
```

### Multiple Provisioners

```hcl
build {
  name    = "apache-image-build"
  sources = ["source.googlecompute.apache"]

  # Install software
  provisioner "shell" {
    inline = ["sudo apt-get install -y apache2"]
  }

  # Copy files
  provisioner "file" {
    source      = "website/"
    destination = "/tmp/website"
  }

  # Configure
  provisioner "shell" {
    inline = ["sudo cp -r /tmp/website/* /var/www/html/"]
  }
}
```

## Cost Considerations

### Build Costs
- **e2-medium VM:** ~$0.03/hour
- **Typical build time:** 3-5 minutes
- **Cost per build:** < $0.01

### Storage Costs
- **Image storage:** ~$0.05/GB/month
- **Typical image size:** 2-3 GB
- **Monthly cost per image:** ~$0.10-$0.15

### Optimization Tips
- Delete unused images
- Use image families for automatic cleanup
- Schedule regular image rebuilds instead of keeping many versions

## Security Considerations

### 1. Minimize Attack Surface
- Only install required packages
- Remove development tools if not needed

### 2. Security Hardening
```bash
# Disable root SSH login
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# Enable automatic security updates
sudo apt-get install -y unattended-upgrades
```

### 3. Secrets Management
- Never hardcode credentials in templates
- Use GCP Secret Manager for sensitive data
- Inject secrets at runtime, not bake into image

### 4. Image Access Control
- Restrict image access to specific service accounts
- Use IAM policies to control who can use images

## Monitoring Build Process

### Enable Detailed Logging
```bash
PACKER_LOG=1 packer build \
  -var "project_id=your-project" \
  template.pkr.hcl
```

### Debug Mode
```bash
packer build -debug \
  -var "project_id=your-project" \
  template.pkr.hcl
```
**Effect:** Pauses between steps, allows manual inspection

## Next Steps

1. **Verify Image:** Check GCP Console → Compute Engine → Images
2. **Test Image:** Create a test VM using the custom image
3. **Use with Terraform:** Reference image in your Terraform configuration
4. **Automate:** Integrate into CI/CD pipeline

## Additional Resources

- [Packer Documentation](https://www.packer.io/docs)
- [Google Compute Builder](https://www.packer.io/plugins/builders/googlecompute)
- [GCP Machine Images](https://cloud.google.com/compute/docs/images)
- [Apache2 Documentation](https://httpd.apache.org/docs/)

## Questions?

Common questions answered:

**Q: How often should I rebuild images?**
A: Monthly or after major security patches

**Q: Can I use this image in different zones?**
A: Yes, images are global resources

**Q: How do I update Apache config in existing VMs?**
A: Use configuration management (Ansible, Chef) or rebuild image

**Q: Can I build images for multiple cloud providers?**
A: Yes! Packer supports AWS, Azure, DigitalOcean, etc.
