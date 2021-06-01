#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*
#*       Azure Firewall Module - Variables            #*                                    
#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*

variable "prefix" {
    default     =       "premiumfw"
}

#Tags

variable "tags" {
    description =   "Resouce tags"
    type        =   map(string)
    default     =   {
        "author"        =   "Vamsi"
        "deployed_with" =   "Terraform"
    }
}


# Vnet and Subnet


variable "subnets" {
    description =   "subnets attributes"
    type        =   map(string)
    default     =   {
        "User-VM-Subnet"        =   "10.2.1.0/24"
        "AzureFirewallSubnet"   =   "10.2.10.0/26"
        "AzureBastionSubnet"    =   "10.2.13.0/27"
    }
}

locals {

    rglocation          =   "centralus"
    vnet_address_range  =   "10.2.0.0/16"
    pubIPnames          =   ["bastion-pubIP", "firewall-pubIP"]
    pubipAllocation     =   "Static"
    pubipSKU            =   "Standard"
    nic_allocation      =   "Dynamic"
    fw_policy_sku       =   "Premium"
    fw_sku_name         =   "AZFW_VNet"
    fw_sku_tier         =   "Premium"

    network_rcg_net_rule          =   {
        name                      =   "Allow_Net-Rule-Collection"
        priority                  =   500
        action                    =   "Allow"
        rule1                     =   {
            name                  =   "allow-outbound-azure-monitor"
            protocols             =   ["TCP"]
            source_addresses      =   ["*"]
            destination_addresses =   ["168.63.129.16"]
            destination_ports     =   ["443", "80", "32526"]
        }
    }

    application_rcg_app_rule_1    =   {
        name                      =   "Deny-App-Rule-Collection"
        priority                  =   500
        action                    =   "Deny"
        rule                      =   {
            name                  =   "deny-all"
            protocols_type        =   "Https"
            protocols_port         =   443
            source_addresses      =   ["*"]
            destination_fqdns     =   ["*"]
        }
    }

    application_rcg_app_rule_2     =   {
        name                      =   "Allow-App-Rule-Collection"
        priority                  =   100
        action                    =   "Allow"
        rule1                     =   {
            name                  =   "Allow-Bing"
            protocols_type        =   "Https"
            protocols_port         =   443
            source_addresses      =   ["*"]
            destination_fqdns     =   ["*.bing.com"]
        }
        rule2                     =   {
            name                  =   "Allow-GitHub"
            protocols_type        =   "Https"
            protocols_port        =   443
            source_addresses      =   ["*"]
            destination_fqdns     =   ["*.github.com"]
        }
    }
}


variable "vmVars"   {
    description         =       "VM Variables"
    type                =       map(string)
    default             =           {
        "virtual_machine_size"          =   "Standard_D2s_v3"
        "computer_name"                 =   "user-vm"
        "admin_username"                =   "win10admin"
        "admin_password"                =   "P@$$w0rD2021*"
        "os_disk_caching"               =   "ReadWrite"
        "os_disk_storage_account_type"  =   "StandardSSD_LRS"
        "os_disk_size_gb"               =   128 
        "publisher"                     =   "MicrosoftWindowsDesktop"
        "offer"                         =   "Windows-10"
        "sku"                           =   "20h2-pro"
        "vm_image_version"              =   "latest"
    }
}

variable "rtVars"   {
    description         =   "Route Variables"
    type                =   map(string)
    default             =   {
        "name"            =   "fw-udr"
        "address_prefix"  =   "0.0.0.0/0"
        "next_hop_type"   =   "VirtualAppliance"
    }
}