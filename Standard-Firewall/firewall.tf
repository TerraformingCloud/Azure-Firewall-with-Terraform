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
  name                  =     "${var.prefix}-rg"
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
# - Network Interface Card for Virtual Machine
#

resource "azurerm_network_interface" "nic" {
  name                              =   "${var.prefix}-nic"
  resource_group_name               =   azurerm_resource_group.rg.name
  location                          =   azurerm_resource_group.rg.location
  tags                              =   var.tags
  ip_configuration                  {
      name                          =  "${var.prefix}-nic-ipconfig"
      subnet_id                     =   azurerm_subnet.sn["User-VM-Subnet"].id
      private_ip_address_allocation =   local.nic_allocation
  }
}


#
# - Create a Windows 10 Virtual Machine
#

resource "azurerm_windows_virtual_machine" "vm" {
  name                              =   "${var.prefix}-vm"
  resource_group_name               =   azurerm_resource_group.rg.name
  location                          =   azurerm_resource_group.rg.location
  network_interface_ids             =   [azurerm_network_interface.nic.id]
  size                              =   var.vmVars["virtual_machine_size"]
  computer_name                     =   var.vmVars["computer_name"]
  admin_username                    =   var.vmVars["admin_username"]
  admin_password                    =   var.vmVars["admin_password"]

  os_disk  {
      name                          =   "${var.prefix}-os-disk"
      caching                       =   var.vmVars["os_disk_caching"]
      storage_account_type          =   var.vmVars["os_disk_storage_account_type"]
      disk_size_gb                  =   var.vmVars["os_disk_size_gb"]
  }

  source_image_reference {
      publisher                     =   var.vmVars["publisher"]
      offer                         =   var.vmVars["offer"]
      sku                           =   var.vmVars["sku"]
      version                       =   var.vmVars["vm_image_version"]
  }

  tags                              =   var.tags

}

# #
# # - Azure Firewall Policy
# #

# resource "azurerm_firewall_policy" "fw" {
#   name                      =       "${var.prefix}-firewall-policy"
#   resource_group_name       =       azurerm_resource_group.rg.name
#   location                  =       azurerm_resource_group.rg.location
#   sku                       =       local.fw_policy_sku  
#   tags                      =       var.tags

# }


# #
# # - Azure Firewall Policy Rule Collection Group
# #



# resource "azurerm_firewall_policy_rule_collection_group" "network" {
#   name                      =       "DefaultNetworkRuleCollectionGroup"
#   firewall_policy_id        =       azurerm_firewall_policy.fw.id
#   priority                  =       200

#   network_rule_collection {
#     name                    =       local.network_rcg_net_rule.name
#     priority                =       local.network_rcg_net_rule.priority
#     action                  =       local.network_rcg_net_rule.action

#     rule                    {
#       name                  =       local.network_rcg_net_rule.rule1.name
#       protocols             =       local.network_rcg_net_rule.rule1.protocols
#       source_addresses      =       local.network_rcg_net_rule.rule1.source_addresses
#       destination_addresses =       local.network_rcg_net_rule.rule1.destination_addresses
#       destination_ports     =       local.network_rcg_net_rule.rule1.destination_ports
#     }
#   }
# }

# resource "azurerm_firewall_policy_rule_collection_group" "application" {
#   name                      =       "DefaultApplicationRuleCollectionGroup"
#   firewall_policy_id        =       azurerm_firewall_policy.fw.id
#   priority                  =       300

#   application_rule_collection {
#     name                    =       local.application_rcg_app_rule_1.name
#     priority                =       local.application_rcg_app_rule_1.priority
#     action                  =       local.application_rcg_app_rule_1.action
    
#     rule                    {
#       name                  =       local.application_rcg_app_rule_1.rule.name
#       protocols             {
#         type                =       local.application_rcg_app_rule_1.rule.protocols_type
#         port                =       local.application_rcg_app_rule_1.rule.protocols_port
#       }
#       source_addresses      =       local.application_rcg_app_rule_1.rule.source_addresses
#       destination_fqdns     =       local.application_rcg_app_rule_1.rule.destination_fqdns
#     }
#   }

#   application_rule_collection {
#     name                    =       local.application_rcg_app_rule_2.name
#     priority                =       local.application_rcg_app_rule_2.priority
#     action                  =       local.application_rcg_app_rule_2.action
    
#     rule                    {
#       name                  =       local.application_rcg_app_rule_2.rule1.name
#       protocols             {
#         type                =       local.application_rcg_app_rule_2.rule1.protocols_type
#         port                =       local.application_rcg_app_rule_2.rule1.protocols_port
#       }
#       source_addresses      =       local.application_rcg_app_rule_2.rule1.source_addresses
#       destination_fqdns     =       local.application_rcg_app_rule_2.rule1.destination_fqdns
#     }

#     rule                    {
#       name                  =       local.application_rcg_app_rule_2.rule2.name
#       protocols             {
#         type                =       local.application_rcg_app_rule_2.rule2.protocols_type
#         port                =       local.application_rcg_app_rule_2.rule2.protocols_port
#       }
#       source_addresses      =       local.application_rcg_app_rule_2.rule2.source_addresses
#       destination_fqdns     =       local.application_rcg_app_rule_2.rule2.destination_fqdns
#     }
#   }
# }

# # #
# # # - Azure Firewall Policy Rule Collection Group
# # #

# # resource "azurerm_firewall_policy_rule_collection_group" "application" {
# #   name                      =       "DefaultApplicationRuleCollectionGroup"
# #   firewall_policy_id        =       azurerm_firewall_policy.fw.id
# #   priority                  =       300

# #   application_rule_collection {
# #     name                    =       local.application_rcg_app_rule_1.name
# #     priority                =       local.application_rcg_app_rule_1.priority
# #     action                  =       local.application_rcg_app_rule_1.action
    
# #     rule                    {
# #       name                  =       local.application_rcg_app_rule_1.rule.name
# #       protocols             {
# #         type                =       local.application_rcg_app_rule_1.rule.protocols_type
# #         port                =       local.application_rcg_app_rule_1.rule.protocols_port
# #       }
# #       source_addresses      =       local.application_rcg_app_rule_1.rule.source_addresses
# #       destination_fqdns     =       local.application_rcg_app_rule_1.rule.destination_fqdns
# #     }
# #   }

# #   application_rule_collection {
# #     name                    =       local.application_rcg_app_rule_2.name
# #     priority                =       local.application_rcg_app_rule_2.priority
# #     action                  =       local.application_rcg_app_rule_2.action
    
# #     rule                    {
# #       name                  =       local.application_rcg_app_rule_2.rule1.name
# #       protocols             {
# #         type                =       local.application_rcg_app_rule_2.rule1.protocols_type
# #         port                =       local.application_rcg_app_rule_2.rule1.protocols_port
# #       }
# #       source_addresses      =       local.application_rcg_app_rule_2.rule1.source_addresses
# #       destination_fqdns     =       local.application_rcg_app_rule_2.rule1.destination_fqdns
# #     }

# #     rule                    {
# #       name                  =       local.application_rcg_app_rule_2.rule2.name
# #       protocols             {
# #         type                =       local.application_rcg_app_rule_2.rule2.protocols_type
# #         port                =       local.application_rcg_app_rule_2.rule2.protocols_port
# #       }
# #       source_addresses      =       local.application_rcg_app_rule_2.rule2.source_addresses
# #       destination_fqdns     =       local.application_rcg_app_rule_2.rule2.destination_fqdns
# #     }
# #   }
# # }




# #
# # - Azure Firewall
# #

# resource "azurerm_firewall" "fw" {
#   name                      =       "${var.prefix}-firewall"
#   resource_group_name       =       azurerm_resource_group.rg.name
#   location                  =       azurerm_resource_group.rg.location
#   sku_name                  =       local.fw_sku_name 
#   sku_tier                  =       local.fw_sku_tier
#   firewall_policy_id        =       azurerm_firewall_policy.fw.id   
#   tags                      =       var.tags

#   ip_configuration {
#     name                    =       "fw-config"
#     subnet_id               =       azurerm_subnet.sn["AzureFirewallSubnet"].id
#     public_ip_address_id    =       azurerm_public_ip.pubIP[1].id
#   }

#   depends_on                =       [azurerm_firewall_policy.fw, azurerm_firewall_policy_rule_collection_group.network, azurerm_firewall_policy_rule_collection_group.application ]
# }

# #
# # - Route Table
# # 

# resource "azurerm_route_table" "rt" {
#   name                          =     "${var.prefix}-uservm-routetable"
#   location                      =     azurerm_resource_group.rg.location
#   resource_group_name           =     azurerm_resource_group.rg.name
#   disable_bgp_route_propagation =     false

#   route {
#     name                        =     var.rtVars["name"]
#     address_prefix              =     var.rtVars["address_prefix"]
#     next_hop_type               =     var.rtVars["next_hop_type"]
#     next_hop_in_ip_address      =     azurerm_firewall.fw.ip_configuration[0].private_ip_address
#   }

#   tags                          =     var.tags
# }

# #
# # - Subnet  - Route Table Association


# resource "azurerm_subnet_route_table_association" "subnet-rt" {
#   subnet_id                   =     azurerm_subnet.sn["User-VM-Subnet"].id
#   route_table_id              =     azurerm_route_table.rt.id
# }