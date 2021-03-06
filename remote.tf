data "terraform_remote_state" "foundation" {
  backend = "remote"

  config = {
    organization = "joestack"
    workspaces = {
      name = "proj-dev-stm-01-foundation"
    }
  }
}

data "terraform_remote_state" "bastionhost" {
  backend = "remote"

  config = {
    organization = "joestack"
    workspaces = {
      name = "proj-dev-stm-02-bastionhost"
    }
  }
}
