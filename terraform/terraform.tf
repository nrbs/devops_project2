terraform {

  cloud {
    organization = "nurbeks-org"

    workspaces {
      name = "devops-project2"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}