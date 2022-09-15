vpc_setup=[
  { 
    name                             = "Larry test VPC"
    cidr_block                       = "10.0.0.0/16"
    tags                             = { "Env" : "Test" }
    options = {"has_vpn_gateway"=true,"has_internet_gateway"=true,"has_egress_only_internet_gateway"=true,"assign_generated_ipv6_cidr_block"=true,"tags"="Env=Test"}
    subnets = [
    {
        name              = "Larry Test Subnet"
        cidr_block        = "10.0.0.0/24"
        options           = {}
        tags              = {}
      },
      {
        name              = "Larry Test Subnet 2"
        cidr_block        = "10.0.1.0/24"
        options           = {}
        tags              = {}
      },
      {
        name              = "Larry Test Subnet 3"
        cidr_block        = "10.0.2.0/24"
        options           = {}
        tags              = {}
      }
    ]
  },
  { 
    name                             = "Larry test VPC 2"
    cidr_block                       = "192.168.0.0/16"
    options = {"has_vpn_gateway"=true,"has_internet_gateway"=true,"has_egress_only_internet_gateway"=true,"assign_generated_ipv6_cidr_block"=true}
    subnets = [
      {
        name              = "Larry Test Subnet 4"
        cidr_block        = "192.168.0.0/24"
        options           = {}
        tags              = {}
      },
    ],
  }, 
]

nacl_setup = [
  {
    nacl_name     = "default"
    vpc = "Larry test VPC"
    subnets  = ["Larry Test Subnet 3"]
    tags = {}
    nacl_rules = [ 
      {
        traffic_type        = "all"
        rule_number         = 100
        external_cidr_range = "0.0.0.0/0"
        options             = {}
      },
      {
        traffic_type        = "ssh"
        rule_number         = 200
        external_cidr_range = "::/0"
        options             = {"deny_access"=true}
      },
      {
        traffic_type        = "all"
        rule_number         = 100
        external_cidr_range = "0.0.0.0/0"
        options             = {"is_ingress"=true}
      },
      {
        traffic_type        = "custom"
        rule_number         = 200
        external_cidr_range = "0.0.0.0/0"
        options             = {"is_ingress"=true,"to_port"=22,"from_port"=22,"protocol"="tcp"}
      },
      {
        traffic_type        = "all"
        rule_number         = 300
        external_cidr_range = "0.0.0.0/0"
        options             = {"is_ingress"=true,"protocol"="icmp","to_port"=-1,"from_port"=-1,"icmp_code"=0,"icmp_type"=0}
      },
    ],
  },
]

nat_gateways = [
  {
    name              = "sample NAT gateway"
    subnet            = "Larry Test Subnet 3"
    options           = {"make_elastic_ip"=true,"is_public"=true,"tags"="Type=Example"}
  },
]

vpc_peering = [
  {
    name = "sample VPC peering"
    requestor_vpc = "Larry test VPC"
    peer_vpc      = "Larry test VPC 2"
    options       = {"auto_accept"=true,"tags"="Name=VPC peering example"}
  },
]

vpc_endpoints = [
  {
    name                = "Sample S3 Gateway endpoint"
    service_name        = "com.amazonaws.us-east-1.s3"
    vpc_id              = null
    vpc_name            = "Larry test VPC"
    auto_accept         = true
    private_dns_enabled = true
    security_group_ids  = null
    vpc_endpoint_type   = "Gateway"
    tags                = { "Type" = "Sample" }

    subnets = [
      {
        name = "Larry Test Subnet"
        id = null
      },
    ]
  },
]

transit_gateways = [
  {
    name                                   = "sample transit gateway"
    options                                = {"enable_dns_support"=true,tags="Type=Sample"}
  },
]

transit_gateway_vpc_attachments = [
  {
    name                                                   = "sample transit gateway to Larry test VPC attachment"
    transit_gateway                                        = "sample transit gateway"
    vpc                                                    = "Larry test VPC"
    subnets                                                = ["Larry Test Subnet"]
    options                                                = {tags="Type=Example, do not use"}
  },
]
