# ---------------------------------------------------------------------------
# Clave SSH gestionada por Terraform
# ---------------------------------------------------------------------------

# Par de claves RSA 4096 generado automáticamente.
# La clave privada se exporta como output sensible para que Ansible pueda usarla.
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# ---------------------------------------------------------------------------
# Red virtual y subred
# ---------------------------------------------------------------------------

# Red virtual que alojará la VM
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-cp2-guiurm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.vnet_address_space
  tags                = local.common_tags
}

# Subred dentro de la VNet
resource "azurerm_subnet" "subnet" {
  name                 = "snet-cp2-guiurm"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_address_prefix
}

# ---------------------------------------------------------------------------
# Network Security Group (NSG) + reglas de entrada
# ---------------------------------------------------------------------------

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-vm-cp2-guiurm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags
}

# Regla SSH (puerto 22) — necesario para que Ansible acceda a la VM
resource "azurerm_network_security_rule" "allow_ssh" {
  name                        = "allow-ssh"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# Regla HTTP (puerto 80) — acceso al servidor web desde Internet
resource "azurerm_network_security_rule" "allow_http" {
  name                        = "allow-http"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# Regla HTTPS (puerto 443) — para el certificado x.509
resource "azurerm_network_security_rule" "allow_https" {
  name                        = "allow-https"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# ---------------------------------------------------------------------------
# IP Pública + NIC + asociación NIC-NSG
# ---------------------------------------------------------------------------

# IP pública estática para la VM (necesaria para acceso desde Internet)
resource "azurerm_public_ip" "vm_pip" {
  name                = "pip-vm-cp2-guiurm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

# Interfaz de red que conecta la VM a la subred y a la IP pública
resource "azurerm_network_interface" "vm_nic" {
  name                = "nic-vm-cp2-guiurm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_pip.id
  }
}

# Asociación de la NIC con el NSG (aplica las reglas de seguridad a la interfaz)
resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.vm_nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# ---------------------------------------------------------------------------
# Máquina Virtual Linux
# ---------------------------------------------------------------------------

resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "vm-cp2-guiurm"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = var.vm_size
  admin_username                  = var.vm_admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.vm_nic.id]
  tags                            = local.common_tags

  # Clave SSH generada por el provider TLS
  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = tls_private_key.ssh_key.public_key_openssh
  }

  # Disco estándar — suficiente para el caso práctico
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Ubuntu 22.04 LTS (Jammy) — distribución de libre elección según enunciado
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}
