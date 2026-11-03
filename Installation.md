# Terraform Reference Guide

A practical reference for infrastructure as code with Terraform: installation, core workflow, state, variables, modules, providers, backends, and operational best practices.

---

## Table of Contents

| #  | Section |
|----|---------|
| 01 | [Installation](#1-installation) |
| 02 | [AWS Authentication Setup](#2-aws-authentication-setup) |
| 03 | [Quick Start: First Project](#3-quick-start-first-project) |
| 04 | [Core Commands](#4-core-commands) |
| 05 | [Workspace Management](#5-workspace-management) |
| 06 | [State Management](#6-state-management) |
| 07 | [Variables, Locals and Outputs](#7-variables-locals-and-outputs) |
| 08 | [Resources, Data Sources and Meta-Arguments](#8-resources-data-sources-and-meta-arguments) |
| 09 | [Modules](#9-modules) |
| 10 | [Providers](#10-providers) |
| 11 | [Inspect and Debug](#11-inspect-and-debug) |
| 12 | [Backends and Remote State](#12-backends-and-remote-state) |
| 13 | [Secrets and Sensitive Data](#13-secrets-and-sensitive-data) |
| 14 | [Resource Targeting](#14-resource-targeting) |
| 15 | [Import and Move](#15-import-and-move) |
| 16 | [Troubleshooting](#16-troubleshooting) |
| 17 | [Best Practices](#17-best-practices) |

---

## 1. Installation

### Prerequisites

- A 64-bit Linux or Windows operating system
- `sudo` access (Linux) or an elevated PowerShell session (Windows)
- Internet access to download packages (a private instance requires a NAT Gateway or equivalent outbound route)
- Credentials for the cloud provider you intend to manage (see Section 2)

### Amazon Linux 2023

```bash
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo dnf install -y terraform
```

### Amazon Linux 2

```bash
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum install -y terraform
```

### RHEL / CentOS / Fedora

```bash
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum install -y terraform
```

For Fedora, use `https://rpm.releases.hashicorp.com/fedora/hashicorp.repo` as the repository URL.

### Ubuntu / Debian

```bash
sudo apt update && sudo apt install -y gnupg software-properties-common curl

wget -O- https://apt.releases.hashicorp.com/gpg | \
  sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update
sudo apt install -y terraform
```

### Manual Binary Installation (any Linux distribution)

```bash
# Replace the version and architecture as required (amd64 or arm64)
TF_VERSION="1.9.8"

curl -LO "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip"
unzip terraform_${TF_VERSION}_linux_amd64.zip
sudo mv terraform /usr/local/bin/
rm terraform_${TF_VERSION}_linux_amd64.zip
```

Check the [official downloads page](https://developer.hashicorp.com/terraform/install) for the latest version number.

### Managing Multiple Versions on Linux (tfenv)

```bash
git clone --depth=1 https://github.com/tfutils/tfenv.git ~/.tfenv
echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

tfenv list-remote          # List available versions
tfenv install 1.9.8        # Install a specific version
tfenv use 1.9.8            # Activate a version
```

### Windows

Run these commands in PowerShell. Use an elevated (Run as administrator) session for system-wide installs.

**Option 1: Windows Package Manager (winget)**

```powershell
winget install --id Hashicorp.Terraform -e
```

**Option 2: Chocolatey**

```powershell
choco install terraform -y
```

**Option 3: Manual installation**

1. Download the Windows AMD64 zip from the [official downloads page](https://developer.hashicorp.com/terraform/install).
2. Extract `terraform.exe` to a folder such as `C:\terraform`.
3. Add that folder to the system `PATH`:

```powershell
[Environment]::SetEnvironmentVariable(
  "Path",
  [Environment]::GetEnvironmentVariable("Path", "Machine") + ";C:\terraform",
  "Machine"
)
```

Close and reopen PowerShell so the new `PATH` takes effect, then verify with `terraform version`.

### Verify the Installation

```bash
terraform version
terraform -help
```

Expected output is similar to the following (`windows_amd64` on Windows):

```
Terraform v1.9.8
on linux_amd64
```

### Enable Tab Completion (Linux: Bash and Zsh)

```bash
terraform -install-autocomplete
```

Restart the shell to activate it.

### Upgrade or Uninstall

**Linux**

```bash
# Upgrade via package manager
sudo dnf upgrade terraform          # Amazon Linux 2023 / Fedora
sudo yum update terraform           # Amazon Linux 2 / RHEL / CentOS
sudo apt update && sudo apt install --only-upgrade terraform   # Ubuntu / Debian

# Uninstall
sudo dnf remove terraform           # or: sudo yum remove terraform / sudo apt remove terraform
```

**Windows (PowerShell)**

```powershell
# Upgrade
winget upgrade --id Hashicorp.Terraform
choco upgrade terraform -y

# Uninstall
winget uninstall --id Hashicorp.Terraform
choco uninstall terraform -y
```

---

## 2. AWS Authentication Setup

Terraform needs credentials to create resources. Choose one method.

### Option A: IAM Role on EC2 (recommended when running on AWS)

Attach an IAM instance profile to the EC2 instance running Terraform. No keys are stored on disk, and the AWS provider detects the role automatically.

### Option B: AWS CLI Profile

```bash
# Install the AWS CLI (Amazon Linux 2023 includes it by default)
aws configure
# Enter: Access Key ID, Secret Access Key, default region, output format

# Verify
aws sts get-caller-identity
```

Terraform reads the `default` profile automatically. To use a named profile:

```hcl
provider "aws" {
  region  = "ap-south-1"
  profile = "my-profile"
}
```

### Option C: Environment Variables

```bash
export AWS_ACCESS_KEY_ID="<access-key-id>"
export AWS_SECRET_ACCESS_KEY="<secret-access-key>"
export AWS_DEFAULT_REGION="ap-south-1"
```

Never hardcode credentials in `.tf` files or commit them to version control.

---

## 3. Quick Start: First Project

```bash
mkdir terraform-demo && cd terraform-demo
```

Create `main.tf`:

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_s3_bucket" "demo" {
  bucket = "my-unique-demo-bucket-12345"

  tags = {
    Name        = "demo-bucket"
    Environment = "dev"
  }
}
```

Run the workflow:

```bash
terraform init      # Download the AWS provider
terraform fmt       # Format the code
terraform validate  # Check syntax
terraform plan      # Preview changes
terraform apply     # Create resources (type "yes" to confirm)
terraform destroy   # Remove everything when finished
```

S3 bucket names are globally unique, so change the name above to something of your own.

---

## 4. Core Commands

The essential Terraform workflow: initialize, plan, apply, destroy.

### Workflow Overview

| Step | Command              | Purpose                          |
|------|----------------------|----------------------------------|
| 1    | `terraform init`     | Initialize the working directory |
| 2    | `terraform validate` | Validate configuration syntax    |
| 3    | `terraform plan`     | Preview changes                  |
| 4    | `terraform apply`    | Apply changes                    |
| 5    | `terraform destroy`  | Destroy managed infrastructure   |

### Commands

```bash
# Initialize working directory and download providers
terraform init

# Re-initialize and upgrade providers
terraform init -upgrade

# Validate configuration files
terraform validate

# Preview changes without applying
terraform plan

# Save the plan to a file
terraform plan -out=tfplan

# Apply changes (prompts for confirmation)
terraform apply

# Apply a saved plan (no prompt)
terraform apply tfplan

# Apply without prompting (use with care, mainly in CI/CD)
terraform apply -auto-approve

# Preview a destroy
terraform plan -destroy

# Destroy all managed infrastructure
terraform destroy

# Destroy without prompting
terraform destroy -auto-approve

# Force a resource to be recreated
terraform apply -replace=aws_instance.app
```

---

## 5. Workspace Management

Workspaces isolate state for multiple environments (for example dev, staging, prod) within the same configuration.

```bash
# List all workspaces
terraform workspace list

# Show the current workspace
terraform workspace show

# Create a new workspace
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Switch workspace
terraform workspace select dev
terraform workspace select prod

# Delete a workspace
terraform workspace delete dev
```

Reference the current workspace name with `terraform.workspace`:

```hcl
resource "aws_instance" "app" {
  # ...
  tags = {
    Environment = terraform.workspace
  }
}
```

For strong isolation between production and non-production, many teams prefer separate directories or separate state backends over workspaces alone.

---

## 6. State Management

The state file maps your configuration to real infrastructure. Treat it as sensitive, since it can contain secrets in plain text.

### Inspect State

```bash
# List all resources in state
terraform state list

# Show details of a specific resource
terraform state show aws_instance.my_instance

# Show the full state as JSON
terraform show -json
```

### Modify State

```bash
# Remove a resource from state (without destroying it)
terraform state rm aws_instance.my_instance

# Rename a resource in state
terraform state mv aws_instance.old_name aws_instance.new_name

# Move a resource into a module
terraform state mv aws_instance.app module.web.aws_instance.app

# Pull remote state to the local machine
terraform state pull

# Push local state to the remote backend
terraform state push terraform.tfstate
```

### Refresh State

`terraform refresh` is deprecated. Use the refresh-only mode instead:

```bash
# Review drift between state and real infrastructure
terraform plan -refresh-only

# Update state to match real infrastructure
terraform apply -refresh-only
```

### Locking

Backends that support locking prevent concurrent runs from corrupting state. If a run is interrupted and leaves a stale lock:

```bash
terraform force-unlock <LOCK_ID>
```

Use this only when you are certain no other run is active.

---

## 7. Variables, Locals and Outputs

### Input Variables

```hcl
# variables.tf
variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "instance_count" {
  description = "Number of instances"
  type        = number
  default     = 2

  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "instance_count must be between 1 and 10."
  }
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default = {
    Env  = "dev"
    Team = "ops"
  }
}
```

Passing values:

```bash
# Via CLI
terraform apply -var="region=us-west-2"
terraform apply -var="region=us-west-2" -var="instance_count=3"

# Via a variable file
terraform apply -var-file="prod.tfvars"

# Via environment variables
export TF_VAR_region="us-west-2"
```

Files loaded automatically without a flag: `terraform.tfvars`, `terraform.tfvars.json`, `*.auto.tfvars`, and `*.auto.tfvars.json`.

Precedence (lowest to highest): defaults, environment variables, `terraform.tfvars`, `*.auto.tfvars`, then `-var` and `-var-file` on the command line.

### Local Values

```hcl
locals {
  name_prefix = "${var.project}-${terraform.workspace}"
  common_tags = merge(var.tags, { ManagedBy = "terraform" })
}

resource "aws_instance" "app" {
  # ...
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-app" })
}
```

### Outputs

```hcl
# outputs.tf
output "instance_ip" {
  description = "Public IP of the instance"
  value       = aws_instance.app.public_ip
}

output "db_password" {
  description = "Database password"
  value       = aws_db_instance.main.password
  sensitive   = true
}
```

```bash
# Show all outputs
terraform output

# Show a specific output
terraform output instance_ip

# Raw value (useful in scripts)
terraform output -raw instance_ip

# JSON output
terraform output -json
```

### Common Variable Types

| Type            | Example                |
|-----------------|------------------------|
| `string`        | `"ap-south-1"`         |
| `number`        | `3`                    |
| `bool`          | `true`                 |
| `list(string)`  | `["a", "b"]`           |
| `set(string)`   | `toset(["a", "b"])`    |
| `map(string)`   | `{ key = "value" }`    |
| `object({...})` | Structured, typed data |

---

## 8. Resources, Data Sources and Meta-Arguments

### Data Sources

Read information about existing resources or external values:

```hcl
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "app" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
}
```

### count

```hcl
resource "aws_instance" "web" {
  count         = 3
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  tags = { Name = "web-${count.index}" }
}
```

### for_each

```hcl
resource "aws_s3_bucket" "buckets" {
  for_each = toset(["logs", "assets", "backups"])
  bucket   = "myorg-${each.key}"
}
```

Prefer `for_each` over `count` when items may be added or removed from the middle of a collection, because `count` identifies resources by position.

### depends_on

```hcl
resource "aws_instance" "app" {
  # ...
  depends_on = [aws_nat_gateway.main]
}
```

### lifecycle

```hcl
resource "aws_instance" "app" {
  # ...
  lifecycle {
    create_before_destroy = true
    prevent_destroy       = true
    ignore_changes        = [tags]
  }
}
```

### Example: VPC with Public and Private Subnets

```hcl
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = "main-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags                    = { Name = "public-subnet" }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  tags       = { Name = "private-subnet" }
}

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  depends_on    = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
```

---

## 9. Modules

Modules package reusable infrastructure components.

### Using a Module

```hcl
# Registry module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"
}

# Local module
module "app" {
  source = "./modules/app"

  instance_type = "t3.micro"
  region        = var.region
}

# Reference a module output
output "vpc_id" {
  value = module.vpc.vpc_id
}
```

```bash
# Download or update modules
terraform get
terraform get -update

# Initialize (also fetches modules)
terraform init
```

### Module Structure

```
modules/
└── app/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── README.md
```

Always pin module versions from a registry or a Git tag to keep builds reproducible.

---

## 10. Providers

```hcl
# versions.tf
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

# Provider configuration
provider "aws" {
  region  = "ap-south-1"
  profile = "default"
}

# Alias for a second region
provider "aws" {
  alias  = "west"
  region = "us-west-2"
}

# Use the alias on a resource
resource "aws_s3_bucket" "replica" {
  provider = aws.west
  bucket   = "myorg-replica"
}
```

```bash
# List providers required by the configuration
terraform providers

# Record provider checksums for multiple platforms
terraform providers lock -platform=linux_amd64 -platform=linux_arm64 -platform=windows_amd64

# Mirror providers locally (for offline or restricted environments)
terraform providers mirror ./mirror-dir

# Upgrade provider versions
terraform init -upgrade
```

Commit `.terraform.lock.hcl` to version control so every team member and pipeline uses identical provider versions.

---

## 11. Inspect and Debug

### Format and Validate

```bash
# Format all .tf files in the current directory
terraform fmt

# Format recursively
terraform fmt -recursive

# Check formatting without writing changes (useful in CI)
terraform fmt -check

# Validate syntax and internal consistency
terraform validate
```

### Show and Graph

```bash
# Show the current state
terraform show

# Show a saved plan
terraform show tfplan

# Generate a dependency graph (DOT format)
terraform graph

# Render with Graphviz
terraform graph | dot -Tsvg > graph.svg
```

### Debug Logging

```bash
# Enable detailed logs
export TF_LOG=DEBUG
terraform apply

# Log levels: TRACE, DEBUG, INFO, WARN, ERROR
export TF_LOG=TRACE

# Write logs to a file
export TF_LOG_PATH=./terraform.log

# Disable logging
unset TF_LOG
unset TF_LOG_PATH
```

### Console

```bash
# Interactive expression evaluator
terraform console

> var.region
"ap-south-1"
> length(var.tags)
2
> cidrsubnet("10.0.0.0/16", 8, 1)
"10.0.1.0/24"
```

---

## 12. Backends and Remote State

Remote backends enable team collaboration, state locking, and safer storage than local files.

### S3 Backend (AWS)

```hcl
terraform {
  backend "s3" {
    bucket       = "my-terraform-state"
    key          = "prod/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true   # S3 native locking (Terraform 1.10+)
  }
}
```

On older Terraform versions, use a DynamoDB table for locking instead:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}
```

Recommended bucket settings: enable versioning, enable default encryption, and block all public access.

### HCP Terraform (Terraform Cloud) Backend

```hcl
terraform {
  cloud {
    organization = "my-org"

    workspaces {
      name = "production"
    }
  }
}
```

### Migrate State

```bash
# Re-initialize after changing the backend and migrate existing state
terraform init -migrate-state

# Reconfigure the backend without migrating state
terraform init -reconfigure
```

### Reading Another Configuration's State

```hcl
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "my-terraform-state"
    key    = "network/terraform.tfstate"
    region = "ap-south-1"
  }
}

# Use: data.terraform_remote_state.network.outputs.vpc_id
```

---

## 13. Secrets and Sensitive Data

```hcl
# Mark an output as sensitive
output "db_password" {
  value     = aws_db_instance.main.password
  sensitive = true
}

# Mark a variable as sensitive
variable "api_key" {
  type      = string
  sensitive = true
}
```

```bash
# Pass secrets through environment variables (never hardcode)
export TF_VAR_api_key="<value>"
export TF_VAR_db_password="<value>"

terraform apply
```

Important notes:

- Sensitive values are hidden in CLI output but are still stored in plain text in the state file. Encrypt and restrict access to the state backend.
- Prefer a secrets manager (AWS Secrets Manager, SSM Parameter Store, HashiCorp Vault) over passing secrets as variables.
- Never commit secrets or state files. Add these entries to `.gitignore`:

```
*.tfvars
*.tfstate
*.tfstate.*
.terraform/
crash.log
```

Do not ignore `.terraform.lock.hcl`; it should be committed.

---

## 14. Resource Targeting

Apply or destroy specific resources selectively.

```bash
# Plan only a specific resource
terraform plan -target=aws_instance.app

# Apply only a specific resource
terraform apply -target=aws_instance.app

# Target a module
terraform apply -target=module.vpc

# Destroy a specific resource
terraform destroy -target=aws_instance.app

# Target multiple resources
terraform apply \
  -target=aws_instance.app \
  -target=aws_security_group.web
```

Use `-target` sparingly. It is intended for exceptional situations such as recovering from errors, and overuse can cause configuration and state to drift apart.

---

## 15. Import and Move

Bring existing infrastructure under Terraform management and refactor safely.

### Import

```bash
# Import an existing resource into state
terraform import aws_instance.app i-1234567890abcdef0

# Import into a module
terraform import module.web.aws_instance.app i-1234567890abcdef0
```

Declarative import block (Terraform 1.5+):

```hcl
import {
  to = aws_instance.app
  id = "i-1234567890abcdef0"
}
```

Generate configuration for imported resources:

```bash
terraform plan -generate-config-out=generated.tf
```

### Moved Block

Rename or relocate a resource without destroying and recreating it:

```hcl
moved {
  from = aws_instance.old_name
  to   = aws_instance.new_name
}

moved {
  from = aws_instance.app
  to   = module.web.aws_instance.app
}
```

---

## 16. Troubleshooting

| Problem | Likely Cause and Fix |
|---------|----------------------|
| `terraform: command not found` | Binary is not on `PATH`. Reinstall or add its directory to `PATH`, then open a new shell. |
| `No valid credential sources found` | AWS credentials are missing. Run `aws configure`, set environment variables, or attach an IAM role. |
| `Error acquiring the state lock` | Another run holds the lock, or a previous run crashed. Wait, or use `terraform force-unlock <ID>` if safe. |
| `Provider produced inconsistent result` | Often a provider bug or eventual consistency. Re-run `terraform apply`; upgrade the provider if it persists. |
| `Error: Unsupported argument` | Argument is misspelled or the provider version is outdated. Check the provider docs and run `terraform init -upgrade`. |
| `init` hangs or times out | No outbound internet. Verify the NAT Gateway, route tables, and security group egress rules. |
| `AlreadyExists` or `BucketAlreadyExists` | The resource exists outside state. Import it, or choose a unique name. |
| Plan shows unexpected changes | Configuration drift. Run `terraform plan -refresh-only` to inspect differences. |
| `Backend configuration changed` | Run `terraform init -reconfigure` or `terraform init -migrate-state`. |

For detailed diagnostics, set `TF_LOG=DEBUG` and write output to a file with `TF_LOG_PATH`.

---

## 17. Best Practices

### Recommended File Structure

```
project/
├── main.tf              # Core resources
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── versions.tf          # Terraform and provider version constraints
├── terraform.tfvars     # Variable values (do not commit if it contains secrets)
├── .terraform.lock.hcl  # Provider lock file (commit this)
└── modules/
    └── app/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

### Safe Workflow

```bash
# Always review a plan before applying
terraform plan -out=tfplan
terraform apply tfplan

# Review state before destroying
terraform state list
terraform destroy -target=<resource>

# Format and validate before committing
terraform fmt -recursive
terraform validate
```

### Guidelines

- Store state remotely with encryption and locking; never keep production state only on a laptop.
- Pin Terraform, provider, and module versions.
- Use separate state per environment and per major component to limit blast radius.
- Keep secrets out of code and version control.
- Use `prevent_destroy` on critical resources such as databases.
- Run `fmt`, `validate`, and `plan` automatically in CI; require review before `apply`.
- Tag every resource consistently (for example `Environment`, `Owner`, `ManagedBy`).
- Prefer `for_each` over `count` for collections.
- Destroy lab and test resources when finished (especially NAT Gateways, Elastic IPs, and load balancers) to avoid unnecessary cost.

### Useful Shortcuts

| Command | Purpose |
|---------|---------|
| `terraform init -upgrade` | Upgrade all providers |
| `terraform plan -refresh=false` | Skip refresh for a faster plan |
| `terraform apply -auto-approve` | Skip the confirmation prompt |
| `terraform output -json` | Machine-readable outputs |
| `terraform fmt -check` | CI formatting check |
| `TF_LOG=DEBUG terraform apply` | Verbose debug output |

---

For the most current information, refer to the [official Terraform documentation](https://developer.hashicorp.com/terraform/docs).
