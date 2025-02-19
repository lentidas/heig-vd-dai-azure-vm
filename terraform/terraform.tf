terraform {
  backend "azurerm" {
    # This Storage Account and Container must already exist. They were created manually.
    resource_group_name  = "remote-terraform-states-rg"
    storage_account_name = "terraformstates864fc5e1"
    container_name       = "tfstate"
    key                  = "heig-vd-dai-vm.tfstate"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = "864fc5e1-6791-459d-817a-201b89d27a4c" # lentidas' Microsoft Azure for Students subscription
}
