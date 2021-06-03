provider "aws" {
  region = "us-east-1"
}

resource "aws_ecs_cluster" "demo_cluster_usa" {
  name = "demo-cluster-usa"
}

resource "aws_ecr_repository" "demo_ecr_repo" {
  name = "demo-url-ecr-repo"
}

resource "aws_vpc" "demo" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
}

resource "aws_security_group" "demo" {
  vpc_id = "${aws_vpc.demo.id}"
}

resource "aws_subnet" "demo" {
  cidr_block        = "10.0.1.0/24"
  vpc_id            = "${aws_vpc.demo.id}"
}

resource "aws_elasticache_subnet_group" "demo" {
  name        = "demo-acc-1"
  subnet_ids  = ["${aws_subnet.demo.id}"]
}


resource "aws_elasticache_cluster" "url" {
  cluster_id           = "demo-cluster-usa"
  engine               = "redis"
  node_type            = "cache.m4.large"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis5.0"
  engine_version       = "5.0.6"
  port                 = 6379
  security_group_ids   = ["${aws_security_group.demo.id}"]
  subnet_group_name    = "${aws_elasticache_subnet_group.demo.id}"
}

resource "aws_ecs_task_definition" "deploy_url_service" {
  family                   = "deploy-url-service"
  container_definitions    = <<DEFINITION
  [
    {
      "name": "deploy-url-service",
      "image": "${aws_ecr_repository.demo_ecr_repo.repository_url}",
      "essential": true,
      "environment": [
          {"name": "REDIS_PORT", "value": "6379"},
          {"name": "REDIS_HOST", "value": "demo-cluster-usa.qdqpk8.0001.use1.cache.amazonaws.com"}
      ],
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000
        }
      ],
      "memory": 512,
      "cpu": 256
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = 512
  cpu                      = 256
  execution_role_arn       = aws_iam_role.ecsDemoTaskExecutionRole.arn
}

resource "aws_iam_role" "ecsDemoTaskExecutionRole" {
  name               = "ecsDemoTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsDemoTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsDemoTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_lb_target_group" "target_group" {
  name        = "target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${aws_vpc.demo.id}"
  health_check {
    matcher = "200,301,302"
    path = "/"
  }
}

resource "aws_security_group" "load_balancer_security_group" {
  name        = "lb-sg"
  description = "Demo SG"
  vpc_id      = aws_vpc.demo.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "service_security_group" {
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_alb" "application_load_balancer" {
  name               = "url-lb"
  load_balancer_type = "application"
  subnets = [
    "${aws_subnet.demo.id}"
  ]
  security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = "${aws_alb.application_load_balancer.arn}"
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.target_group.arn}"
  }
}

resource "aws_ecs_service" "url-service" {
  name            = "url-service"
  cluster         = "${aws_ecs_cluster.demo_cluster_usa.id}"
  task_definition = "${aws_ecs_task_definition.deploy_url_service.arn}"
  launch_type     = "FARGATE"
  desired_count   = 2

  load_balancer {
    target_group_arn = "${aws_lb_target_group.target_group.arn}"
    container_name   = "${aws_ecs_task_definition.deploy_url_service.family}"
    container_port   = 3000
  }

  network_configuration {
    subnets          = ["${aws_subnet.demo.id}"]
    assign_public_ip = true
    security_groups  = ["${aws_security_group.service_security_group.id}"]
  }
}



