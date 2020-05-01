terraform {

  backend "s3" {
    bucket = "hb-wolke-edda"
    key = "terraform/fennas/terraform.tfstate"
    region = "eu-central-1"
  }



  required_providers {
    docker = "< 2.7.0"
  }

}

provider "docker" {
  host = "ssh://ando"

  registry_auth {
    address = "registry.fanya.dev"
    username = "ando"
    password = var.docker_registry_fanya_pw
  }

}
