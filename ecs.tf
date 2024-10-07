resource "aws_ecr_repository" "ecr_repo" {
  name                 = "canvas-diary/backend"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_lifecycle_policy" "ecr_lp" {
  repository = aws_ecr_repository.ecr_repo.name
  policy = data.aws_ecr_lifecycle_policy_document.ecr_lp_doc.json
}

data "aws_ecr_lifecycle_policy_document" "ecr_lp_doc" {
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