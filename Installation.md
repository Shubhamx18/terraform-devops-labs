# Install Terraform on Ubuntu

## Step 1: Update packages and install prerequisites

```bash
sudo apt update
sudo apt install -y gnupg software-properties-common curl wget
```

## Step 2: Add the HashiCorp GPG key

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | \
  sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
```

## Step 3: Add the HashiCorp repository

```bash
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list
```

## Step 4: Install Terraform

```bash
sudo apt update
sudo apt install -y terraform
```

## Step 5: Verify

```bash
terraform version
```

You should see `Terraform v1.x.x on linux_amd64`.

## Step 6: Give Terraform AWS access

Attach an **IAM role** to the EC2 instance (EC2 console → Instance → Actions → Security → Modify IAM role). For practice, a role with `AmazonS3FullAccess` is enough for the test below.

Install the AWS CLI (Ubuntu does not include it):

```bash
sudo apt install -y unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
unzip awscliv2.zip
sudo ./aws/install
```

Check access:

```bash
aws sts get-caller-identity
```

If this prints an account ID, you're ready. If the instance has no IAM role, run `aws configure` and enter an access key instead.

## Step 7: Create a test project

```bash
mkdir ~/terraform-demo && cd ~/terraform-demo

cat > main.tf <<EOF
terraform {
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
  bucket = "tf-demo-$RANDOM$RANDOM"
}
EOF
```

## Step 8: Run Terraform

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

Type `yes` when prompted.

## Step 9: Clean up

```bash
terraform destroy
```

Type `yes` when prompted.

## If a step fails

| Error | Fix |
|---|---|
| `apt update` hangs or times out | No outbound internet. On a private instance, add a NAT Gateway route (`0.0.0.0/0 → NAT`) |
| `Could not get lock /var/lib/dpkg/lock` | Wait a minute for background updates, then retry |
| `NO_PUBKEY` or GPG error | Repeat Step 2, then run `sudo apt update` again |
| `E: Unable to locate package terraform` | Repeat Steps 2 to 3, then run `sudo apt update` |
| `terraform: command not found` | Run `hash -r`, or open a new SSH session |
| `No valid credential sources found` | IAM role not attached or `aws configure` not done (Step 6) |
| `Failed to query available provider packages` | No outbound internet to `registry.terraform.io` |
| `AccessDenied` on apply | The IAM role lacks S3 permissions |
