variable "ec2_ami" {
  default = "ami-0f5ee92e2d63afc18"
     type = string
}

variable "ec2_instance_type" {
     default = "t3.micro" 
     type = string
}


variable "ec2_name" {
     default = "variable"
     type = string
}

# ------------------------------------------------
variable "instance_type" {
  default = {
     default= ["t3.micro"]
     dev = ["t3.micro", "t3.small", "t3.micro"]
     prd = ["t3.micro", "c7i-flex.large"]
  }
}

#--------------------------------------------------
