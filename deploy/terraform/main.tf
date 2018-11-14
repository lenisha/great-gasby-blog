terraform {
  required_version = ">= 0.11"

  backend "azurerm" {}
}

# Configure the Microsoft Azure Provider
provider "azurerm" {}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "demo-rg" {
  name     = "${var.rg-name}"
  location = "${var.location}"
}

# Create a Storage Account and enable Static website hosting
resource "azurerm_storage_account" "webblob" {
  name                     = "${var.dns_name}"
  location                 = "${azurerm_resource_group.demo-rg.location}"
  resource_group_name      = "${azurerm_resource_group.demo-rg.name}"
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"

   provisioner "local-exec" {
    command = "az storage blob service-properties update --account-name ${azurerm_storage_account.webblob.name} --static-website  --index-document index.html --404-document 404.html"
  }
}

# Query Web Endpoint for Static Hosting
module "query_url" {
  source  = "matti/resource/shell"

  command = "printf $(az storage account show -n ${azurerm_storage_account.webblob.name} -g ${azurerm_resource_group.demo-rg.name} --query \"primaryEndpoints.web\" --output tsv | cut -d \"/\" -f 3)"
}


# Create Azure CDN profile
resource "azurerm_cdn_profile" "webblob-cdn" {
  name                = "${azurerm_storage_account.webblob.name}cdnprofile"
  location            = "${azurerm_resource_group.demo-rg.location}"
  resource_group_name = "${azurerm_resource_group.demo-rg.name}"
  sku                 = "Standard_Verizon"
}

# Point Azure CDN profile to web endpoint for Static website
resource "azurerm_cdn_endpoint" "webblob-cdn-endpt" {
  name                = "${var.dns_name}"
  profile_name        = "${azurerm_cdn_profile.webblob-cdn.name}"
  location            = "${azurerm_resource_group.demo-rg.location}"
  resource_group_name = "${azurerm_resource_group.demo-rg.name}"
  is_http_allowed 	  = "false"
  optimization_type   = "GeneralWebDelivery"
  origin_host_header  = "${module.query_url.stdout}"
  querystring_caching_behaviour = "IgnoreQueryString"
  
  origin {
    name      = "assets"
    host_name = "${module.query_url.stdout}"
	https_port = "443"
  }
  depends_on = ["module.query_url"]
}