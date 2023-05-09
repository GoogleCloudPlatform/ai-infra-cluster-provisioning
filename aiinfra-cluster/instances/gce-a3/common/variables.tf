  
variable "region" {
    type = string
}

variable "zone" {
    type = string
}

variable "deployment_name" {
    type = string
}

variable "num_migs" {
    type = number
}

variable "num_machines_per_mig" {
    type = number
}

variable "os_image" {
    type = string
}