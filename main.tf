# Mapping of environment to custom code
variable "env_mappring" {
  type = map
  default = {
    dev = "7"
    uat = "3"
    prd = "0"
  }
}

# Creating environment prefix
locals {
  env_prefix = join("-", [join("", [lower(substr(var.project_name,0,2)), var.env_mappring[lower(var.environment)]]),"we"])
  project = lower(var.project_name)
}

# Creating ressource group for main ressources of the project
resource "azurerm_resource_group" "main-rg" {
  name      = join("-", [local.env_prefix, local.project, "rg","001"])
  location  = var.resource_group_location

  tags = {
    "environment" = upper(var.environment)
    "project" = var.project_name
    "module" = "Main"
  }
}

# Creating ressource group for Databricks nodes
resource "azurerm_resource_group" "databricks-managed-rg" {
  name      = join("-", [local.env_prefix, local.project, "rg","002"])
  location  = var.resource_group_location

  tags = {
    "environment" = upper(var.environment)
    "project" = var.project_name
    "module" = "Databricks"
  }
}

# Creating ressource group for devops ressources
resource "azurerm_resource_group" "devops-rg" {
  name      = join("-", [local.env_prefix,"devops", "rg","001"])
  location  = var.resource_group_location

  tags = {
    "environment" = upper(var.environment)
    "project" = var.project_name
    "module" = "Devops"
  }
}

# Creating ressource group for network resources
resource "azurerm_resource_group" "network-rg" {
  name      = join("-", [local.env_prefix, "network", "rg","001"])
  location  = var.resource_group_location

  tags = {
    "environment" = upper(var.environment)
    "project" = var.project_name
    "module" = "Network"
  }
}

# Creating network ressources

# First we create the nsg rule
resource "azurerm_network_security_group" "nsg-001" {
  name                = join("-", [local.env_prefix, local.project, "nsg","001"])
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.network-rg.name

  tags = {
    "environment" = upper(var.environment)
    "project" = var.project_name
    "module" = "Network"
  }
}

# Route table
resource "azurerm_route_table" "route-001" {
  name                          = join("-", [local.env_prefix, local.project, "appliance", "peering", "001"])
  location                      = var.resource_group_location
  resource_group_name           = azurerm_resource_group.network-rg.name
  disable_bgp_route_propagation = false

  route {
    name           = "hubToAppliance"
    address_prefix = "10.205.0.0/24"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = "10.205.0.38"
  }

  route {
    name           = "InternetToAppliance"
    address_prefix = "10.1.0.0/16"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = "10.205.0.38"
  }

  route {
    name           = "ManagementNone"
    address_prefix = "10.205.0.0/28"
    next_hop_type  = "None"
  }

  tags = {
    "environment" = upper(var.environment)
    "project" = var.project_name
    "module" = "Network"
  }
}

# The main vnet
resource "azurerm_virtual_network" "main-vnet" {
  name                = join("-", [local.env_prefix, local.project, "vnet","001"])
  address_space       = ["10.205.5.0/24"]
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.network-rg.name
}

# The main subnet
resource "azurerm_subnet" "main-subnet" {
  name                 = join("-", [local.env_prefix, local.project, "sub","001"])
  resource_group_name  = azurerm_resource_group.network-rg.name
  virtual_network_name = azurerm_virtual_network.main-vnet.name
  address_prefixes     = ["10.205.5.0/25"]
}

# The public subnet for Databricks
resource "azurerm_subnet" "pub-subnet" {
  name                 = join("-", [local.env_prefix, local.project, "sub", "pub", "001"])
  resource_group_name  = azurerm_resource_group.network-rg.name
  virtual_network_name = azurerm_virtual_network.main-vnet.name
  address_prefixes     = ["10.205.5.128/26"]
}

resource "azurerm_subnet_route_table_association" "pub-route-association" {
  subnet_id      = azurerm_subnet.pub-subnet.id
  route_table_id = azurerm_route_table.route-001.id
}

resource "azurerm_subnet_network_security_group_association" "pub-nsg-association" {
  subnet_id                 = azurerm_subnet.pub-subnet.id
  network_security_group_id = azurerm_network_security_group.nsg-001.id
}

# The private subnet for Databricls
resource "azurerm_subnet" "prv-subnet" {
  name                 = join("-", [local.env_prefix, local.project, "sub", "prv", "001"])
  resource_group_name  = azurerm_resource_group.network-rg.name
  virtual_network_name = azurerm_virtual_network.main-vnet.name
  address_prefixes     = ["10.205.5.192/26"]
}

resource "azurerm_subnet_route_table_association" "prv-route-association" {
  subnet_id      = azurerm_subnet.prv-subnet.id
  route_table_id = azurerm_route_table.route-001.id
}

resource "azurerm_subnet_network_security_group_association" "prv-nsg-association" {
  subnet_id                 = azurerm_subnet.prv-subnet.id
  network_security_group_id = azurerm_network_security_group.nsg-001.id
}