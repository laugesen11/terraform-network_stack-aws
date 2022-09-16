module "network_boundaries" {
  source                          = "git@github.com:laugesen11/terraform-internal_network-aws.git"
  vpc_setup                       = var.vpc_setup
  nacl_setup                      = var.nacl_setup
  nat_gateways                    = var.nat_gateways
  vpc_peering                     = var.vpc_peering
  transit_gateways                = var.transit_gateways
  transit_gateway_vpc_attachments = var.transit_gateway_vpc_attachments
}

module "security_groups" {
  source          = "git@github.com:laugesen11/terraform-security_groups-aws.git"
  security_groups = var.security_groups
  vpcs            = module.network_boundaries.vpcs
}

module "route_tables" {
  source                        = "git@github.com:laugesen11/terraform-route_table-aws.git"
  route_tables                  = var.route_tables
  vpcs                          = module.network_boundaries.vpcs
}

module "vpc_endpoints" {
  source          = "git@github.com:laugesen11/terraform-vpc_endpoints-aws.git"
  vpc_endpoints   = var.vpc_endpoints
  vpcs            = module.network_boundaries.vpcs
  security_groups = module.security_groups.security_groups
}

#MAKE A FOR_EACH
#module "routes" {
#  source                        = "git@github.com:laugesen11/terraform-route_table-aws.git"
#  route_tables                  = module.route_tables
#  vpcs                          = module.network_boundaries.vpcs
#  internet_gateways             = module.network_boundaries.internet_gateways
#  egress_only_internet_gateways = module.network_boundaries.egress_only_internet_gateways
#  vpn_gateways                  = module.network_boundaries.vpn_gateways
#  nat_gateways                  = module.network_boundaries.nat_gateways
#  vpc_peering_connections       = module.network_boundaries.vpc_peering_connections
#  vpc_endpoints                 = module.network_boundaries.vpc_endpoints
#  transit_gateways              = module.network_boundaries.transit_gateways
#}
#
