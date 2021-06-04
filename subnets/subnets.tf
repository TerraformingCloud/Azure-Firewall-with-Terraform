# Provider Block

terraform {
    required_providers  {
        azurerm =   {
            source  =   "hashicorp/azurerm"
        }
    }
}

provider "azurerm" {
    features {}
}


#
# - Resource Group
#

resource "azurerm_resource_group" "rg" {
  name                  =     "core-rg"
  location              =     "eastus"

}

#
# - Virtual Network
#

resource "azurerm_virtual_network" "vnet" {
  name                  =   "core-vnet"
  resource_group_name   =   azurerm_resource_group.rg.name
  location              =   azurerm_resource_group.rg.location
  address_space         =   ["10.2.0.0/16"]
}

#
# - Subnets
#

resource "azurerm_subnet" "sn" {
  count                 =   length(var.subnet_names)
  name                  =   var.subnet_names[count.index]
  resource_group_name   =   azurerm_resource_group.rg.name
  virtual_network_name  =   azurerm_virtual_network.vnet.name
  address_prefixes      =   [var.subnet_cidr[count.index]]
  service_endpoints     =   lookup(var.subnet_service_endpoints, var.subnet_names[count.index], null)
}

variable "subnet_names" {
    default     =   ["DC-VM-Subnet", "User-VM-Subnet", "AzureFirewallSubnet", "AzureBastionSubnet"]
}

variable "subnet_cidr"  {
    default     =   ["10.2.0.0/24", "10.2.1.0/24", "10.2.10.0/26", "10.2.13.0/27"]
}

variable "subnet_service_endpoints" {
    type    =   map(any)
    default =   {
        User-VM-Subnet = ["Microsoft.Storage", "Microsoft.Sql", "Microsoft.KeyVault"],
    }
}

# variable "subnets" {
#     description =   "subnets attributes"
#     type        =   map(string)
#     default     =   {
#         "DC-VM-Subnet"          =   "10.2.0.0/24"
#         "User-VM-Subnet"        =   "10.2.1.0/24"
#         "AzureFirewallSubnet"   =   "10.2.10.0/26"
#         "AzureBastionSubnet"    =   "10.2.13.0/27"
#     }
# }

