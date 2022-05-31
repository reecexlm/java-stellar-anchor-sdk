#provider "aws" {
#    region = "us-east-1"
#    alias = "regional"
#}

resource "local_file" "foo" {
    content  = "foo!"
    filename = "${path.module}/foo.bar"
}



locals {
  sepconfig = templatefile("${path.module}/templates/sep.tftpl",{
      "homeDomain"   = "www.stellaranchordemo.com"})
    appspec = templatefile("${path.module}/templates/appspec.tftpl",{})
}
  
data "archive_file" "deploypackage" {
  type        = "zip"
  output_path = "${path.module}/files/dotfiles.zip"
  excludes    = [ "${path.module}/unwanted.zip" ]

  source {
    content  = local.sepconfig
    filename = "anchor-config.yaml"
  }

  source {
    content  = local.appspec
    filename = "appspec.yml"
  }
}

resource "aws_s3_bucket_object" "file_upload" {
  #provider         = "aws.regional"
  bucket           = "sepconfig"
  key              = "anchorconfig.zip"
  content          = data.archive_file.deploypackage.output_path
}


