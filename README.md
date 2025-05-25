# Topic 5: Creating a GKE Kubernetes Cluster with Terraform and GitHub Actions

---

## Step 1. Create Terraform configuration for GKE

### 1.1. Create configuration files:

* `variables.tf` — declaring variables:

```hcl
variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-east1"  # Change to a region with available quota if needed
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = "primary"
}

variable "node_disk_size" {
  description = "Node disk size (GB)"
  type        = number
  default     = 50
}
```

---

* `provider.tf` — Google provider:

```hcl
provider "google" {
  project = var.project_id
  region  = var.region
}
```

---

* `gke.tf` — create the cluster and node pool with smaller disk size:

```hcl
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region

  remove_default_node_pool = true
  initial_node_count       = 1
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-node-pool"
  cluster    = google_container_cluster.primary.name
  location   = var.region

  node_config {
    machine_type = "e2-medium"
    disk_size_gb = var.node_disk_size
    disk_type    = "pd-standard"
  }

  initial_node_count = 1
}
```

---

* `terraform.tfvars` — real values (DO NOT commit to repo!):

```hcl
project_id = "your-gcp-project-id"
region     = "us-east1"
cluster_name = "primary"
node_disk_size = 50
```

---

## Step 2. Create `.gitignore`

To avoid uploading sensitive and temporary files:

```
# Terraform files to ignore
*.tfstate
*.tfstate.*
.terraform/
terraform.tfvars
*.tfvars.json

# Credentials
gcp-key.json
```

---

## Step 3. Initialize and validate Terraform config

Run locally or in GitHub Actions:

```bash
terraform init
terraform validate
terraform plan -var-file="terraform.tfvars"
```

If you see **"variables file terraform.tfvars does not exist"** error, make sure the `terraform.tfvars` file exists and the path is correct.

---

## Step 4. Create GitHub Actions workflow for automation

In `.github/workflows/terraform-gke.yml` add:

```yaml
name: Terraform GKE

on:
  push:
    branches:
      - master
  pull_request:
  workflow_dispatch:
    inputs:
      action:
        description: 'Terraform action to run'
        required: true
        default: 'plan'
        type: choice
        options:
          - plan
          - apply
          - destroy

jobs:
  terraform:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Set up Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.7

      - name: Create credentials file from secret
        run: |
          echo "${{ secrets.GCP_CREDENTIALS_BASE64 }}" | base64 -d > $HOME/gcp-key.json
          echo "GOOGLE_APPLICATION_CREDENTIALS=$HOME/gcp-key.json" >> $GITHUB_ENV

      - name: Terraform Init
        run: terraform init

      - name: Terraform Plan
        if: ${{ github.event.inputs.action == 'plan' || github.event_name != 'workflow_dispatch' }}
        run: terraform plan -var-file="terraform.tfvars"

      - name: Terraform Apply
        if: ${{ github.event.inputs.action == 'apply' }}
        run: terraform apply -var-file="terraform.tfvars" -auto-approve

      - name: Terraform Destroy
        if: ${{ github.event.inputs.action == 'destroy' }}
        run: terraform destroy -var-file="terraform.tfvars" -auto-approve
```

---

## Step 5. Add secrets to GitHub

* In your GitHub repo, go to **Settings > Secrets and variables > Actions > New repository secret**.
* Add secret named `GCP_CREDENTIALS_BASE64`.
* The value should be your GCP service account JSON key encoded in base64.

Example:

```bash
cat your-gcp-key.json | base64 | pbcopy
```

Paste that into the secret.

---

## Step 6. Run the workflow

* Go to **Actions** tab in GitHub.
* Run the workflow manually via **Run workflow**, choosing action: `plan`, `apply`, or `destroy`.
* Or it runs automatically on push to `master`.

---

## Important recommendations

* If you get a **Quota** error, reduce `node_disk_size` in `terraform.tfvars` or change the region.
* Make sure Kubernetes Engine API is enabled in GCP console.
* Always check your `.gitignore` to avoid committing keys and sensitive files.

