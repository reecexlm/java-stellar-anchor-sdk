
locals {
  subnet_arns = formatlist(
                    "arn:aws:ec2:us-east-2:245943599471:subnet/%s",
                    module.vpc.private_subnets
                )
}

resource "aws_ecr_repository" "anchor_config" {
  name                 = "${var.environment}-anchor-config"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_s3_bucket" "anchor_config" {
  bucket = "${var.environment}-anchor-config"
  tags = {
    Environment = "${var.environment}"
  }
}

resource "aws_s3_bucket_acl" "anchor_config" {
  bucket = aws_s3_bucket.anchor_config.id
  acl    = "private"
}

resource "aws_iam_role" "codebuild_role" {
  name = "${var.environment}-anchorplatform-codebuild"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codebuild_policy" {
  role = aws_iam_role.codebuild_role.name

  policy = jsonencode(
    {
        "Version": "2012-10-17",
        "Statement": [
            {   "Effect": "Allow",
                "Resource": [
                  "${var.docker_password_arn}"
                ],
                "Action": [
                  "secretsmanager:GetSecretValue" 
                ]  
            },
            {
                "Effect": "Allow",
                "Resource": [
                    "arn:aws:logs:*",
                ],
                "Action": [
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream",
                    "logs:PutLogEvents"
                ]
            },
            {
                "Effect": "Allow",
                "Resource": [
                    "*"
                ],
                "Action": [
                  "ecr:GetAuthorizationToken",
                  "ecr:BatchCheckLayerAvailability",
                  "ecr:GetDownloadUrlForLayer",
                  "ecr:GetRepositoryPolicy",
                  "ecr:DescribeRepositories",
                  "ecr:ListImages",
                  "ecr:DescribeImages",
                  "ecr:BatchGetImage",
                  "ecr:GetLifecyclePolicy",
                  "ecr:GetLifecyclePolicyPreview",
                  "ecr:ListTagsForResource",
                  "ecr:DescribeImageScanFindings"
                ]
            },
            {
                "Effect": "Allow",
                "Resource": [
                    "*"
                ],
                "Action": [
                    "ec2:DescribeSubnets",
                    "ec2:CreateNetworkInterface",
                    "ec2:DescribeDhcpOptions",
                    "ec2:DescribeNetworkInterfaces",
                    "ec2:DeleteNetworkInterface",
                    "ec2:DescribeSubnets",
                    "ec2:DescribeSecurityGroups",
                    "ec2:DescribeVpcs"
                ]
            },
            {
                "Effect": "Allow",
                "Action": [
                  "ec2:CreateNetworkInterfacePermission"
                ],
                "Resource": [
                  "arn:aws:ec2:us-east-2:245943599471:network-interface/*"
                ],
                "Condition": {
                  "StringEquals": {
                    "ec2:Subnet": local.subnet_arns,
                    "ec2:AuthorizedService": "codebuild.amazonaws.com"
                  }
                }
              },
            {
                "Effect": "Allow",
                "Resource": [
                    "arn:aws:s3:::${aws_s3_bucket.anchor_config.bucket}/*",
                    "arn:aws:s3:::${aws_s3_bucket.anchor_config.bucket}"
                ],
                "Action": [
                    "s3:GetObject",
                    "s3:GetObjectVersion",
                    "s3:GetBucketAcl",
                    "s3:GetBucketLocation",
                    "s3:ListBucket"
                ]
            },
            {
                "Effect": "Allow",
                "Action": [
                    "codebuild:CreateReportGroup",
                    "codebuild:CreateReport",
                    "codebuild:UpdateReport",
                    "codebuild:BatchPutTestCases",
                    "codebuild:BatchPutCodeCoverages"
                ],
                "Resource": [
                    "arn:aws:codebuild:us-east-2:245943599471:report-group/${var.environment}-anchor-config"
                ]
            }
        ]
    })
}


resource "aws_codebuild_project" "codebuild_config" {
  name          = "${var.environment}-anchorplatform-config"
  description   = "config image"
  build_timeout = "5"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

      environment_variable {
        name  = "ANCHOR_CONFIG_ENVIRONMENT"
        value = "${var.environment}"
      }

      environment_variable {
        name  = "ANCHOR_CONFIG_S3_BUCKET"
        value = "${var.environment}-anchor-config"
      }
      environment_variable {
       name  = "ANCHOR_CONFIG_ECR_REPO"
        value = aws_ecr_repository.anchor_config.name
      }

      environment_variable {
        name  = "AWS_ACCOUNT"
        value = var.aws_account
      }

       environment_variable {
        name  = "AWS_REGION"
        value = var.aws_region
      }

      environment_variable {
        name  = "ANCHOR_CONFIG_DOCKER_LOGIN_SECRET"
        value = "/CodeBuild/dockerLoginPassword"
      }

    }

  logs_config {
    cloudwatch_logs {
      group_name  = "anchorplatform-${var.environment}-codebuild"
      stream_name = "codebuild"
    }
  }
  
  # source location temporary
  source {
    type            = "GITHUB"
    buildspec       = var.anchor_config_build_spec
    location        = var.anchor_config_repository 
    git_clone_depth = 1

    git_submodules_config {
      fetch_submodules = true
    }
  }

  source_version = "refs/heads/fargate"

  vpc_config {
    vpc_id = module.vpc.vpc_id
    subnets = module.vpc.private_subnets

    security_group_ids = [aws_security_group.sep.id]
  }

  tags = {
    Environment = "${var.environment}"
  }

  depends_on = [aws_iam_role.codebuild_role]

}