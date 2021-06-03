#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*
#*         Azure Firewall Module - DC VM              #*                                    
#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*

#
# - Network Interface Card for Virtual Machine
#

resource "azurerm_network_interface" "dc-nic" {
  name                              =   "${var.prefix}-dc-nic"
  resource_group_name               =   azurerm_resource_group.rg.name
  location                          =   azurerm_resource_group.rg.location
  tags                              =   var.tags
  ip_configuration                  {
      name                          =  "${var.prefix}-dc-nic-ipconfig"
      subnet_id                     =   azurerm_subnet.sn["DC-VM-Subnet"].id
      private_ip_address_allocation =   local.nic_allocation
  }
}


#
# - Create a Windows 10 Virtual Machine
#

resource "azurerm_windows_virtual_machine" "dc-vm" {
  name                              =   "${var.prefix}-dc-vm"
  resource_group_name               =   azurerm_resource_group.rg.name
  location                          =   azurerm_resource_group.rg.location
  network_interface_ids             =   [azurerm_network_interface.dc-nic.id]
  size                              =   var.vmVars["virtual_machine_size"]
  computer_name                     =   var.vmVars["dc_computer_name"]
  admin_username                    =   var.vmVars["dc_admin_username"]
  admin_password                    =   var.vmVars["dc_admin_password"]

  os_disk  {
      name                          =   "${var.prefix}-dc-os-disk"
      caching                       =   var.vmVars["os_disk_caching"]
      storage_account_type          =   var.vmVars["os_disk_storage_account_type"]
      disk_size_gb                  =   var.vmVars["os_disk_size_gb"]
  }

  source_image_reference {
      publisher                     =   var.vmVars["dc_publisher"]
      offer                         =   var.vmVars["dc_offer"]
      sku                           =   var.vmVars["dc_sku"]
      version                       =   var.vmVars["vm_image_version"]
  }

  tags                              =   var.tags

}

#
# - Promote the Server to a Domain\ Controller with PowerShell script
#

resource "azurerm_virtual_machine_extension" "adds" {
  name                  =        "Domain-Controller-Services"
  virtual_machine_id    =        azurerm_windows_virtual_machine.dc-vm.id
  publisher             =        "Microsoft.Compute"
  type                  =        "CustomScriptExtension"
  type_handler_version  =        "1.10"

  protected_settings = <<PROTECTED_SETTINGS
    {
      "commandToExecute"    :   "powershell -ExecutionPolicy Unrestricted -File adds.ps1",
      "storageAccountName"  :   "${azurerm_storage_account.scripts.name}",
      "storageAccountKey"   :   "${azurerm_storage_account.scripts.primary_access_key}"
    }
  PROTECTED_SETTINGS

  settings = <<SETTINGS
    {
        "fileUris"      : [ "https://domainpsscripts.blob.core.windows.net/psscripts/adds.ps1" ]
    }
  SETTINGS

  depends_on      =       [azurerm_windows_virtual_machine.dc-vm]

}