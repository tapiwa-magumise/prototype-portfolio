terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }

  # Bucket and region are passed at init time: see README "Deploying".
  backend "s3" {
    key          = "portfolio/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}

locals {
  tags = { Project = "portfolio", ManagedBy = "terraform" }
}

provider "aws" {
  region = var.region
  default_tags { tags = local.tags }
}
