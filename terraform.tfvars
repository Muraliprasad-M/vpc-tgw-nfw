region="eu-west-2"
vpc_cidr="10.232.0.0/22"
azs=["eu-west-2a","eu-west-2b","eu-west-2c"]
subnet_cidrs={
 a={ private="10.232.0.0/25" firewall="10.232.0.128/28" tgw_attach="10.232.0.144/28" public_egress="10.232.0.160/28" endpoints="10.232.0.192/25" }
 b={ private="10.232.1.0/25" firewall="10.232.1.128/28" tgw_attach="10.232.1.144/28" public_egress="10.232.1.160/28" endpoints="10.232.1.192/25" }
 c={ private="10.232.2.0/25" firewall="10.232.2.128/28" tgw_attach="10.232.2.144/28" public_egress="10.232.2.160/28" endpoints="10.232.2.192/25" }
}
tags={ Owner="Infra" Environment="dev" CostCenter="network" Sapid="2286671"}
