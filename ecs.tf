resource "aws_ecr_repository" "ecr_repo" {
  name                 = "canvas-diary/backend"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_lifecycle_policy" "ecr_lp" {
  repository = aws_ecr_repository.ecr_repo.name
  policy = data.aws_ecr_lifecycle_policy_document.leave_recent.json
}

data "aws_ecr_lifecycle_policy_document" "leave_recent" {
  rule {
    priority    = 1
    description = "최근 2개 이미지만 저장"

    selection {
      tag_status      = "any"
      count_type      = "imageCountMoreThan"
      count_number    = 2
    }
  }
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "canvas-diary"
}

resource "aws_ecs_task_definition" "ecr_deploy_task" {
  family = "canvas-diary-deploy"
  requires_compatibilities = ["EC2"]
  network_mode = "bridge"
  cpu = 1
  memory = 500
  execution_role_arn = "arn:aws:iam::339713161378:role/ecsTaskExecutionRole"
  task_role_arn = "arn:aws:iam::339713161378:role/ecsTaskExecutionRole"

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = "canvas-diary"
      image     = "image-uri"
      essential = true
      cpu       = 1
      memory    = 500
      memoryReservation = 500
      portMappings = [
        {
          hostPort      = 80
          containerPort = 8080
          protocol = "tcp"
        }
      ]
    }
  ])
}