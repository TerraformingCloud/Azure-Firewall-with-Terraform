#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*
#*       Azure Firewall Module - Outputs              #*                                    
#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*



# output "firewall_config" {
#     value   =  {

#         "Firewall-Name"             =   azurerm_firewall.fw.name
#         "Firewall-PrivateIp"        =   azurerm_firewall.fw.ip_configuration[0].private_ip_address
#         "Firewall-Policy-Name"      =   azurerm_firewall_policy.fw.name
#         "Firewall-Network-RCG"      =   azurerm_firewall_policy_rule_collection_group.network
#         "Firewall-Application-RCG"  =   azurerm_firewall_policy_rule_collection_group.application
#     }
# } 