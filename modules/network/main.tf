# ==========================================
# 1. 取得動態可用區 (Dynamic Availability Zones)
# ==========================================
data "aws_availability_zones" "available" {
  state = "available"
}

# ==========================================
# 2. VPC & 高可用雙子網路
# ==========================================
resource "aws_vpc" "logistics_vpc" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = "${var.project_name}-${var.environment}-vpc" }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.logistics_vpc.id
  cidr_block        = "10.10.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags              = { Name = "${var.project_name}-${var.environment}-public-1" }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.logistics_vpc.id
  cidr_block        = "10.10.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags              = { Name = "${var.project_name}-${var.environment}-public-2" }
}

# ==========================================
# 3. 聯外網路與路由地圖 (IGW & Route Table)
# ==========================================
resource "aws_internet_gateway" "logistics_igw" {
  vpc_id = aws_vpc.logistics_vpc.id
  tags   = { Name = "${var.project_name}-${var.environment}-igw" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.logistics_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.logistics_igw.id
  }
  tags = { Name = "${var.project_name}-${var.environment}-public-rt" }
}

resource "aws_route_table_association" "public_subnet_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_subnet_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# ==========================================
# 4. 私有子網路與 NAT 網關 (打通網路黑洞)
# ==========================================
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.logistics_vpc.id
  cidr_block        = "10.10.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags              = { Name = "${var.project_name}-${var.environment}-private-1" }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.logistics_vpc.id
  cidr_block        = "10.10.4.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags              = { Name = "${var.project_name}-${var.environment}-private-2" }
}

resource "aws_subnet" "private_subnet_3" {
  vpc_id            = aws_vpc.logistics_vpc.id
  cidr_block        = "10.10.5.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags              = { Name = "${var.project_name}-${var.environment}-private-3" }
}

resource "aws_eip" "nat_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.logistics_igw]
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
  tags          = { Name = "${var.project_name}-${var.environment}-nat-gw" }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.logistics_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = { Name = "${var.project_name}-${var.environment}-private-rt" }
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_assoc_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_assoc_3" {
  subnet_id      = aws_subnet.private_subnet_3.id
  route_table_id = aws_route_table.private_rt.id
}


