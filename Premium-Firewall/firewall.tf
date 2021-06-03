#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*
#*               Azure Firewall Module                #*                                    
#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*

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
  name                  =     "${var.prefix}-core-rg"
  location              =     local.rglocation
  tags                  =     var.tags
}

resource "azurerm_resource_group" "user-rg" {
  name                  =     "${var.prefix}-user-rg"
  location              =     local.rglocation
  tags                  =     var.tags
}

#
# - Virtual Network
#

resource "azurerm_virtual_network" "vnet" {
  name                  =   "${var.prefix}-vnet"
  resource_group_name   =   azurerm_resource_group.rg.name
  location              =   azurerm_resource_group.rg.location
  address_space         =   [local.vnet_address_range]
  tags                  =   var.tags
}

#
# - Subnets
#

resource "azurerm_subnet" "sn" {
  for_each              =   var.subnets
  name                  =   each.key
  resource_group_name   =   azurerm_resource_group.rg.name
  virtual_network_name  =   azurerm_virtual_network.vnet.name
  address_prefixes      =   [each.value]
}

#
# - Network Security Group
#

# resource "azurerm_network_security_group" "nsg" {
#   name                        =       "${var.prefix}-nsg"
#   resource_group_name         =       azurerm_resource_group.rg.name
#   location                    =       azurerm_resource_group.rg.location
#   tags                        =       var.tags

#   security_rule {
#   name                        =       "Allow_Https"
#   priority                    =       1000
#   direction                   =       "Inbound"
#   access                      =       "Allow"
#   protocol                    =       "Tcp"
#   source_port_range           =       "*"
#   destination_port_range      =       443
#   source_address_prefix       =       "*" 
#   destination_address_prefix  =       "*"
  
#   }
# }


# #
# # - Subnet-NSG Association
# #

# resource "azurerm_subnet_network_security_group_association" "subnet-nsg" {
#   subnet_id                    =       azurerm_subnet.sn["User-VM-Subnet"].id
#   network_security_group_id    =       azurerm_network_security_group.nsg.id
# }


#
# - Public IP Addresses
#


resource "azurerm_public_ip" "pubIP" {
  count                     =       length(local.pubIPnames)
  name                      =       "${var.prefix}-${local.pubIPnames[count.index]}"
  resource_group_name       =       azurerm_resource_group.rg.name
  location                  =       azurerm_resource_group.rg.location
  allocation_method         =       local.pubipAllocation
  sku                       =       local.pubipSKU
  tags                      =       var.tags
}


#
# - Bastion Host
#

resource "azurerm_bastion_host" "bastion" {
  name                      =       "${var.prefix}-bastion"
  resource_group_name       =       azurerm_resource_group.rg.name
  location                  =       azurerm_resource_group.rg.location
  tags                      =       var.tags

  ip_configuration          {
    name                    =       "bastion-config"
    subnet_id               =       azurerm_subnet.sn["AzureBastionSubnet"].id
    public_ip_address_id    =       azurerm_public_ip.pubIP[0].id
  }
}


#
# - Azure Firewall Policy
#

resource "azurerm_firewall_policy" "fw" {
  name                      =       "${var.prefix}-firewall-policy"
  resource_group_name       =       azurerm_resource_group.rg.name
  location                  =       azurerm_resource_group.rg.location
  sku                       =       local.fw_policy_sku  
  tags                      =       var.tags

}


#
# - Azure Firewall Policy Rule Collection Group
#



resource "azurerm_firewall_policy_rule_collection_group" "network" {
  name                      =       "DefaultNetworkRuleCollectionGroup"
  firewall_policy_id        =       azurerm_firewall_policy.fw.id
  priority                  =       200

  network_rule_collection {
    name                    =       "networkrules"
    priority                =       500
    action                  =       "Allow"

    dynamic "rule" {
      for_each                =   local.ncg_rules
      content   {
        name                  =   rule.value.name
        protocols             =   rule.value.protocols
        source_addresses      =   rule.value.source_addresses
        destination_addresses =   rule.value.destination_addresses
        destination_ports     =   rule.value.destination_ports
      }
    }
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "application" {
  name                      =       "DefaultApplicationRuleCollectionGroup"
  firewall_policy_id        =       azurerm_firewall_policy.fw.id
  priority                  =       300

  application_rule_collection {
    name                    =       "acg_rule1"
    priority                =       200
    action                  =       "Allow"

    dynamic "rule" {
        for_each  =  local.acg_rules
        content  {
            name              =   rule.value.name
            protocols   {
            type    =   rule.value.type
            port    =   rule.value.port
            }
            source_addresses  =   rule.value.source_addresses
            destination_fqdns =   rule.value.destination_fqdns
      }
    }
  }
}

# resource "azurerm_firewall_policy_rule_collection_group" "application" {
#   name                      =       "DefaultApplicationRuleCollectionGroup"
#   firewall_policy_id        =       azurerm_firewall_policy.fw.id
#   priority                  =       300


#   application_rule_collection {
#     name                    =       local.application_rcg_app_rule.name
#     priority                =       local.application_rcg_app_rule.priority
#     action                  =       local.application_rcg_app_rule.action
    
#     rule                    {
#       name                  =       local.application_rcg_app_rule.rule1.name
#       protocols             {
#         type                =       local.application_rcg_app_rule.rule1.protocols_type
#         port                =       local.application_rcg_app_rule.rule1.protocols_port
#       }
#       source_addresses      =       local.application_rcg_app_rule.rule1.source_addresses
#       destination_fqdns     =       local.application_rcg_app_rule.rule1.destination_fqdns
#     }

#     rule                    {
#       name                  =       local.application_rcg_app_rule.rule2.name
#       protocols             {
#         type                =       local.application_rcg_app_rule.rule2.protocols_type
#         port                =       local.application_rcg_app_rule.rule2.protocols_port
#       }
#       source_addresses      =       local.application_rcg_app_rule.rule2.source_addresses
#       destination_fqdns     =       local.application_rcg_app_rule.rule2.destination_fqdns
#     }
#   }
# }


#
# - Azure Firewall
#

resource "azurerm_firewall" "fw" {
  name                      =       "${var.prefix}-firewall"
  resource_group_name       =       azurerm_resource_group.rg.name
  location                  =       azurerm_resource_group.rg.location
  sku_name                  =       local.fw_sku_name 
  sku_tier                  =       local.fw_sku_tier
  firewall_policy_id        =       azurerm_firewall_policy.fw.id   
  tags                      =       var.tags

  ip_configuration {
    name                    =       "fw-config"
    subnet_id               =       azurerm_subnet.sn["AzureFirewallSubnet"].id
    public_ip_address_id    =       azurerm_public_ip.pubIP[1].id
  }

  depends_on                =       [azurerm_firewall_policy.fw, azurerm_firewall_policy_rule_collection_group.network, azurerm_firewall_policy_rule_collection_group.application ]
}

#
# - Route Table
# 

resource "azurerm_route_table" "rt" {
  name                          =     "${var.prefix}-uservm-routetable"
  location                      =     azurerm_resource_group.rg.location
  resource_group_name           =     azurerm_resource_group.rg.name
  disable_bgp_route_propagation =     false

  route {
    name                        =     var.rtVars["name"]
    address_prefix              =     var.rtVars["address_prefix"]
    next_hop_type               =     var.rtVars["next_hop_type"]
    next_hop_in_ip_address      =     azurerm_firewall.fw.ip_configuration[0].private_ip_address
  }

  tags                          =     var.tags
}

#
# - Subnet  - Route Table Association


resource "azurerm_subnet_route_table_association" "subnet-rt" {
  subnet_id                   =     azurerm_subnet.sn["User-VM-Subnet"].id
  route_table_id              =     azurerm_route_table.rt.id
}