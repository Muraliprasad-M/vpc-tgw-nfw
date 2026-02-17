variable "vpc_cidr" { type=string default="10.232.0.0/22" }
variable "azs" { type=list(string) default=["eu-west-2a","eu-west-2b","eu-west-2c"] }
variable "subnet_cidrs" { description="Map of per-AZ CIDRs for roles: private, firewall, tgw_attach, public_egress, endpoints"
  type = map(object({ private=string, firewall=string, tgw_attach=string, public_egress=string, endpoints=string })) }
variable "tgw_id" { description="Existing TGW ID to attach. If null, skip." type=string default=null }
variable "create_nfw" { type=bool default=false }
variable "nfw_policy_arn" { type=string default=null }
locals { endpoint_services=[for s in ["ssm","ssmmessages","ec2messages","sts","kms","logs"]: "com.amazonaws.${data.aws_region.current.name}.${s}"] }
variable "tags" { type=map(string) default={ Owner="Infra" Environment="dev" CostCenter="network" } }
