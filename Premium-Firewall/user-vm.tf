#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*
#*         Azure Firewall Module - User VM            #*                                    
#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*


#
# - Network Interface Card for Virtual Machine
#

resource "azurerm_network_interface" "user-nic" {
  name                              =   "${var.prefix}-nic"
  resource_group_name               =   azurerm_resource_group.user-rg.name
  location                          =   azurerm_resource_group.user-rg.location
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

resource "azurerm_windows_virtual_machine" "user-vm" {
  name                              =   "${var.prefix}-user-vm"
  resource_group_name               =   azurerm_resource_group.user-rg.name
  location                          =   azurerm_resource_group.user-rg.location
  network_interface_ids             =   [azurerm_network_interface.user-nic.id]
  size                              =   var.vmVars["virtual_machine_size"]
  computer_name                     =   var.vmVars["user_computer_name"]
  admin_username                    =   var.vmVars["user_admin_username"]
  admin_password                    =   var.vmVars["user_admin_password"]

  os_disk  {
      name                          =   "${var.prefix}-uservm-os-disk"
      caching                       =   var.vmVars["os_disk_caching"]
      storage_account_type          =   var.vmVars["os_disk_storage_account_type"]
      disk_size_gb                  =   var.vmVars["os_disk_size_gb"]
  }

  source_image_reference {
      publisher                     =   var.vmVars["user_publisher"]
      offer                         =   var.vmVars["user_offer"]
      sku                           =   var.vmVars["user_sku"]
      version                       =   var.vmVars["vm_image_version"]
  }

  tags                              =   var.tags

  depends_on                        =   [azurerm_windows_virtual_machine.dc-vm, azurerm_virtual_machine_extension.adds]

}


#
# - Join this VM to the domain and install software with PowerShell/Chocolatey script
#

resource "azurerm_virtual_machine_extension" "domainjoin" {
  name                  =        "Domain-Join"
  virtual_machine_id    =        azurerm_windows_virtual_machine.user-vm.id
  publisher             =        "Microsoft.Compute"
  type                  =        "CustomScriptExtension"
  type_handler_version  =        "1.10"

  protected_settings = <<PROTECTED_SETTINGS
    {
      "commandToExecute"    :   "powershell -ExecutionPolicy Unrestricted -File domainjoin.ps1",
      "storageAccountName"  :   "${azurerm_storage_account.scripts.name}",
      "storageAccountKey"   :   "${azurerm_storage_account.scripts.primary_access_key}"
    }
  PROTECTED_SETTINGS

  settings = <<SETTINGS
    {
        "fileUris"      : [ "https://domainpsscripts.blob.core.windows.net/psscripts/domainjoin.ps1" ]
    }
  SETTINGS

  depends_on      =       [azurerm_windows_virtual_machine.dc-vm, azurerm_windows_virtual_machine.user-vm]
}