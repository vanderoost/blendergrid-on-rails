resource "aws_ecr_repository" "web_app" {
  name = "blendergrid/web-app"
}

resource "aws_ecr_lifecycle_policy" "web_app" {
  repository = aws_ecr_repository.web_app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep the 16 most recent untagged images, expire all others"
        selection = {
          tagStatus   = "untagged"
          countType   = "imageCountMoreThan"
          countNumber = 16
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep the 8 most recent tagged images, expire all others"
        selection = {
          tagStatus      = "tagged"
          tagPatternList = ["*"],
          countType      = "imageCountMoreThan"
          countNumber    = 8
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 3
        description  = "Expire all images older than 30 days"
        selection = {
          tagStatus   = "any"
          countType   = "sinceImagePushed",
          countUnit   = "days",
          countNumber = 30
        }
        action = { type = "expire" }
      },
    ]
  })
}
