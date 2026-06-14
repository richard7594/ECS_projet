variable "cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "az" {
  type    = list(string)
  default = ["eu-west-1a", "eu-west-1b"]
}

variable "cidr_public" {
  type = map(string)
  default = {
    eu-west-1a = "10.0.1.0/24",
    eu-west-1b = "10.0.2.0/24"
  }
}

variable "cidr_private" {
  type = map(string)
  default = {
    eu-west-1a = "10.0.3.0/24",
    eu-west-1b = "10.0.4.0/24"
  }
}