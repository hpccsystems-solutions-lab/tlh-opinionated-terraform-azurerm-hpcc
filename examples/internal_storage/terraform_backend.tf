terraform {
  backend "remote" {
    hostname     = "tfe.lnrisk.io"
    organization = "Infrastructure"
    workspaces {
      name = "us-prctrox-dev" # Modify this to match your workspace prefix
    }
  }
}