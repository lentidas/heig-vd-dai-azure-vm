output "virtual_machine" {
  value = {
    name       = resource.azurerm_linux_virtual_machine.ubuntu_vm.name
    public_ip  = resource.azurerm_public_ip.public_ip.ip_address
    public_dns = resource.azurerm_public_ip.public_ip.fqdn
  }
}
