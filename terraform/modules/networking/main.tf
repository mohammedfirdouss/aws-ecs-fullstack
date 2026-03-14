data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

# ── VPC ──────────────────────────────────────────────────────────────────────

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# ── Subnets ───────────────────────────────────────────────────────────────────

resource "aws_subnet" "public" {
  for_each = toset(local.azs)

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, index(local.azs, each.key))
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${each.key}"
    Tier = "public"
  }
}

resource "aws_subnet" "private" {
  for_each = toset(local.azs)

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, index(local.azs, each.key) + 10)

  tags = {
    Name = "${var.project_name}-private-${each.key}"
    Tier = "private"
  }
}

resource "aws_subnet" "isolated" {
  for_each = toset(local.azs)

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, index(local.azs, each.key) + 20)

  tags = {
    Name = "${var.project_name}-isolated-${each.key}"
    Tier = "isolated"
  }
}

# ── NAT Gateways ──────────────────────────────────────────────────────────────

resource "aws_eip" "nat" {
  count  = length(local.azs)
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip-${local.azs[count.index]}"
  }
}

resource "aws_nat_gateway" "this" {
  count = length(local.azs)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[local.azs[count.index]].id

  tags = {
    Name = "${var.project_name}-nat-${local.azs[count.index]}"
  }

  depends_on = [aws_internet_gateway.this]
}

# ── Route Tables ──────────────────────────────────────────────────────────────

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.project_name}-rt-public"
  }
}

resource "aws_route_table_association" "public" {
  for_each = toset(local.azs)

  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count = length(local.azs)

  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[count.index].id
  }

  tags = {
    Name = "${var.project_name}-rt-private-${local.azs[count.index]}"
  }
}

resource "aws_route_table_association" "private" {
  count = length(local.azs)

  subnet_id      = aws_subnet.private[local.azs[count.index]].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table" "isolated" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-rt-isolated"
  }
}

resource "aws_route_table_association" "isolated" {
  for_each = toset(local.azs)

  subnet_id      = aws_subnet.isolated[each.key].id
  route_table_id = aws_route_table.isolated.id
}

# ── VPC Endpoints ─────────────────────────────────────────────────────────────

resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.project_name}-vpc-endpoints"
  description = "Allow HTTPS from within the VPC to VPC interface endpoints."
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "HTTPS from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-vpc-endpoints-sg"
  }
}

locals {
  interface_endpoints = {
    ecr_api        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
    ecr_dkr        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
    secretsmanager = "com.amazonaws.${data.aws_region.current.name}.secretsmanager"
    logs           = "com.amazonaws.${data.aws_region.current.name}.logs"
  }

  private_subnet_ids_list = [for az in local.azs : aws_subnet.private[az].id]
}

data "aws_region" "current" {}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoints

  vpc_id              = aws_vpc.this.id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  subnet_ids          = local.private_subnet_ids_list
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-endpoint-${each.key}"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat(
    [aws_route_table.public.id, aws_route_table.isolated.id],
    aws_route_table.private[*].id
  )

  tags = {
    Name = "${var.project_name}-endpoint-s3"
  }
}
