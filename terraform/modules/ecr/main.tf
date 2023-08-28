variable "prefix_environment" {
}

resource "aws_ecr_repository" "nequi-platform-ms-ecrrepository" {
  name                 = "nequi-platform-ms"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}