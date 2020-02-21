# Set a provider
provider "azurerm" {
  version = "=1.27.0"
}
###########################################################
resource "azurerm_resource_group" "sam-terraformgroup" {
    name     = "sam-sparta"
    location = "northeurope"

    tags = {
        environment = "Terraform Demo"
    }
}
###########################################################
resource "azurerm_virtual_network" "sam-terraformnetwork" {
    name                = "sam-Vnet"
    address_space       = ["10.0.0.0/16"]
    location            = "northeurope"
    resource_group_name = azurerm_resource_group.sam-terraformgroup.name

    tags = {
        environment = "Terraform Demo"
    }
}
###########################################################
resource "azurerm_subnet" "sam-terraformsubnet" {
    name                 = "sam-Subnet"
    resource_group_name  = azurerm_resource_group.sam-terraformgroup.name
    virtual_network_name = azurerm_virtual_network.sam-terraformnetwork.name
    address_prefix       = "10.0.2.0/24"
}
###########################################################
resource "azurerm_public_ip" "sam-terraformpublicip" {
    name                         = "sam-PublicIP"
    location                     = "northeurope"
    resource_group_name          = azurerm_resource_group.sam-terraformgroup.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform Demo"
    }
}
###########################################################
resource "azurerm_network_security_group" "sam-terraformnsg" {
    name                = "sam-NetworkSecurityGroup"
    location            = "northeurope"
    resource_group_name = azurerm_resource_group.sam-terraformgroup.name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "Terraform Demo"
    }
}
###########################################################
resource "azurerm_network_interface" "sam-terraformnic" {
    name                        = "sam-NIC"
    location                    = "northeurope"
    resource_group_name         = azurerm_resource_group.sam-terraformgroup.name
    network_security_group_id   = azurerm_network_security_group.sam-terraformnsg.id

    ip_configuration {
        name                          = "sam-NicConfiguration"
        subnet_id                     = "${azurerm_subnet.sam-terraformsubnet.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${azurerm_public_ip.sam-terraformpublicip.id}"
    }

    tags = {
        environment = "Terraform Demo"
    }
}
###########################################################
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.sam-terraformgroup.name
    }

    byte_length = 8
}
###########################################################
resource "azurerm_storage_account" "sam-storageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.sam-terraformgroup.name
    location                    = "northeurope"
    account_replication_type    = "LRS"
    account_tier                = "Standard"

    tags = {
        environment = "Terraform Demo"
    }
}
###########################################################
resource "azurerm_virtual_machine" "sam-terraformvm" {
    name                  = "sam-VM"
    location              = "northeurope"
    resource_group_name   = azurerm_resource_group.sam-terraformgroup.name
    network_interface_ids = [azurerm_network_interface.sam-terraformnic.id]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "sam-OsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "sam-vm"
        admin_username = "azureuser"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCgQRL7t2bcOY5rzeWHTRK/vMJd0QUDaQdwrOnAT9tl78DJtTst9aa7H2nXasmTIowNNPa9YN5zD0l+amz+oISVLKlSvp0FW6ycT37aGdTfngt6+dLBJwttKlJhG7d9Vsw05YZnX9aCEIVWs3Xtkq6yaOkNC4PNh2S2Pe+DZy8H5c045q2zCRahAnurIF/ty5563G2fOztCt/PIoRgEJ47DCh6mvbMQYjdybmKb6680WncVeOH24Ze2MofwjBgtzu1W9+zmr5JrI6OzfoRM9FHNw2lYeR4jxM+k9Yh15FaXgLXbBCimQxmfxXT9Ob5gW1ekFl/vTbiqXmMimcaNfMANu/IuFCiWpeoKB3bk+wFzgMM0b0tui3cU2Nr2CsrRabPJDjsljq8UAzO/F47DGOTxvnX1UCJ7GAYqmhOT92H5kQ9ZoeitkTwkyqIiWSpMEAP+dK94BitYHHDY+d7hfMiGQzARx5m8f9FnJfSD6jBys9hhgV/qh/BmQ/qb2vWLFm4xnYF1iNep8ABuPXakb2dDzi1qvnB5l+r48heS/OrQvn0F4KHienwpYVhrJ74V1H9LhH1yi2SLVcsGjafwODNWw63aO6C8Tc+Q3zTazW9E8vyqVXfHeGRW8B5wDcoy1CitmIizm1Agz1T5GRHrrSeQHjLVvc0KweKTp3MQTuPSww== swatson@spartaglobal.com"
        }
    }
    tags = {
        environment = "Terraform Demo"
    }
}
###########################################################
