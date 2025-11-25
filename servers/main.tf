# First, specify the required terraform version and AWS provider.
terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Define the AWS provider and set the region.
provider "aws" {
  region = "eu-west-1"
}

# Variable Definitions
variable "servers" {
  description = "List of servers"
  type        = list(string)
  default     = ["Appweb", "Ecomm", "linux"]
}

variable "instance_type" {
  description = "Type of AWS instance"
  type        = string
  default     = "t2.micro"
}

variable "environment" {
  type    = string
  default = "dev"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

locals {
  ami_id = data.aws_ami.amazon_linux.id
}
resource "aws_instance" "servers" {
  // We can use for-each to iterate over the list of servers.
  // toset is used to convert the list to a set for iteration and to avoid duplicates.
  #for_each      = toset(var.servers)
  // Using count to create instances based on the length of the servers list.
  for_each = toset(var.servers)
  ami           = local.ami_id
  instance_type = var.instance_type == "prod" ? "t2.small" : "t2.micro"

  tags = {
    Name = "${var.environment}-${each.value}"
    Environment = var.environment
  }
}

# Outputs
output "server_ids" {
  description = "Map of server names to instance IDs"
  value = {
    for name, instance in aws_instance.servers :
    name => instance.id
  }
}

output "server_public_ips" {
  description = "Map of server names to public IPs"
  value = {
    for name, instance in aws_instance.servers :
    name => instance.public_ip
  }
}