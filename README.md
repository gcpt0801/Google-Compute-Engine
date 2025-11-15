# Google-compute-engine - Automated GCP VM Deployment with Custom Images

## 📋 Project Overview

This project demonstrates Infrastructure as Code (IaC) using **Terraform** and **Packer** to automate the deployment of Google Compute Engine (GCE) instances with pre-configured Apache2 web servers. The solution combines image building automation with infrastructure deployment in a complete CI/CD pipeline.

### Key Features

- 🚀 **Automated Image Building** - Packer creates custom GCE images with Apache2 pre-installed
- 🏗️ **Infrastructure as Code** - Terraform manages VM instances, networking, and firewall rules
- 🔄 **CI/CD Integration** - GitHub Actions automates the entire build and deployment process
- 📦 **Immutable Infrastructure** - VMs are deployed from pre-baked images for consistency
- 🔒 **Security Best Practices** - Service account authentication, least privilege access
- 🌍 **Production Ready** - Environment-specific configurations using `.tfvars` files

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     GitHub Actions Workflow                      │
│                                                                  │
│  ┌────────────┐        ┌────────────┐        ┌──────────────┐  │
│  │   Packer   │  ───►  │   Custom   │  ───►  │  Terraform   │  │
│  │   Build    │        │   Image    │        │    Apply     │  │
│  └────────────┘        └────────────┘        └──────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
        ┌──────────────────────────────────────────────┐
        │         Google Cloud Platform                │
        │                                              │
        │  ┌──────────────┐      ┌──────────────┐    │
        │  │   VM-1       │      │   VM-2       │    │
        │  │   Apache2    │      │   Apache2    │    │
        │  │   Running    │      │   Running    │    │
        │  └──────────────┘      └──────────────┘    │
        │           │                     │           │
        │           └─────────┬───────────┘           │
        │                     │                       │
        │          ┌──────────▼──────────┐           │
        │          │   Firewall Rules    │           │
        │          │   HTTP/HTTPS/SSH    │           │
        │          └─────────────────────┘           │
        └──────────────────────────────────────────────┘
```

## 📁 Project Structure

```
Google-compute-engine/
├── .github/
│   └── workflows/
│       ├── image-build-and-apply.yml    # Combined Packer + Terraform workflow
│       ├── terraform.yml                 # Terraform apply workflow
│       └── terraform-destroy.yml         # Terraform destroy workflow
│
├── packer/
│   ├── template.pkr.hcl                  # Packer template for Apache2 image
│   └── README.md                         # Detailed Packer documentation
│
├── main.tf                               # Main Terraform configuration
├── variables.tf                          # Terraform variable definitions
├── providers.tf                          # GCP provider configuration
├── dev.tfvars                           # Development environment variables
├── startup.sh                           # VM startup script
└── README.md                            # This file
```

## 🛠️ Technology Stack

| Tool | Purpose | Version |
|------|---------|---------|
| **Terraform** | Infrastructure provisioning | 1.5.7 |
| **Packer** | Custom image creation | Latest |
| **Google Cloud Platform** | Cloud infrastructure | - |
| **GitHub Actions** | CI/CD automation | - |
| **Apache2** | Web server | 2.4.x |
| **Ubuntu** | Base operating system | 22.04 LTS |

## 🚀 Getting Started

### Prerequisites

1. **Google Cloud Platform Account**
   - Active GCP project
   - Billing enabled
   - Compute Engine API enabled

2. **Local Tools** (for manual execution)
   - [Terraform](https://www.terraform.io/downloads) (v1.5.7+)
   - [Packer](https://www.packer.io/downloads) (latest)
   - [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)

3. **GCP Service Account**
   - Roles required:
     - Compute Admin
     - Service Account User
   - JSON key file downloaded

### Initial Setup

#### 1. Clone the Repository

```bash
git clone https://github.com/gcpt0801/Google-compute-engine.git
cd Google-compute-engine
```

#### 2. Configure GCP Authentication

```bash
# Set your GCP project ID
export GCP_PROJECT="your-gcp-project-id"

# Set credentials path
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
```

#### 3. Update Configuration Files

Edit `dev.tfvars` to match your requirements:

```hcl
instance_count = 2                  # Number of VM instances
machine_type   = "n2-standard-2"    # VM machine type
zone           = "us-central1-a"    # GCP zone
# image_name is provided by the workflow via -var flag
# Format: custom-apache-image-{github.run_id}
```

**Note:** The `image_name` variable is **required** and must be a Packer-built custom image. The GitHub Actions workflow automatically generates unique image names using `github.run_id` (e.g., `custom-apache-image-19388339951`).

## 📦 Deployment Methods

### Method 1: Automated Deployment (Recommended)

Using GitHub Actions workflow:

1. **Configure GitHub Secrets**
   
   Go to: `Settings → Secrets and variables → Actions`
   
   Add secret:
   - **Name:** `GCP_SA_KEY`
   - **Value:** Paste entire contents of your service account JSON key

2. **Trigger Workflow**
   
   Go to: `Actions → Build image and apply Terraform → Run workflow`
   
   The workflow will:
   - ✅ Build custom Apache2 image using Packer with unique name (custom-apache-image-{run_id})
   - ✅ Deploy VMs using Terraform with the newly built image
   - ✅ Configure firewall rules
   - ✅ Output VM IP addresses
   
   **Image Naming:** Each workflow run generates a unique image name using GitHub's `run_id`. For example:
   - Run #1: `custom-apache-image-19388339951`
   - Run #2: `custom-apache-image-19400123456`
   
   This ensures every deployment uses a fresh, versioned image.

3. **Monitor Progress**
   
   Watch the workflow execution in the Actions tab

### Method 2: Manual Deployment

#### Step 1: Build Custom Image with Packer

```bash
# Navigate to packer directory
cd packer

# Initialize Packer
packer init .

# Build the image
packer build \
  -var "project_id=${GCP_PROJECT}" \
  -var "image_name=custom-apache-image-$(date +%s)" \
  template.pkr.hcl

# Note the output image name
```

#### Step 2: Deploy Infrastructure with Terraform

```bash
# Return to root directory
cd ..

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan \
  -var "image_name=custom-apache-image-XXXXX" \
  -var-file="dev.tfvars"

# Apply the configuration
terraform apply \
  -var "image_name=custom-apache-image-XXXXX" \
  -var-file="dev.tfvars" \
  -auto-approve
```

#### Step 3: Verify Deployment

```bash
# Get VM IP addresses
terraform output

# Test web server
curl http://<VM_IP_ADDRESS>
```

## 🔧 Configuration Details

### Packer Configuration

**File:** `packer/template.pkr.hcl`

**What it does:**
- Creates temporary VM in GCP
- Installs Apache2 web server
- Configures Apache2 to start on boot
- Creates machine image
- Cleans up temporary resources

**Variables:**
- `project_id` - GCP project ID (required)
- `image_name` - Name for the custom image (default: "custom-apache-image")

**Build time:** ~3-5 minutes

### Terraform Configuration

**Main Resources:**

| Resource | Description | Configuration |
|----------|-------------|---------------|
| `google_compute_instance` | VM instances | n2-standard-2, 20GB disk |
| `google_compute_firewall` | HTTP/HTTPS access | Ports 80, 443 |
| `google_compute_firewall` | SSH access | Port 22 |

**Variables:**

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `project_id` | string | - | GCP project ID |
| `region` | string | us-central1 | GCP region |
| `zone` | string | us-central1-a | GCP zone |
| `instance_count` | number | 2 | Number of VMs |
| `machine_type` | string | n2-standard-2 | VM size |
| `image_name` | string | **required** | Custom Packer image (auto-generated in workflow) |

**Important:** `image_name` has no default value and must be provided. The GitHub Actions workflow automatically passes this using `custom-apache-image-${{ github.run_id }}`.

## 🔄 CI/CD Workflows

### 1. Build Image and Apply Terraform

**File:** `.github/workflows/image-build-and-apply.yml`

**Trigger:** Manual (`workflow_dispatch`)

**Steps:**
1. Checkout code
2. Authenticate to GCP
3. Install Packer
4. Build custom image
5. Setup Terraform
6. Apply infrastructure

**Duration:** ~8-10 minutes

**Image Versioning:** Each workflow execution creates a new image with a unique name based on the GitHub run ID. This provides:
- **Traceability:** Match deployed VMs to specific workflow runs
- **Rollback capability:** Keep multiple image versions for easy rollback
- **Immutable infrastructure:** Each deployment uses a specific versioned image
- **No conflicts:** Multiple builds never overwrite each other

Example image progression:
```
custom-apache-image-19388339951  (First build)
custom-apache-image-19400123456  (Second build - next day)
custom-apache-image-19412567890  (Third build - after updates)
```

### 2. Terraform Apply Only

**File:** `.github/workflows/terraform.yml`

**Trigger:** Push to main, Pull requests

**Use case:** Deploy using existing image

### 3. Terraform Destroy

**File:** `.github/workflows/terraform-destroy.yml`

**Trigger:** Manual

**Use case:** Clean up all infrastructure

## 🧪 Testing

### Verify VM Deployment

```bash
# List all instances
gcloud compute instances list

# Get instance details
gcloud compute instances describe <instance-name> --zone=us-central1-a
```

### Test Web Server

```bash
# Get external IP
EXTERNAL_IP=$(gcloud compute instances describe <instance-name> \
  --zone=us-central1-a \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

# Test HTTP response
curl http://${EXTERNAL_IP}

# Expected: Apache2 default page HTML
```

### SSH into Instance

```bash
gcloud compute ssh <instance-name> --zone=us-central1-a
```

## 📊 Cost Estimation

### Compute Costs (Monthly)

| Resource | Specification | Estimated Cost |
|----------|--------------|----------------|
| 2x n2-standard-2 VMs | 2 vCPU, 8GB RAM | ~$100/month |
| 2x 20GB Standard Disks | Persistent storage | ~$4/month |
| External IP addresses | 2 static IPs | ~$14/month |
| **Total** | | **~$118/month** |

### Image Storage

| Item | Cost |
|------|------|
| Custom image (2-3GB) | ~$0.15/month |

**Note:** Costs vary by region and usage. Use [GCP Pricing Calculator](https://cloud.google.com/products/calculator) for accurate estimates.

## 🔒 Security Considerations

### Authentication & Authorization

- ✅ Service account with minimum required permissions
- ✅ No hardcoded credentials in code
- ✅ GitHub Secrets for sensitive data
- ✅ IAM roles following least privilege principle

### Network Security

- ✅ Firewall rules limiting access to specific ports
- ✅ SSH access can be restricted by IP range
- ✅ HTTPS ready (requires SSL certificate configuration)

### Best Practices Implemented

1. **Immutable Infrastructure** - VMs deployed from pre-baked images
2. **Version Control** - All configurations in Git
3. **Environment Separation** - Use different `.tfvars` for prod/dev
4. **State Management** - Consider using remote state (GCS backend)

## 🐛 Troubleshooting

### Common Issues

#### Issue: Packer build fails with "ssh_username must be specified"

**Solution:** Ensure `ssh_username = "packer"` is in the source block of `template.pkr.hcl`

#### Issue: Terraform fails with "image not found"

**Solution:** 
- Verify image name matches Packer output
- Check image exists: `gcloud compute images list --filter="name:custom-apache"`

#### Issue: Cannot access web server

**Solution:**
- Verify firewall rules: `gcloud compute firewall-rules list`
- Check Apache2 status: `systemctl status apache2`
- Ensure external IP is correct

#### Issue: GitHub Actions workflow fails with credentials error

**Solution:**
- Verify `GCP_SA_KEY` secret is set correctly
- Ensure service account has required permissions
- Check JSON key format is valid

### Debug Commands

```bash
# Check Terraform state
terraform show

# Validate Terraform configuration
terraform validate

# View Packer logs
PACKER_LOG=1 packer build template.pkr.hcl

# SSH and check Apache
gcloud compute ssh <instance-name> --zone=us-central1-a
sudo systemctl status apache2
```

## 🧹 Cleanup

### Destroy Infrastructure

#### Using GitHub Actions

1. Go to `Actions → Terraform Destroy`
2. Click `Run workflow`
3. Confirm destruction

#### Using Terraform CLI

```bash
terraform destroy -var-file="dev.tfvars" -auto-approve
```

### Delete Custom Images

```bash
# List images
gcloud compute images list --filter="name:custom-apache"

# Delete specific image
gcloud compute images delete custom-apache-image-XXXXX
```

## 📚 Additional Documentation

- **Packer Details:** See [packer/README.md](packer/README.md) for comprehensive Packer documentation
- **Terraform Variables:** See [variables.tf](variables.tf) for all configurable options
- **GCP Documentation:** [Google Compute Engine](https://cloud.google.com/compute/docs)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is open source and available under the MIT License.

## 👥 Authors

- **gcpt0801** - Initial work

## 🙏 Acknowledgments

- HashiCorp for Terraform and Packer
- Google Cloud Platform documentation
- Ubuntu community

## 📞 Support

For issues and questions:
- Open an issue in GitHub
- Check existing issues for solutions
- Review documentation in `packer/README.md`

---

**Last Updated:** November 15, 2025

**Project Status:** ✅ Active

