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
# - Network Security Group for Azure Bastion
#

resource "azurerm_resource_group" "rg" {
    name        =       "bastion-test-rg"
    location    =       "eastus"
}

resource "azurerm_network_security_group" "nsg" {
  name                        =       "bastion-nsg"
  resource_group_name         =       azurerm_resource_group.rg.name
  location                    =       azurerm_resource_group.rg.location

  dynamic "security_rule"   {
      for_each  =   local.nsgrules
      content {
          name                          =       security_rule.value.name
          priority                      =       security_rule.value.priority
          direction                     =       security_rule.value.direction
          access                        =       security_rule.value.access
          protocol                      =       security_rule.value.protocol
          source_port_range             =       security_rule.value.source_port_range
          destination_port_range        =       security_rule.value.destination_port_range
          source_address_prefix         =       security_rule.value.source_address_prefix
          destination_address_prefix    =       security_rule.value.destination_address_prefix
      }
  }
}


locals {
    nsgrules   =   [
        {
            "name"                        =       "Bastion-in-allow",
            "priority"                    =       100,
            "direction"                   =       "Inbound",
            "access"                      =       "Allow",
            "protocol"                    =       "TCP",
            "source_port_range"           =       "*",
            "destination_port_range"      =       443,
            "source_address_prefix"       =       "*",
            "destination_address_prefix"  =       "*"
        },
        {
            "name"                        =       "Bastion-control-in-allow",
            "priority"                    =       120,
            "direction"                   =       "Inbound",
            "access"                      =       "Allow",
            "protocol"                    =       "TCP",
            "source_port_range"           =       "*",
            "destination_port_range"      =       "443",
            "source_address_prefix"       =       "GatewayManager",
            "destination_address_prefix"  =       "*"
        },
        {
            "name"                        =       "Bastion-in-deny",
            "priority"                    =       900,
            "direction"                   =       "Inbound",
            "access"                      =       "Deny",
            "protocol"                    =       "*",
            "source_port_range"           =       "*",
            "destination_port_range"      =       "*",
            "source_address_prefix"       =       "*",
            "destination_address_prefix"  =       "*"
        },
        {
            "name"                        =       "Bastion-vnet-out-allow-ssh",
            "priority"                    =       100,
            "direction"                   =       "Outbound",
            "access"                      =       "Allow",
            "protocol"                    =       "TCP",
            "source_port_range"           =       "*",
            "destination_port_range"      =       22,
            "source_address_prefix"       =       "*",
            "destination_address_prefix"  =       "VirtualNetwork"
        },
        {
            "name"                        =       "Bastion-vnet-out-allow-rdp",
            "priority"                    =       110,
            "direction"                   =       "Outbound",
            "access"                      =       "Allow",
            "protocol"                    =       "TCP",
            "source_port_range"           =       "*",
            "destination_port_range"      =       3389,
            "source_address_prefix"       =       "*",
            "destination_address_prefix"  =       "VirtualNetwork"
        },
        {
            "name"                        =       "Bastion-azure-out-allow",
            "priority"                    =       120,
            "direction"                   =       "Outbound",
            "access"                      =       "Allow",
            "protocol"                    =       "TCP",
            "source_port_range"           =       "*",
            "destination_port_range"      =       "443",
            "source_address_prefix"       =       "*",
            "destination_address_prefix"  =       "AzureCloud"
        }

    ]
}