variable "subscription_id" {
  type     = string
  nullable = false
  description = "The id of the subscription you want to deply in."
}

variable "client_id" {
  type     = string
  nullable = false
  description = "The client id of the service principal used for Azure authentication."
}

variable "client_secret" {
  type     = string
  nullable = false
  description = "The client secret of the service principal used for Azure authentication."
}

variable "tenant_id" {
  type     = string
  nullable = false
  description = "The tenant id where your subscription lives in."
}

variable "project_name" {
  type     = string
  nullable = false
  description   = "The name of the project you're deploying the configuration for."
}

variable "environment" {
  type     = string
  nullable = false
  description   = "The name of the environement you're deploying in."
}

variable "resource_group_location" {
  default = "westeurope"
  description   = "Location of the resource group."
}