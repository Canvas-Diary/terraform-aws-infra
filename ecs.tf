resource "aws_ecr_repository" "ecr_repository" {
  name                 = "canvas-diary/backend"
  image_tag_mutability = "MUTABLE"
}