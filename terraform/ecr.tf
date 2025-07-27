resource "aws_ecr_repository" "web_app" {
  name = "blendergrid/web-app"
}

resource "aws_ecr_lifecycle_policy" "web_app" {
  repository = aws_ecr_repository.web_app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Only keep the 3 latest tagged images"
        selection = {
          tagStatus      = "tagged"
          tagPatternList = ["*"],
          countType      = "imageCountMoreThan"
          countNumber    = 3
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Expire all untagged images older than 14 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed",
          countUnit   = "days",
          countNumber = 14
        }
        action = { type = "expire" }
      },
    ]
  })
}
