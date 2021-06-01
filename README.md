# Azure Firewall with Terraform (Work in progress)

- [Azure Firewall (Standard) deployment with Terraform](https://github.com/TerraformingCloud/Azure-Firewall-with-Terraform/blob/master/Standard-Firewall)
- [Azure Firewall (Premium) deployment with Terraform](https://github.com/TerraformingCloud/Azure-Firewall-with-Terraform/blob/master/Premium-Firewall)

We are going use Hashicorp Terraform to create the resources required to test new features of the Azure Firewall resource.

## Resource List

|    Resource Type                              |     Resource Name in Terraform                                    |
|    ---                                        |     ---                                                           |
|   A Resource Group                            |     azurerm_resource_group                                        |
|   A Virtual Network                           |     azurerm_virtual_network                                       |
|   3 Subnets (VM, Bastion and Firewall)        |     azurerm_subnet                                                |
|   2 Public IPs (Bastion and Firewall)         |     azurerm_public_ip                                             |
|   Azure Bastion                               |     azurerm_bastion_host                                          |
|   A Network Interface                         |     azurerm_network_interface                                     |
|   A Windows 10 Virtual Machine                |     azurerm_windows_virtual_machine                               |
|   Azure Firewall                              |     azurerm_firewall                                              |
|   Azure Firewall Policy                       |     azurerm_firewall_policy                                       |
|   Azure Firewall Policy Rule Collection Group |     azurerm_firewall_policy_rule_collection_group                 |
|   A Route Table                               |     azurerm_route_table                                           |
|   A Route (UDR)                               |     azurerm_route                                                 |
|   Subnet-RouteTable Association               |     azurerm_subnet_route_table_association                        |
