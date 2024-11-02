resource "aws_ecr_repository" "ecr_repo" {
  name                 = "canvas-diary/backend"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_lifecycle_policy" "ecr_lp" {
  repository = aws_ecr_repository.ecr_repo.name
  policy     = data.aws_ecr_lifecycle_policy_document.leave_recent.json
  depends_on = [aws_ecr_repository.ecr_repo]
}

data "aws_ecr_lifecycle_policy_document" "leave_recent" {
  rule {
    priority    = 1
    description = "최근 2개 이미지만 저장"

    selection {
      tag_status   = "any"
      count_type   = "imageCountMoreThan"
      count_number = 2
    }
  }
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "canvas-diary-cluster"

}

resource "aws_autoscaling_group" "ecs_asg" {
  name = "canvas-diary-asg"

  launch_template {
    id      = aws_launch_template.ecs_instance_template.id
    version = "$Latest"
  }

  vpc_zone_identifier = [aws_subnet.public_subnet_1.id]
  desired_capacity    = 1
  min_size            = 1
  max_size            = 2

  instance_maintenance_policy {
    min_healthy_percentage = 100
    max_healthy_percentage = 200
  }

  target_group_arns = [aws_lb_target_group.nlb_tg.arn]

  tag {
    key                 = "Name"
    value               = "canvas-diary"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
}

resource "aws_ecs_capacity_provider" "ecs_cp" {
  name = "canvas-diary-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs_asg.arn

    managed_scaling {
      status          = "ENABLED"
      target_capacity = 100
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "example" {
  cluster_name       = aws_ecs_cluster.ecs_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.ecs_cp.name]
}

resource "aws_ecs_task_definition" "ecr_deploy_task" {
  family                   = "canvas-diary-deploy"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  cpu                      = 1024
  memory                   = 949
  execution_role_arn       = "arn:aws:iam::339713161378:role/ecsTaskExecutionRole"
  task_role_arn            = "arn:aws:iam::339713161378:role/ecsTaskExecutionRole"

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name              = "canvas-diary-app"
      image             = "${aws_ecr_repository.ecr_repo.repository_url}:latest"
      essential         = true
      cpu               = 1024
      memory            = 949
      memoryReservation = 949
      portMappings = [
        {
          hostPort      = 80
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      secrets = [
        {
          valueFrom = "arn:aws:secretsmanager:ap-northeast-2:339713161378:secret:canvas-diary/mysql-SKFMzk:DB_URL::",
          name      = "DB_URL"
        },
        {
          valueFrom = "arn:aws:secretsmanager:ap-northeast-2:339713161378:secret:canvas-diary/mysql-SKFMzk:DB_USERNAME::",
          name      = "DB_USERNAME"
        },
        {
          valueFrom = "arn:aws:secretsmanager:ap-northeast-2:339713161378:secret:canvas-diary/mysql-SKFMzk:DB_PASSWORD::",
          name      = "DB_PASSWORD"
        },
        {
          valueFrom = "arn:aws:secretsmanager:ap-northeast-2:339713161378:secret:canvas-diary/api-key-xosDpd:FLUX_API_KEY::",
          name      = "FLUX_API_KEY"
        },
        {
          valueFrom = "arn:aws:secretsmanager:ap-northeast-2:339713161378:secret:canvas-diary/api-key-xosDpd:GEMINI_API_KEY::",
          name      = "GEMINI_API_KEY"
        },
        {
          valueFrom = "arn:aws:secretsmanager:ap-northeast-2:339713161378:secret:canvas-diary/api-key-xosDpd:KAKAO_REST_API_KEY::",
          name      = "KAKAO_REST_API_KEY"
        },
        {
          valueFrom = "arn:aws:secretsmanager:ap-northeast-2:339713161378:secret:canvas-diary/api-key-xosDpd:KAKAO_CLIENT_SECRET::",
          name      = "KAKAO_CLIENT_SECRET"
        },
        {
          valueFrom = "arn:aws:secretsmanager:ap-northeast-2:339713161378:secret:canvas-diary/api-key-xosDpd:KAKAO_REDIRECT_URL::",
          name      = "KAKAO_REDIRECT_URL"
        },
        {
          valueFrom = "arn:aws:secretsmanager:ap-northeast-2:339713161378:secret:canvas-diary/api-key-xosDpd:JWT_SECRET_KEY::",
          name      = "JWT_SECRET_KEY"
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "ecs_service" {
  name            = "canvas-diary-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecr_deploy_task.arn
  desired_count   = 1

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_cp.name
    base              = 1
    weight            = 1
  }
}