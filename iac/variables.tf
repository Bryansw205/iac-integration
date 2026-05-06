variable "region" {
    description = "Region de despliegue"
    type = string
    default = "us-east-2"
}

variable "entorno" {
    description = "Entorno de despliegue"
    type = string
}

variable "vpc-cidr" {
    description = "CIDR de la VPC"
    type = string
    default = "10.0.0.0/16"
}
