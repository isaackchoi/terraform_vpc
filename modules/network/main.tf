# ==========================================
# 2. VPC & 高可用雙子網路
# ==========================================
resource "aws_vpc" "logistics_vpc" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = "Isaac-Logistics-VPC" }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.logistics_vpc.id
  cidr_block        = "10.10.1.0/24"
  availability_zone = "us-east-1a"
  tags              = { Name = "Isaac-Public-Subnet-1" }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.logistics_vpc.id
  cidr_block        = "10.10.2.0/24"
  availability_zone = "us-east-1b"
  tags              = { Name = "Isaac-Public-Subnet-2" }
}

# ==========================================
# 3. 聯外網路與路由地圖 (IGW & Route Table)
# ==========================================
resource "aws_internet_gateway" "logistics_igw" {
  vpc_id = aws_vpc.logistics_vpc.id
  tags   = { Name = "Isaac-Logistics-IGW" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.logistics_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.logistics_igw.id
  }
  tags = { Name = "Isaac-Public-RouteTable" }
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
# 8. 私有子網路與 NAT 網關 (打通網路黑洞)
# ==========================================
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.logistics_vpc.id
  cidr_block        = "10.10.3.0/24"
  availability_zone = "us-east-1a"
  tags              = { Name = "isaac-private-subnet-1" }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.logistics_vpc.id
  cidr_block        = "10.10.4.0/24"
  availability_zone = "us-east-1b"
  tags              = { Name = "isaac-private-subnet-2" }
}

resource "aws_eip" "nat_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.logistics_igw]
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
  tags          = { Name = "isaac-nat-gateway" }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.logistics_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = { Name = "isaac-private-route-table" }
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_assoc_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}
