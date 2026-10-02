locals {
  nat_gateway_count = var.enable_nat_gateway ? (
    var.nat_gateway_mode == "single" ? 1 : length(var.public_subnet_ids)
  ) : 0
}

resource "aws_internet_gateway" "this" {
  vpc_id = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-igw"
  })
}

resource "aws_eip" "nat" {
  count = local.nat_gateway_count

  domain = "vpc"

  tags = merge(var.tags, {
    Name = var.nat_gateway_mode == "single" ? "${var.name_prefix}-nat-eip" : "${var.name_prefix}-nat-eip-${count.index + 1}"
  })
}

resource "aws_nat_gateway" "this" {
  count = local.nat_gateway_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = var.public_subnet_ids[count.index]

  tags = merge(var.tags, {
    Name = var.nat_gateway_mode == "single" ? "${var.name_prefix}-nat" : "${var.name_prefix}-nat-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-rt"
    Tier = "public"
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = var.internet_cidr_block
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_ids)

  subnet_id      = var.public_subnet_ids[count.index]
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private_app" {
  count = length(var.private_app_subnet_ids)

  vpc_id = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-app-rt-${count.index + 1}"
    Tier = "private-app"
  })
}

resource "aws_route" "private_app_nat" {
  count = var.enable_nat_gateway ? length(var.private_app_subnet_ids) : 0

  route_table_id         = aws_route_table.private_app[count.index].id
  destination_cidr_block = var.internet_cidr_block

  nat_gateway_id = var.nat_gateway_mode == "single" ? aws_nat_gateway.this[0].id : aws_nat_gateway.this[count.index % length(aws_nat_gateway.this)].id
}

resource "aws_route_table_association" "private_app" {
  count = length(var.private_app_subnet_ids)

  subnet_id      = var.private_app_subnet_ids[count.index]
  route_table_id = aws_route_table.private_app[count.index].id
}

resource "aws_route_table" "private_db" {
  count = length(var.private_db_subnet_ids)

  vpc_id = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-db-rt-${count.index + 1}"
    Tier = "private-db"
  })
}

resource "aws_route" "private_db_nat" {
  count = var.enable_db_subnet_nat_route && var.enable_nat_gateway ? length(var.private_db_subnet_ids) : 0

  route_table_id         = aws_route_table.private_db[count.index].id
  destination_cidr_block = var.internet_cidr_block

  nat_gateway_id = var.nat_gateway_mode == "single" ? aws_nat_gateway.this[0].id : aws_nat_gateway.this[count.index % length(aws_nat_gateway.this)].id
}

resource "aws_route_table_association" "private_db" {
  count = length(var.private_db_subnet_ids)

  subnet_id      = var.private_db_subnet_ids[count.index]
  route_table_id = aws_route_table.private_db[count.index].id
}