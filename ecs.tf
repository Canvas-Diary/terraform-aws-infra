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
  name = "canvas-diary-cluster"
}

resource "aws_ecs_task_definition" "ecr_deploy_task" {
  family = "canvas-diary-deploy"
  requires_compatibilities = ["EC2"]
  network_mode = "bridge"
  cpu = 512
  memory = 474
  execution_role_arn = "arn:aws:iam::339713161378:role/ecsTaskExecutionRole"
  task_role_arn = "arn:aws:iam::339713161378:role/ecsTaskExecutionRole"

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = "canvas-diary-app"
      image     = "${aws_ecr_repository.ecr_repo.repository_url}:latest"
      essential = true
      cpu       = 512
      memory    = 474
      memoryReservation = 474
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

resource "aws_ecs_service" "ecs_service" {
  name            = "canvas-diary-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  launch_type = "EC2"
  task_definition = aws_ecs_task_definition.ecr_deploy_task.arn
  desired_count   = 1
  wait_for_steady_state = true
}