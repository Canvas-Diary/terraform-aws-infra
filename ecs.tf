resource "aws_ecr_repository" "ecr_repository" {
  name                 = "canvas-diary/backend"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_lifecycle_policy" "example" {
  repository = aws_ecr_repository.ecr_repository.name
  policy = data.aws_ecr_lifecycle_policy_document.ecr_lifecycle_policy.json
}

data "aws_ecr_lifecycle_policy_document" "ecr_lifecycle_policy" {
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