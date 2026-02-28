resource "aws_s3_bucket" "my_bucket" {
  bucket = "terra-buck-et123" # Change this to a unique bucket name

  tags = {
    Name        = "My Terraform Bucket for secure state management"
    Environment = "Dev"
  }
}
