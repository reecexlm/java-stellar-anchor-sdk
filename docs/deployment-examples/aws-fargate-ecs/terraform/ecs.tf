
resource "aws_ecs_cluster" "sep" {
  name = "sep-${var.environment}-cluster"
}

resource "aws_ecs_cluster" "ref" {
  name = "ref-${var.environment}-cluster"
}

resource "aws_ecs_task_definition" "sep" {
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  family                   = "${var.environment}-sep"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([{
   name        = "${var.environment}-sep"
   image       = "stellar/anchor-platform:9cea0d1"
   essential   = true
   portMappings = [{
     protocol      = "tcp"
     containerPort = 8080
     hostPort      = 8080
   }]
  }])
}

resource "aws_ecs_task_definition" "ref" {
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
    family                   = "${var.environment}-ref"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([{
   name        = "${var.environment}-reference"
   image       = "stellar/anchor-platform:9cea0d1"
   essential   = true
   portMappings = [{
     protocol      = "tcp"
     containerPort = 8081
     hostPort      = 8081
   }]
  }])
}

resource "aws_iam_role" "ecs_task_role" {
  name = "anchorplatform-ecsTaskRole"
 
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "anchorplatform-ecsTaskExecutionRole"
 
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}
 
resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_service" "sep" {
 name                               = "sep-${var.environment}-service"
 cluster                            = aws_ecs_cluster.sep.id
 task_definition                    = aws_ecs_task_definition.sep.arn
 desired_count                      = 2
 deployment_minimum_healthy_percent = 50
 deployment_maximum_percent         = 200
 launch_type                        = "FARGATE"
 scheduling_strategy                = "REPLICA"
 
 network_configuration {
   security_groups  = [aws_security_group.sep_alb.name]
   subnets          = module.vpc.public_subnets
   assign_public_ip = false
 }
 
 load_balancer {
   target_group_arn = aws_alb_target_group.sep.arn
   container_name   = "sep-container-${var.environment}"
   container_port   = 8080
 }
 
 lifecycle {
   ignore_changes = [task_definition, desired_count]
 }
}

resource "aws_lb" "sep" {
  name               = "sep-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sep_alb.name]
  subnets            = module.vpc.public_subnets
 
  enable_deletion_protection = false
}
 
resource "aws_alb_target_group" "sep" {
  name        = "sep-${var.environment}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"
 
  health_check {
   healthy_threshold   = "3"
   interval            = "30"
   protocol            = "HTTP"
   matcher             = "200"
   timeout             = "3"
   path                = "/health"
   unhealthy_threshold = "2"
  }
}

resource "aws_alb_listener" "sep_http" {
  load_balancer_arn = aws_lb.sep.id
  port              = 80
  protocol          = "HTTP"
 
  default_action {
   type = "redirect"
 
   redirect {
     port        = 443
     protocol    = "HTTPS"
     status_code = "HTTP_301"
   }
  }
}
data "aws_route53_zone" "anchor_zone" {
  name         = "${var.hosted_zone_name}"
  private_zone = false
}
 data "aws_acm_certificate" "issued" {
  domain   = "www.${data.aws_route53_zone.anchor_zone.name}"
  statuses = ["ISSUED"]
}
resource "aws_alb_listener" "sep_https" {
  load_balancer_arn = aws_lb.sep.id
  port              = 443
  protocol          = "HTTPS"
 
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   =  data.aws_acm_certificate.issued.arn
 
  default_action {
    target_group_arn = aws_alb_target_group.sep.id
    type             = "forward"
  }
}

#
# ref
#
resource "aws_ecs_service" "ref" {
 name                               = "sep-${var.environment}-service"
 cluster                            = aws_ecs_cluster.ref.id
 task_definition                    = aws_ecs_task_definition.ref.arn
 desired_count                      = 2
 deployment_minimum_healthy_percent = 50
 deployment_maximum_percent         = 200
 launch_type                        = "FARGATE"
 scheduling_strategy                = "REPLICA"
 
 network_configuration {
   security_groups  = [aws_security_group.ref_alb.name]
   subnets          = module.vpc.public_subnets
   assign_public_ip = false
 }
 
 load_balancer {
   target_group_arn = aws_alb_target_group.ref.arn
   container_name   = "ref-container-${var.environment}"
   container_port   = 8080
 }
 
 lifecycle {
   ignore_changes = [task_definition, desired_count]
 }
}

resource "aws_lb" "ref" {
  name               = "ref-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ref_alb.name]
  subnets            = module.vpc.private_subnets
 
  enable_deletion_protection = false
}
 
resource "aws_alb_target_group" "ref" {
  name        = "ref-${var.environment}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"
 
  health_check {
   healthy_threshold   = "3"
   interval            = "30"
   protocol            = "HTTP"
   matcher             = "200"
   timeout             = "3"
   path                = "/health"
   unhealthy_threshold = "2"
  }
}

resource "aws_alb_listener" "ref_http" {
  load_balancer_arn = aws_lb.ref.id
  port              = 8081
  protocol          = "HTTP"
 
  default_action {
   target_group_arn = aws_alb_target_group.ref.arn
   type             = "forward" 
  }
}
 


#resource "aws_iam_policy" "dynamodb" {
##  name        = "${var.name}-task-policy-dynamodb"
#  description = "Policy that allows access to DynamoDB"
# 
# policy = <<EOF
#{
#   "Version": "2012-10-17",
#   "Statement": [
#       {
#           "Effect": "Allow",
#           "Action": [
#               "dynamodb:CreateTable",
#           ],
#           "Resource": "*"
#       }
#   ]
#}
#EOF
#}
 
#resource "aws_iam_role_policy_attachment" "ecs-task-role-policy-attachment" {
#  role       = aws_iam_role.ecs_task_role.name
#  policy_arn = aws_iam_policy.dynamodb.arn
#}