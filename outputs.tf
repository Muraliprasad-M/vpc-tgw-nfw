output "vpc_id" {
  value = aws_vpc.this.id
}

output "subnets_by_role" {
  value = {
    private = {
      for k, s in aws_subnet.private : k => s.id
    }
    firewall = {
      for k, s in aws_subnet.firewall : k => s.id
    }
    tgw_attach = {
      for k, s in aws_subnet.tgw : k => s.id
    }
    public_egress = {
      for k, s in aws_subnet.public_egress : k => s.id
    }
    endpoints = {
      for k, s in aws_subnet.endpoints : k => s.id
    }
  }
}

output "nat_gateways" {
  value = {
    for k, n in aws_nat_gateway.this : k => n.id
  }
}
