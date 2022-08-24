terraform {
  cloud {
    organization = "brightblueray"
    workspaces {
      name = "hcp-packer-demo-admin"
    }
  }

  required_providers {

    aws = {
      source = "hashicorp/aws"
    }

    hcp = {
      source = "hashicorp/hcp"
    }

    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

provider "hcp" {}
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "rryjewski-rg"
  location = "eastus2"
}