# 1. 建立 IAM 使用者
resource "aws_iam_user" "github_actions" {
  name = "github-actions-user"
}

# 2. 為使用者建立存取金鑰 (Access Key)
resource "aws_iam_access_key" "github_actions_key" {
  user = aws_iam_user.github_actions.name
}

# 3. 綁定權限策略 (例如允許操作 ECS 和 ECR)
resource "aws_iam_user_policy_attachment" "ecs_full_access" {
  user       = aws_iam_user.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

resource "aws_iam_user_policy_attachment" "ecr_full_access" {
  user       = aws_iam_user.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

# 4. 輸出金鑰 (方便你之後填入 GitHub Secrets)
output "access_key_id" {
  value = aws_iam_access_key.github_actions_key.id
}

output "secret_access_key" {
  value     = aws_iam_access_key.github_actions_key.secret
  sensitive = true
}
