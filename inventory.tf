data "template_file" "ansible_tfe_hosts" {
  template   = file("${path.root}/templates/ansible_hosts.tpl")
  depends_on = [aws_instance.tfe_node]

  vars = {
    node_name    = aws_instance.tfe_node.*.tags[0]["Name"]
    ansible_user = var.ssh_user
    ip           = aws_instance.tfe_node.*.private_ip[0]
  }
}

data "template_file" "ansible_skeleton" {
  template = file("${path.root}/templates/ansible_skeleton.tpl")

  vars = {
    tfe_hosts_def = join("", data.template_file.ansible_tfe_hosts.*.rendered)
  }
}

resource "local_file" "ansible_inventory" {
  content  = data.template_file.ansible_skeleton.rendered
  filename = "${path.root}/ansible/inventory"
}


## REPLICATED CONFIG

data "template_file" "ansible_replicated" {
  template   = file("${path.root}/templates/replicated.conf.tpl")
  depends_on = [aws_instance.tfe_node]

  vars = {
    tfe_password = var.tfe_password
    domain       = local.dns_domain
    hostname     = lookup(aws_instance.tfe_node.*.tags[0], "Name")
  }
}

resource "local_file" "ansible_replicated" {
  depends_on = [data.template_file.ansible_replicated]

  content  = data.template_file.ansible_replicated.rendered
  filename = "${path.root}/ansible/roles/ptfe/files/replicated.conf"
}



## SETTINGS.JSON CONFIG

resource "random_string" "settings_backup_token" {
  length           = 32
  special          = false
}

data "template_file" "ansible_settings" {
  template   = file("${path.root}/templates/settings.json.tpl")
  depends_on = [
                aws_instance.tfe_node,
                random_string.settings_backup_token
                ]

  vars = {
    tfe_encryption_key = var.tfe_encryption_key
    domain             = local.dns_domain
    hostname           = lookup(aws_instance.tfe_node.*.tags[0], "Name")
    backup_token       = random_string.settings_backup_token.result
  }
}

resource "local_file" "ansible_settings" {
  #count      = var.tfe_node_install
  depends_on = [data.template_file.ansible_settings]

  content  = data.template_file.ansible_settings.rendered
  filename = "${path.root}/ansible/roles/ptfe/files/settings.json"
}


### CERTBOT Playbook role create_cert - modify the email address relatet to the TLS cert

data "template_file" "ansible_certbot" {
  template   = file("${path.root}/templates/certbot.tpl")
  depends_on = [aws_instance.tfe_node]

  vars = {
    email        = var.email
    domain       = local.dns_domain
  }
}

resource "local_file" "ansible_certbot" {
  depends_on = [data.template_file.ansible_certbot]

  content  = data.template_file.ansible_certbot.rendered
  filename = "${path.root}/ansible/roles/create_cert/tasks/main.yml"
}



#copy the license file to the ansible dir ansible/roles/ptfe/files

resource "null_resource" "license" {
  depends_on = [aws_instance.tfe_node]
  
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "echo ${local.lic_rli} > ${path.root}/ansible/roles/ptfe/files/license.rli"
  }
}

##
## here we copy the entire Ansible Playbook from the local executin entironment to the Bastionhost
##
resource "null_resource" "cp_ansible" {
  depends_on = [
    local_file.ansible_inventory,
    local_file.ansible_replicated,
    local_file.ansible_settings,
    local_file.ansible_certbot,
    null_resource.license
    ]

  triggers = {
    always_run = timestamp()
  }

  provisioner "file" {
    source      = "${path.root}/ansible"
    destination = "~/ptfe"

    connection {
      type        = "ssh"
      host        = data.terraform_remote_state.bastionhost.outputs.bastionhost_public_ip
      user        = var.ssh_user
      private_key = local.priv_key
      insecure    = true
    }
  }
}

