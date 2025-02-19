resource "azurerm_resource_group" "resource_group" {
  name     = "${var.app_name}-rg"
  location = var.location

  tags = local.resource_tags
}

resource "azurerm_virtual_network" "virtual_network" {
  name                = "${var.app_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = resource.azurerm_resource_group.resource_group.location
  resource_group_name = resource.azurerm_resource_group.resource_group.name

  tags = local.resource_tags
}

resource "azurerm_subnet" "private_subnet" {
  name                 = "${var.app_name}-subnet"
  resource_group_name  = resource.azurerm_resource_group.resource_group.name
  virtual_network_name = resource.azurerm_virtual_network.virtual_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  name                = "${var.app_name}-public-ip"
  location            = resource.azurerm_resource_group.resource_group.location
  resource_group_name = resource.azurerm_resource_group.resource_group.name
  allocation_method   = "Static"
  domain_name_label   = trimprefix(format("%s-%s", var.public_ip_label_prefix, var.app_name), "-")

  tags = local.resource_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_network_security_group" "network_security_group" {
  name                = "${var.app_name}-nsg"
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

  tags = local.resource_tags
}

resource "azurerm_network_interface" "network_interface" {
  name                = "${var.app_name}-nic"
  location            = resource.azurerm_resource_group.resource_group.location
  resource_group_name = resource.azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "${var.app_name}-nic-ip"
    subnet_id                     = resource.azurerm_subnet.private_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = resource.azurerm_public_ip.public_ip.id
  }

  tags = local.resource_tags
}

resource "azurerm_network_interface_security_group_association" "nic_nsg_association" {
  network_interface_id      = resource.azurerm_network_interface.network_interface.id
  network_security_group_id = resource.azurerm_network_security_group.network_security_group.id
}

resource "azurerm_linux_virtual_machine" "ubuntu_vm" {
  name                = "${var.app_name}-vm"
  resource_group_name = resource.azurerm_resource_group.resource_group.name
  location            = resource.azurerm_resource_group.resource_group.location
  size                = "Standard_B1s"
  admin_username      = "ubuntu"
  network_interface_ids = [
    resource.azurerm_network_interface.network_interface.id,
  ]

  admin_ssh_key {
    username   = "ubuntu"
    public_key = var.admin_ssh_public_key
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

  tags = local.resource_tags
}
