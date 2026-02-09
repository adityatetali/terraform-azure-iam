# Terraform Cloud Configuration
# This file configures Terraform Cloud as the backend

terraform {
  cloud {
    organization = "adityatetaliorg"

    workspaces {
      name = "terraform-azure-iam-module"
    }
  }
}
