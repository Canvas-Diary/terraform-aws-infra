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

resource "aws_ecs_task_definition" "ecr_deploy_task" {
  family                   = "canvas-diary-deploy"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  cpu                      = 512
  memory                   = 474
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
      cpu               = 512
      memory            = 474
      memoryReservation = 474
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
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "ecs_service" {
  name                               = "canvas-diary-service"
  cluster                            = aws_ecs_cluster.ecs_cluster.id
  launch_type                        = "EC2"
  task_definition                    = aws_ecs_task_definition.ecr_deploy_task.arn
  desired_count                      = 1
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100
}