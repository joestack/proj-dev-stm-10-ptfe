### main.tf ###

terraform {
  required_version = ">= 0.12"
}

provider "aws" {
    region = var.aws_region
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "tfe_node" {
  count                       = var.tfe_node_install
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = data.terraform_remote_state.foundation.outputs.bastionhost_subnet_id
  private_ip                  = data.terraform_remote_state.foundation.outputs.tfenode_priv_ip
  associate_public_ip_address = "true"
  vpc_security_group_ids      = [data.terraform_remote_state.foundation.outputs.tfe_asg_id]
  key_name                    = var.pub_key


  tags = {
    Name        = format("tfe-%02d", count.index + 1)
  }


  ebs_block_device {
      device_name = "/dev/xvdb"
      volume_type = "gp2"
      volume_size = 40
    }

  ebs_block_device {
      device_name = "/dev/xvdc"
      volume_type = "gp2"
      volume_size = 20
    }

  user_data = file("./templates/userdata.sh")
}

resource "aws_route53_record" "tfenode" {
  count   = var.tfe_node_install
  zone_id = data.terraform_remote_state.foundation.outputs.dns_zone_id
  name    = lookup(aws_instance.tfe_node.*.tags[count.index], "Name")
  type    = "A"
  ttl     = "300"
  records = [element(aws_instance.tfe_node.*.public_ip, count.index )]
  #[aws_instance.tfe_node.public_ip]
}

