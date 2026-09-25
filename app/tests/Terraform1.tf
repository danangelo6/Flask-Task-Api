terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.49.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "env1-network-rg"
  location = "North Europe"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "env1-vnet"
  address_space       = ["10.128.6.0/24"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_servers         = ["10.128.6.8", "10.128.6.9"]
}

resource "azurerm_subnet" "subnet1" {
  name                 = "pearl"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.128.6.64/26"]
}

resource "azurerm_subnet" "subnet2" {
  name                 = "diamond"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.128.6.128/25"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "env1-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet_network_security_group_association" "nsgassoc" {
  subnet_id                 = azurerm_subnet.subnet2.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
