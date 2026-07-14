# ==========================================
# 0. 核心部門調用與編排 (Orchestration)
# ==========================================

# 🌐 1. 網路部門
module "network" {
  source = "./modules/network"
}

# 💾 2. 資料庫部門
module "data" {
  source             = "./modules/data"
  vpc_id             = module.network.vpc_id
  ecs_sg_id          = module.compute.ecs_sg_id # 💡 從運算部門拿安全組 ID
  private_subnet_ids = module.network.private_subnet_ids
}

# 🚀 3. 運算部門 (包含 ALB, ECS, ECR, IAM)
module "compute" {
  source             = "./modules/compute"
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids
  rds_endpoint       = module.data.rds_endpoint
  rds_db_name        = module.data.rds_db_name
  rds_username       = module.data.rds_username
  rds_password       = module.data.rds_password
}

# ==========================================
# 1. 全域環境供應商宣告
# ==========================================
provider "aws" {
  region = "us-east-1"
}

# ==========================================
# 2. 全域對外接口輸出 (Outputs)
# ==========================================
output "ecr_repository_url" {
  value = module.compute.ecr_repository_url
}

output "rds_endpoint" {
  value = module.data.rds_endpoint
}
