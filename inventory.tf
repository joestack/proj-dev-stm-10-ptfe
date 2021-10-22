data "template_file" "ansible_tfe_hosts" {
  count      = var.tfe_node_install
  template   = file("${path.root}/templates/ansible_hosts.tpl")
  depends_on = [aws_instance.tfe_node]

  vars = {
    node_name    = aws_instance.tfe_node.*.tags[count.index]["Name"]
    ansible_user = var.ssh_user
    ip           = element(aws_instance.tfe_node.*.private_ip, count.index)
  }
}


data "template_file" "ansible_skeleton" {
  count      = var.tfe_node_install
  template = file("${path.root}/templates/ansible_skeleton.tpl")

  vars = {
    tfe_hosts_def = join("", data.template_file.ansible_tfe_hosts.*.rendered)
  }
}

##
## copy the local file to the tfe_node
##
resource "null_resource" "provisioner" {
  count      = var.tfe_node_install

  triggers = {
    always_run = timestamp()
  }

  provisioner "file" {
    content     = data.template_file.ansible_skeleton.*.rendered
    destination = "~/inventory"

    connection {
      type        = "ssh"
      host        = data.terraform_remote_state.foundation.outputs.bastionhost.public_ip
      user        = var.ssh_user
      private_key = local.priv_key
      insecure    = true
    }
  }
}


