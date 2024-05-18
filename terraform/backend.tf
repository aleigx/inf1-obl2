terraform {
  backend "s3"{
  bucket = "terraform-state-inf1"
  key = "terrraform.tfstate"
  region = "us-west-2"
  }
}