terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  // The provider will automatically use the subscription from your Azure CLI session.
  skip_provider_registration = true
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "Hawkins"
  location = "West Europe"
}

resource "azurerm_app_service_plan" "main" {
  name                = "asp-devops-lab"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku {
    tier = "Free"
    size = "F1"
  }
}

resource "azurerm_app_service" "webapp" {
  name                = "webapp-devops-lab-2026"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  app_service_plan_id = azurerm_app_service_plan.main.id
}