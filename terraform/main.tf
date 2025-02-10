resource "azurerm_resource_group" "resource_group" {
  name     = "${local.app_name}-rg"
  location = "West Europe"

  tags = local.default_tags
}

resource "azurerm_virtual_network" "virtual_network" {
  name                = "${local.app_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = resource.azurerm_resource_group.resource_group.location
  resource_group_name = resource.azurerm_resource_group.resource_group.name

  tags = local.default_tags
}

resource "azurerm_subnet" "private_subnet" {
  name                 = "${local.app_name}-subnet"
  resource_group_name  = resource.azurerm_resource_group.resource_group.name
  virtual_network_name = resource.azurerm_virtual_network.virtual_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  name                = "${local.app_name}-public-ip"
  location            = resource.azurerm_resource_group.resource_group.location
  resource_group_name = resource.azurerm_resource_group.resource_group.name
  allocation_method   = "Static"
  domain_name_label   = format("%s-%s", local.public_ip_label_prefix, local.app_name)

  tags = local.default_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_network_security_group" "network_security_group" {
  name                = "${local.app_name}-nsg"
  location            = resource.azurerm_resource_group.resource_group.location
  resource_group_name = resource.azurerm_resource_group.resource_group.name

  # The following security rules are based on what Azure creates by default when creating a VM following the guidelines of the HEIG-VD course.

  security_rule {
    name                       = "ssh"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "http"
    priority                   = 320
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "https"
    priority                   = 340
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.default_tags
}

resource "azurerm_network_interface" "network_interface" {
  name                = "${local.app_name}-nic"
  location            = resource.azurerm_resource_group.resource_group.location
  resource_group_name = resource.azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "${local.app_name}-nic-ip"
    subnet_id                     = resource.azurerm_subnet.private_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = resource.azurerm_public_ip.public_ip.id
  }

  tags = local.default_tags
}

resource "azurerm_network_interface_security_group_association" "nic_nsg_association" {
  network_interface_id      = resource.azurerm_network_interface.network_interface.id
  network_security_group_id = resource.azurerm_network_security_group.network_security_group.id
}

resource "azurerm_linux_virtual_machine" "ubuntu_vm" {
  name                = "${local.app_name}-vm"
  resource_group_name = resource.azurerm_resource_group.resource_group.name
  location            = resource.azurerm_resource_group.resource_group.location
  size                = "Standard_B1s"
  admin_username      = "ubuntu"
  network_interface_ids = [
    resource.azurerm_network_interface.network_interface.id,
  ]

  admin_ssh_key {
    username   = "ubuntu"
    public_key = <<-EOT
      ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDYqZQrzJOK5VeQOmJYGrMZzcv+PdQ7OK3Zc0PuL6gShT2cH1eKtZSiVqNNwj94xBkA9oWJ+83J9viGMkDarQrMfEzi0JKqM2QvHpqPOI3vLPfu/WeXwmILz3cvv2/wjULyJNPiANp0gQB7dEgkNCKBQzTV/XU3KB6f5+8WFoyx+6Fv6l3Dr/XtwosnAn2dpJzRylTqRWOGoSfV1X6Y4XwpUsShldlfHM0eb/OIIwnQ9Ue55bZMow2Dr5Id57yv/6lWuC+HiFw1Yby++El/gp3JYlmzVoTzdMxP3qiw7vkNDVC8nMLzQwVrB28DA64CueY2lsJU8znBEk0Wk3kX8BekVSwzV9jkhhXGX4n1IWdc3keJwOO3NqunbKmE4FnBLB8YxJA6UWd6b0DDhELqMZTQEBimL7fjbJ4uiU1RodyFR7N//qSAZ+OvOE3TqBg4Oz1pSFFWHO8y1froNTUoMj19rXQYVxa+ON9tdHZLJuTBVNJ6/ELj179pTutuEDWresIL5XqaKQW7RqS/RkEGILJcH4kdHPrjXntDnL10F1lwzG/y12YWFDhKTdcI27uTCd6a7DW1YZj/Ezii/4Ohou5G0GmR+D/fpLQFFCOU2PhzZnml/XCI9Tenb4gPwWbj3RRHeJkzoq/ZEp+1+ZNbP+c0ZVV8t1mpq5xS45ibRF2DJQ== openpgp:0x82F8AEFC:YubiKey20554191
    EOT
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  tags = local.default_tags
}
