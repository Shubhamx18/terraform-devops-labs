# 🏗️ Terraform

> Essential commands and concepts for infrastructure as code with Terraform.

---

## 📚 Table of Contents

| # | Section |
|---|---------|
| 01 | [⚙️ Core Commands](#️-core-commands) |
| 02 | [🗂️ Workspace Management](#️-workspace-management) |
| 03 | [📦 State Management](#-state-management) |
| 04 | [🔧 Variables & Outputs](#-variables--outputs) |
| 05 | [📁 Modules](#-modules) |
| 06 | [🔌 Providers](#-providers) |
| 07 | [🔍 Inspect & Debug](#-inspect--debug) |
| 08 | [🗄️ Backends & Remote State](#️-backends--remote-state) |
| 09 | [🔐 Secrets & Sensitive Data](#-secrets--sensitive-data) |
| 10 | [📋 Resource Targeting](#-resource-targeting) |
| 11 | [🚀 Import & Move](#-import--move) |
| 12 | [✅ Best Practices & Tips](#-best-practices--tips) |

---

## ⚙️ Core Commands

> The essential Terraform workflow — init, plan, apply, destroy.

### 🔁 Workflow Overview

| Step | Command | Purpose |
|------|---------|---------|
| 1 | `terraform init` | Initialize working directory |
| 2 | `terraform validate` | Validate configuration syntax |
| 3 | `terraform plan` | Preview changes |
| 4 | `terraform apply` | Apply changes |
| 5 | `terraform destroy` | Destroy infrastructure |

### 🛠️ Commands

```bash
# Initialize working directory & download providers
terraform init

# Re-initialize and upgrade providers
terraform init -upgrade

# Validate configuration files
terraform validate

# Preview changes (no apply)
terraform plan

# Save plan to file
terraform plan -out=tfplan

# Apply changes (prompts for confirmation)
terraform apply

# Apply saved plan (no prompt)
terraform apply tfplan

# Auto approve without prompt
terraform apply -auto-approve

# Destroy all managed infrastructure
terraform destroy

# Auto approve destroy
terraform destroy -auto-approve
```

---

## 🗂️ Workspace Management

> Isolate state for multiple environments (dev, staging, prod).

```bash
# List all workspaces
terraform workspace list

# Show current workspace
terraform workspace show

# Create new workspace
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Switch workspace
terraform workspace select dev
terraform workspace select prod

# Delete workspace
terraform workspace delete dev
```

> 💡 Use `${terraform.workspace}` in configs to reference the current workspace name.

```hcl
resource "aws_instance" "app" {
  tags = {
    Environment = terraform.workspace
  }
}
```

---

## 📦 State Management

> Manage and inspect the Terraform state file.

### 🔎 Inspect State

```bash
# List all resources in state
terraform state list

# Show details of a specific resource
terraform state show aws_instance.my_instance

# Show full state as JSON
terraform show -json
```

### ✏️ Modify State

```bash
# Remove a resource from state (without destroying)
terraform state rm aws_instance.my_instance

# Move/rename a resource in state
terraform state mv aws_instance.old_name aws_instance.new_name

# Move resource to a module
terraform state mv aws_instance.app module.web.aws_instance.app

# Pull remote state locally
terraform state pull

# Push local state to remote
terraform state push terraform.tfstate
```

### 🔄 Refresh State

```bash
# Sync state with real infrastructure
terraform refresh

# Refresh during plan
terraform plan -refresh=true
```

---

## 🔧 Variables & Outputs

> Pass values in and get information out of your configurations.

### 📥 Variables

```hcl
# variables.tf
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_count" {
  type    = number
  default = 2
}

variable "tags" {
  type = map(string)
  default = {
    Env  = "dev"
    Team = "ops"
  }
}
```

```bash
# Pass variable via CLI
terraform apply -var="region=us-west-2"

# Pass multiple variables
terraform apply -var="region=us-west-2" -var="instance_count=3"

# Use a .tfvars file
terraform apply -var-file="prod.tfvars"

# Auto-loaded var files (no flag needed)
# terraform.tfvars
# *.auto.tfvars
```

### 📤 Outputs

```hcl
# outputs.tf
output "instance_ip" {
  description = "Public IP of the instance"
  value       = aws_instance.app.public_ip
}

output "db_password" {
  value     = aws_db_instance.main.password
  sensitive = true
}
```

```bash
# Show all outputs
terraform output

# Show specific output
terraform output instance_ip

# Output as JSON
terraform output -json
```

---

## 📁 Modules

> Reuse infrastructure components across configurations.

### 📦 Using a Module

```hcl
# main.tf
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"
}

# Local module
module "app" {
  source = "./modules/app"

  instance_type = "t3.micro"
  region        = var.region
}
```

```bash
# Download/update modules
terraform get

# Initialize (also fetches modules)
terraform init

# Show module outputs
terraform output -module=vpc
```

### 🗂️ Module Structure

```
modules/
└── app/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── README.md
```

---

## 🔌 Providers

> Configure cloud and service providers.

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
  region  = "us-east-1"
  profile = "default"
}

# Alias for multi-region
provider "aws" {
  alias  = "west"
  region = "us-west-2"
}
```

```bash
# List installed providers
terraform providers

# Lock provider versions
terraform providers lock

# Mirror providers locally
terraform providers mirror ./mirror-dir

# Upgrade provider versions
terraform init -upgrade
```

---

## 🔍 Inspect & Debug

> Understand your configuration and troubleshoot issues.

### 🧾 Format & Validate

```bash
# Format all .tf files
terraform fmt

# Format recursively
terraform fmt -recursive

# Check formatting without writing
terraform fmt -check

# Validate syntax and logic
terraform validate
```

### 🔬 Show & Graph

```bash
# Show current state or plan
terraform show

# Show plan file
terraform show tfplan

# Generate dependency graph (DOT format)
terraform graph

# Visualize with Graphviz
terraform graph | dot -Tsvg > graph.svg
```

### 🐛 Debug Logging

```bash
# Enable detailed logs
export TF_LOG=DEBUG
terraform apply

# Log levels: TRACE, DEBUG, INFO, WARN, ERROR
export TF_LOG=TRACE

# Save logs to file
export TF_LOG_PATH=./terraform.log

# Disable logging
export TF_LOG=
```

### 🧮 Console

```bash
# Interactive expression evaluator
terraform console

# Test expressions
> var.region
"us-east-1"
> length(var.tags)
2
> aws_instance.app.public_ip
```

---

## 🗄️ Backends & Remote State

> Store state remotely for team collaboration.

### ☁️ S3 Backend (AWS)

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}
```

### 🌐 Terraform Cloud Backend

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

### 🔁 Migrate State

```bash
# Re-initialize after changing backend
terraform init -migrate-state

# Reconfigure backend without migrating
terraform init -reconfigure
```

---

## 🔐 Secrets & Sensitive Data

> Handle passwords, tokens, and keys safely.

```hcl
# Mark output as sensitive
output "db_password" {
  value     = aws_db_instance.main.password
  sensitive = true
}

# Mark variable as sensitive
variable "api_key" {
  type      = string
  sensitive = true
}
```

```bash
# Pass secrets via environment variables (never hardcode)
export TF_VAR_api_key="my-secret-key"
export TF_VAR_db_password="super-secret"

terraform apply
```

> ⚠️ Never commit `.tfvars` files with secrets. Add to `.gitignore`:

```
*.tfvars
*.tfstate
*.tfstate.backup
.terraform/
```

---

## 📋 Resource Targeting

> Apply or destroy specific resources selectively.

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

> ⚠️ Use `-target` sparingly — it can cause state drift if overused.

---

## 🚀 Import & Move

> Bring existing infrastructure under Terraform management.

### 📥 Import

```bash
# Import existing resource into state
terraform import aws_instance.app i-1234567890abcdef0

# Import into a module
terraform import module.web.aws_instance.app i-1234567890abcdef0
```

```hcl
# Terraform 1.5+ — import block (declarative)
import {
  to = aws_instance.app
  id = "i-1234567890abcdef0"
}
```

### 🔄 Moved Block

```hcl
# Rename/move resource without destroy & recreate
moved {
  from = aws_instance.old_name
  to   = aws_instance.new_name
}

# Move into a module
moved {
  from = aws_instance.app
  to   = module.web.aws_instance.app
}
```

---

## ✅ Best Practices & Tips

> Habits and patterns for clean, safe Terraform usage.

### 📁 Recommended File Structure

```
project/
├── main.tf          # Core resources
├── variables.tf     # Input variables
├── outputs.tf       # Output values
├── versions.tf      # Provider & TF version locks
├── terraform.tfvars # Variable values (gitignored if secrets)
└── modules/
    └── app/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

### 🏷️ Common Variable Types

| Type | Example |
|------|---------|
| `string` | `"us-east-1"` |
| `number` | `3` |
| `bool` | `true` |
| `list(string)` | `["a", "b"]` |
| `map(string)` | `{key = "val"}` |
| `object({...})` | Complex structure |

### 🛡️ Safe Workflow

```bash
# Always plan before apply
terraform plan -out=tfplan
terraform apply tfplan

# Review state before destroying
terraform state list
terraform destroy -target=<resource>

# Format and validate before committing
terraform fmt -recursive
terraform validate
```

### ⚡ Useful Shortcuts

| Command | Purpose |
|---------|---------|
| `terraform init -upgrade` | Upgrade all providers |
| `terraform plan -refresh=false` | Skip refresh for faster plan |
| `terraform apply -auto-approve` | Skip confirmation prompt |
| `terraform output -json` | Machine-readable outputs |
| `terraform fmt -check` | CI formatting check |
| `TF_LOG=DEBUG terraform apply` | Verbose debug output |

---

> 📖 For the most current information, refer to the [official Terraform documentation](https://developer.hashicorp.com/terraform/docs).
