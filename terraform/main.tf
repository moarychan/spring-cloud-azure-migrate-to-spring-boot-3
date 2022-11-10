terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.9.0"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.16"
    }
  }
}

provider "azurerm" {
  features {}
}

// ===========resource_group===========
resource "azurecaf_name" "resource_group" {
  name          = var.application_name
  resource_type = "azurerm_resource_group"
  random_length = 5
  clean_input   = true
}

resource "azurerm_resource_group" "main" {
  name     = azurecaf_name.resource_group.result
  location = var.location

  tags = {
    "terraform"                 = "true"
    "application-name"          = var.application_name
    "spring-cloud-azure-sample" = var.sample_tag_value
  }
}

data "azurerm_client_config" "current" {
}

// ===========azurerm_key_vault===========
resource "azurecaf_name" "azurecaf_name_kv" {
  name          = var.application_name
  resource_type = "azurerm_key_vault"
  random_length = 5
  clean_input   = true
}

resource "azurerm_key_vault" "kv_account" {
  name                        = azurecaf_name.azurecaf_name_kv.result
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Purge",
      "Delete"
    ]
  }

  tags = {
    "terraform"                 = "true"
    "spring-cloud-azure-sample" = var.sample_tag_value
  }
}

# =================== eventhubs ================
resource "azurecaf_name" "azurecaf_name_eventhubs" {
  name          = var.application_name
  resource_type = "azurerm_eventhub_namespace"
  random_length = 5
  clean_input   = true
}

resource "azurerm_eventhub_namespace" "eventhubs_namespace" {
  name                = azurecaf_name.azurecaf_name_eventhubs.result
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
  capacity            = 1

  tags = {
    terraform_azure_sample = var.sample_tag_value
  }
}

resource "azurerm_eventhub" "eventhubs" {
  name                = "eh1"
  namespace_name      = azurerm_eventhub_namespace.eventhubs_namespace.name
  resource_group_name = azurerm_resource_group.main.name
  partition_count     = 2
  message_retention   = 1
}

resource "azurerm_role_assignment" "role_eventhubs_data_owner" {
  scope                = azurerm_eventhub.eventhubs.id
  role_definition_name = "Azure Event Hubs Data Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}

# =================== storage ================
resource "azurecaf_name" "storage_account" {
  name          = var.application_name
  resource_type = "azurerm_storage_account"
  random_length = 5
  clean_input   = true
}

resource "azurerm_storage_account" "storage_account" {
  name                     = azurecaf_name.storage_account.result
  resource_group_name      = azurerm_resource_group.main.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    "spring-cloud-azure-sample" = var.sample_tag_value
    "terraform"                 = "true"
    "application-name"          = var.application_name
  }
}

resource "azurerm_storage_container" "storage_container" {
  name                  = "eventhubs-binder-sample"
  storage_account_name  = azurerm_storage_account.storage_account.name
  container_access_type = "container"
}

// role_assignment
resource "azurerm_role_assignment" "role_storage_account_contributor" {
  scope                = azurerm_storage_account.storage_account.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "role_storage_blob_data_owner" {
  scope                = azurerm_storage_container.storage_container.resource_manager_id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Store credentials in Azure Key Secret
resource "azurerm_key_vault_secret" "key_vault_secret_eventhubs_namespace" {
  name         = "azureEeventhubsNamespace"
  value        = azurerm_eventhub_namespace.eventhubs_namespace.name
  key_vault_id = azurerm_key_vault.kv_account.id
}

resource "azurerm_key_vault_secret" "key_vault_secret_storage_account" {
  name         = "azureStorageAccountName"
  value        = azurerm_storage_account.storage_account.name
  key_vault_id = azurerm_key_vault.kv_account.id
}

resource "azurerm_key_vault_secret" "key_vault_secret_storage_container" {
  name         = "azureStorageContainerName"
  value        = azurerm_storage_container.storage_container.name
  key_vault_id = azurerm_key_vault.kv_account.id
}

resource "azurerm_key_vault_secret" "key_vault_secret_eventhub_name" {
  name         = "azureEventhubName"
  value        = azurerm_eventhub.eventhubs.name
  key_vault_id = azurerm_key_vault.kv_account.id
}
