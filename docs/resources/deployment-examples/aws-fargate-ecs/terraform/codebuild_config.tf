
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
  role = aws_iam_role.example.name

  policy = ${jsonencode(
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Resource": [
                    "arn:aws:logs:us-east-2:245943599471:log-group:/aws/codebuild/anchorplatform-${environment}",
                    "arn:aws:logs:us-east-2:245943599471:log-group:/aws/codebuild/anchorplatform-${environment}:*"
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
                    "arn:aws:s3:::${environment}-anchorconfig"
                ],
                "Action": [
                    "s3:GetObject",
                    "s3:GetObjectVersion",
                    "s3:GetBucketAcl",
                    "s3:GetBucketLocation"
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
                    "arn:aws:codebuild:us-east-2:245943599471:report-group/${environment}-anchor-config-*"
                ]
            }
        ]
    }
  )}
}

resource "aws_codebuild_project" "codebuild_config" {
  name          = "${environment}-anchorplatform-config"
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
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "anchorplatform-${environment}-codebuild"
      stream_name = "codebuild"
    }
  }
  
  # source location temporary
  source {
    type            = "GITHUB"
    location        = "https://github.com/reecexlm/java-stellar-anchor-sdk"
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
    Environment = "${environment}"
  }
}