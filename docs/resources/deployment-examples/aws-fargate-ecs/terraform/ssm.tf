
resource "aws_ssm_parameter" "jwt_secret" {
  name  = "/${var.environment}/anchorplatform/JWT_SECRET"
  type  = "SecureString"
  value = "${var.jwt_secret}"

    tags = {
    environment = "${var.environment}"
  }
}

data "aws_ssm_parameter" "jwt_secret" {
  name  = "/${var.environment}/anchorplatform/JWT_SECRET"
}

resource "aws_ssm_parameter" "sep10_signing_seed" {
  name  = "/${var.environment}/anchorplatform/SEP10_SIGNING_SEED"
  type  = "SecureString"
  value = "${var.sep10_signing_seed}"

    tags = {
    environment = "${var.environment}"
  }
}

data "aws_ssm_parameter" "sep10_signing_seed" {
  name  = "/${var.environment}/anchorplatform/SEP10_SIGNING_SEED"
}

resource "aws_ssm_parameter" "sqlite_username" {
  name  = "/${var.environment}/anchorplatform/SQLITE_USERNAME"
  type  = "SecureString"
  value = "${var.sqlite_username}"

    tags = {
    environment = "${var.environment}"
  }
}

data "aws_ssm_parameter" "sqlite_username" {
  name  = "/${var.environment}/anchorplatform/SQLITE_USERNAME" 
}

resource "aws_ssm_parameter" "sqlite_passowrd" {
  name  = "/${var.environment}/anchorplatform/SQLITE_PASSWORD"
  type  = "SecureString"
  value = "${var.sqlite_password}"

    tags = {
    environment = "${var.environment}"
  }
}

data "aws_ssm_parameter" "sqlite_password" {
  name  = "/${var.environment}/anchorplatform/SQLITE_PASSWORD" 
}


resource "aws_ssm_parameter" "sqs_access_key" {
  name  = "/${var.environment}/anchorplatform/SQS_ACCESS_KEY"
  type  = "SecureString"
  value = "${var.sqs_access_key}"

    tags = {
    environment = "${var.environment}"
  }
}

data "aws_ssm_parameter" "sqs_access_key" {
  name = "/${var.environment}/anchorplatform/SQS_ACCESS_KEY"
}

resource "aws_ssm_parameter" "sqs_secret_key" {
  name  = "/${var.environment}/anchorplatform/SQS_SECRET_KEY"
  type  = "SecureString"
  value = "${var.sqs_secret_key}"

    tags = {
    environment = "${var.environment}"
  }
}

data "aws_ssm_parameter" "sqs_secret_key" {
  name  = "/${var.environment}/anchorplatform/SQS_SECRET_KEY" 
}




