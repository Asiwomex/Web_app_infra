resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
  })
}

# ─── Internet Gateway ─────────────────────────────────────────────────────────

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-igw"
  })
}

# ─── Public Subnets (ALB requires 2 AZs) ─────────────────────────────────────

resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_az1_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-public-az1"
    Tier = "Public"
  })
}

resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_az2_cidr
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-public-az2"
    Tier = "Public"
  })
}

# ─── Private Subnets ──────────────────────────────────────────────────────────

resource "aws_subnet" "private_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_az1_cidr
  availability_zone = "${var.aws_region}a"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-private-az1"
    Tier = "Private"
  })
}

resource "aws_subnet" "private_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_az2_cidr
  availability_zone = "${var.aws_region}b"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-private-az2"
    Tier = "Private"
  })
}

# ─── NAT Gateways (outbound for private subnets) ─────────────────────────────
# single_nat_gateway=true  → one NAT GW in AZ1 (dev/staging, cost-optimised)
# single_nat_gateway=false → one NAT GW per AZ (prod, survives AZ1 failure)

resource "aws_eip" "nat_az1" {
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-nat-eip-az1"
  })

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "az1" {
  allocation_id = aws_eip.nat_az1.id
  subnet_id     = aws_subnet.public_az1.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-nat-az1"
  })

  depends_on = [aws_internet_gateway.main]
}

resource "aws_eip" "nat_az2" {
  count  = var.single_nat_gateway ? 0 : 1
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-nat-eip-az2"
  })

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "az2" {
  count         = var.single_nat_gateway ? 0 : 1
  allocation_id = aws_eip.nat_az2[0].id
  subnet_id     = aws_subnet.public_az2.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-nat-az2"
  })

  depends_on = [aws_internet_gateway.main]
}

locals {
  nat_gateway_az2_id = var.single_nat_gateway ? aws_nat_gateway.az1.id : aws_nat_gateway.az2[0].id
}

# ─── Route Tables ─────────────────────────────────────────────────────────────

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-public-rt"
  })
}

resource "aws_route_table" "private_az1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.az1.id
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-private-rt-az1"
  })
}

resource "aws_route_table" "private_az2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = local.nat_gateway_az2_id
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-private-rt-az2"
  })
}

resource "aws_route_table_association" "public_az1" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_az2" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_az1" {
  subnet_id      = aws_subnet.private_az1.id
  route_table_id = aws_route_table.private_az1.id
}

resource "aws_route_table_association" "private_az2" {
  subnet_id      = aws_subnet.private_az2.id
  route_table_id = aws_route_table.private_az2.id
}

# ─── VPC Flow Logs ────────────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "vpc_flow" {
  name              = "/aws/vpc/${var.project_name}-${var.environment}/flow-logs"
  retention_in_days = 30
  skip_destroy      = false

  tags = var.tags
}

resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.project_name}-${var.environment}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "${var.project_name}-${var.environment}-vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-flow-logs"
  })
}

# ─── VPC Gateway Endpoints (FREE — bypass NAT Gateway for S3/DynamoDB) ───────
# S3 traffic from private subnets goes directly to the AWS backbone instead of
# through the NAT Gateway, eliminating NAT data-processing charges ($0.045/GB).

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private_az1.id, aws_route_table.private_az2.id]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-s3-endpoint"
  })
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private_az1.id, aws_route_table.private_az2.id]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-dynamodb-endpoint"
  })
}
