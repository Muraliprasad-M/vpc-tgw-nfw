locals {
  az_suffixes = ["a", "b", "c", "d", "e"]
  az_map = {
    for idx, az in var.azs : local.az_suffixes[idx] => az
    if idx < length(local.az_suffixes)
  }
}
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = "vpc-it" })
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "vpc-it-igw" })
}
resource "aws_subnet" "private" {
  for_each          = local.az_map
  vpc_id            = aws_vpc.this.id
  availability_zone = each.value
  cidr_block        = var.subnet_cidrs[each.key].private
  tags              = merge(var.tags, { Name = "private-${each.value}", Role = "private" })
}
resource "aws_subnet" "firewall" {
  for_each          = local.az_map
  vpc_id            = aws_vpc.this.id
  availability_zone = each.value
  cidr_block        = var.subnet_cidrs[each.key].firewall
  tags              = merge(var.tags, { Name = "firewall-${each.value}", Role = "firewall-endpoint" })
}
resource "aws_subnet" "tgw" {
  for_each          = local.az_map
  vpc_id            = aws_vpc.this.id
  availability_zone = each.value
  cidr_block        = var.subnet_cidrs[each.key].tgw_attach
  tags              = merge(var.tags, { Name = "tgw-attach-${each.value}", Role = "tgw-attach" })
}
resource "aws_subnet" "public_egress" {
  for_each                = local.az_map
  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value
  cidr_block              = var.subnet_cidrs[each.key].public_egress
  map_public_ip_on_launch = true
  tags                    = merge(var.tags, { Name = "public-egress-${each.value}", Role = "public-egress" })
}
resource "aws_subnet" "endpoints" {
  for_each          = local.az_map
  vpc_id            = aws_vpc.this.id
  availability_zone = each.value
  cidr_block        = var.subnet_cidrs[each.key].endpoints
  tags              = merge(var.tags, { Name = "endpoints-${each.value}", Role = "endpoints" })
}
resource "aws_eip" "nat" {
  for_each = local.az_map
  domain   = "vpc"
  tags     = merge(var.tags, { Name = "eip-nat-${each.value}" })
}
resource "aws_nat_gateway" "this" {
  for_each      = local.az_map
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public_egress[each.key].id
  depends_on    = [aws_internet_gateway.igw]
  tags          = merge(var.tags, { Name = "nat-${each.value}" })
}
resource "aws_route_table" "public_egress" {
  for_each = local.az_map
  vpc_id   = aws_vpc.this.id
  tags     = merge(var.tags, { Name = "rtb-public-egress-${each.value}" })
}
resource "aws_route" "public_0_default" {
  for_each               = local.az_map
  route_table_id         = aws_route_table.public_egress[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}
resource "aws_route_table_association" "public_egress_assoc" {
  for_each       = local.az_map
  subnet_id      = aws_subnet.public_egress[each.key].id
  route_table_id = aws_route_table.public_egress[each.key].id
}
resource "aws_route_table" "private" {
  for_each = local.az_map
  vpc_id   = aws_vpc.this.id
  tags     = merge(var.tags, { Name = "rtb-private-${each.value}" })
}
resource "aws_route" "private_0_default" {
  for_each               = local.az_map
  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[each.key].id
}
resource "aws_route_table_association" "private_assoc" {
  for_each       = local.az_map
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}
resource "aws_route_table" "endpoints" {
  for_each = local.az_map
  vpc_id   = aws_vpc.this.id
  tags     = merge(var.tags, { Name = "rtb-endpoints-${each.value}" })
}
resource "aws_route_table_association" "endpoints_assoc" {
  for_each       = local.az_map
  subnet_id      = aws_subnet.endpoints[each.key].id
  route_table_id = aws_route_table.endpoints[each.key].id
}
resource "aws_security_group" "vpce" {
  name        = "sg-vpce"
  description = "Allow HTTPS from VPC to Interface Endpoints"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "sg-vpce" })
}
resource "aws_vpc_endpoint" "interface" {
  for_each            = toset(local.endpoint_services)
  vpc_id              = aws_vpc.this.id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for k in keys(aws_subnet.endpoints) : aws_subnet.endpoints[k].id]
  security_group_ids  = [aws_security_group.vpce.id]
  private_dns_enabled = true
  tags = merge(var.tags, {
    Name = "vpce-${replace(each.value, "com.amazonaws.${data.aws_region.current.name}.", "")}"
  })
}
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw" {
  count              = var.tgw_id == null ? 0 : 1
  subnet_ids         = [for k in keys(aws_subnet.tgw) : aws_subnet.tgw[k].id]
  transit_gateway_id = var.tgw_id
  vpc_id             = aws_vpc.this.id
  tags               = merge(var.tags, { Name = "tgw-attach" })
}
resource "aws_networkfirewall_firewall" "this" {
  count               = var.create_nfw ? 1 : 0
  firewall_policy_arn = var.nfw_policy_arn
  name                = "nfw-it"
  vpc_id              = aws_vpc.this.id
  subnet_mapping = [
    for k in keys(aws_subnet.firewall) : {
      subnet_id = aws_subnet.firewall[k].id
    }
  ]
  tags = merge(var.tags, { Name = "nfw-it" })
}
