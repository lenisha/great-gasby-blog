variable "dns_name" {
  description = " Label for the Domain Name. Will be used to make up the FQDN."
}

variable "rg-name" {
  default = "demogatsbyrg"
}

variable "location" {
  default = "WestUS"
}