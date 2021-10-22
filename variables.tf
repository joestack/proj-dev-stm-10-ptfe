variable "aws_region" {
  description = "AWS region"
  default     = "eu-west-1"
}

variable "name" {
  description = "Unique name of the deployment"
  default     = "stm-dev"
}


variable "tfe_node_install" {
  description = "1=yes, 0=no"
  default     = "1"
}


variable "instance_type" {
  description = "instance size to be used for worker nodes"
  default     = "t2.medium"
}


variable "pub_key" {
  description = "the public key to be used to access the bastion host and ansible nodes"
  default     = "joestack"
}

variable "ssh_user" {
    default = "ubuntu"
}

variable "pri_key" {
  description = "the base64 encoded private key to be used to access the bastion host and ansible nodes"
}



locals {
  priv_key = base64decode(var.pri_key)
}
