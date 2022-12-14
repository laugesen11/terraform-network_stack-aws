#Declare variables. 
#
#We have declared the below variables:
#
#VPC SETUP VARIABLES:
#  vpc_setup    - Sets up the VPCs we want to create.
#    Sub variable:
#      subnets - creates subnets within this VPC
# 
#NACL SETUP VARIABLES:
#  nacl_egress_rules  - sets the egress rules for NACLs
#  nacl_ingress_rules - sets the ingress rules for NACLs
#
#NETWORK ITEM SETUP VARIABLES:
#  nat_gateways  - sets up NAT gateways
#  vpc_peering   - sets up VPC peering connections
#  vpc_endpoints - sets up VPC endpoints
#  
#SECURITY GROUP SETUP
#

#Base setup for VPC
variable "vpc_setup" {
  description = "Sets up the VPCs in our network. Need to set the name, cidr_block, tags, amazon_side_asn (set to below 0 to disable), ipv6_enabled, and has_vpn_gateway"
  default = null

  type = list(
     object({
       name                             = string
       cidr_block                       = string
       #Sets up options values for VPC
       #Valid values include:
       #  - "has_vpn_gateway"                  - sets up a Virtual Private gateway (VPN gateway) to this VPC
       #  - "has_internet_gateway"             - sets up an Internet gateway to this VPC
       #  - "has_egress_only_internet_gateway" - sets up an Egress Only Internet gateway to this VPC
       #  - "dedicated_tenancy"                - sets up the instance_tenancy to be "dedicated". If not set, instance_tenancy is set to "default", or shared tenancy
       #  - "disable_dns_support"              - Overrides default setting that sets enable_dns_support to true
       #  - "enable_dns_hostname"              - Overrides default setting that sets enable_dns_hostname to false
       #  - "assign_generated_ipv6_cidr_block" - Assigns an IPv6 CIDR block
       #  - "amazon_side_asn=<number>"         - sets up a custom Amazon side ASN for use with VPN gateway. If not set, AWS will set a default value
       #  - tags="<tag_name1>=<tag_value1>,<tag_name2>=<tag_value2>,..."
       options                          = map(any)

 
       subnets = list(
         object({
           name              = string
           cidr_block        = string
           #Sets optional values for subnets
           #Valid values include:
           #  - "assign_ipv6_address_on_creation = <true|false>"                - indicates that network interfaces created in the specified subnet should be assigned an IPv6 address
           #  - "enable_dns64 = <true|false>"                                   - Indicates whether DNS queries made to the Amazon-provided DNS Resolver in this subnet should return synthetic IPv6 addresses for IPv4-only destinations
           #  - "enable_resource_name_dns_aaaa_record_on_launch = <true|false>" - Indicates whether to respond to DNS queries for instance hostnames with DNS AAAA records
           #  - "enable_resource_name_dns_a_record_on_launch = <true|false>"    - Indicates whether to respond to DNS queries for instance hostnames with DNS A records
           #  - "ipv6_native = <true|false>"                                    - Indicates whether to create an IPv6-only subnet
           #  - "map_public_ip_on_launch = <true|false>"                        - Specify true to indicate that instances launched into the subnet should be assigned a public IP address
           #  - "ipv6_cidr_block=<IPv6 CIDR block>"              - The IPv6 network range for the subnet, in CIDR notation. The subnet size must use a /64 prefix length.
           #  - "availability_zone=<AWS Availability zone>"      - AZ for the subnet
           options           = map(any)
           tags              = map(string)
         })
       )
     })
  )
}

variable "nacl_setup" {
  description = "Determine the Network Access Control List ingress (inbound) traffic rules"
  default = null

  type = list(
      object({
        nacl_name     = string

        #Set to use VPC created in this module.
        #Must set this value to use subnet names for nacl_subnets
        vpc = string

        #Can be set to subnet IDs or names used in this module
        subnets  = list(string)
        tags     = map(string)
        nacl_rules    = list(object({
          #Set's the traffic type
          #Set to null or "custom" to set protocol, to_port, and from_port yourself
          #Valid options include:
          #  - "all"                - All traffic to the destination (to_port,from_port=0, protocol="all")
          #  - "http"               - HTTP traffic to the destination (to_port,from_port=80, protocol="tcp")
          #  - "https"              - HTTPS traffic to the destination (to_port,from_port=443, protocol="tcp")
          #  - "ssh"                - SSH traffic to the destination (to_port,from_port=22, protocol="tcp")
          #  - "telnet"             - Telnet traffic to the destination (to_port,from_port=23, protocol="tcp")
          #  - "smtp"               - SMTP traffic to the destination (to_port,from_port=25, protocol="tcp")
          #  - "web site response"  - Traffc to ephemeral ports, usually a response to a web page(from_port=1024,to_port=65535,protocol="tcp")
          traffic_type        = string

          #Sets the priority of the rule
          rule_number     = number

          #Sets the IPv4 or IPv6 address of the external IP address we are recieving traffic from or directing traffic to
          #We use pattern matching on this value to determine which it is
          external_cidr_range = string

          #Sets optional settings for rules
          #Valid values include:
          #  - "deny_access"=<true|false> - set this rule to deny access
          #  - "is_ingress"=<true|false>  - set this rule to be an ingress. Otherwise, this will be an egress rule
          #  - "icmp_type"="<string>"   - sets the ICMP type if handling ICMP
          #  - "icmp_code"="<string>"   - sets the ICMP code if handling ICMP
          #  - "from_port"="<number>"   - sets the minimum port range for custom setup. Set to '0' for all. If not set, set equal to "to_port"
          #  - "to_port"="<number>"     - sets the max port port range for custom setup. Set to '0' for all. If not set, set equal to "to_port"
          #  - "protocol"="<string>"    - sets the protocol if we want to handle all that ourselves. Can set to 'all' for all protocols
          options         = map(string)
        })
      )
    })
  )
}

variable "nat_gateways" {
  description = "Creates NAT gateways in the VPC identified"
  default     = null

  type = list(
    object({
      name           = string
      
      #Sets optional values
      #Valid values include:
      #  - "make_elastic_ip"    - make a new elastic IP and attach to this NAT gateway
      #  - "is_public"          - makes this a public NAT Gateway. Otherwise this is private
      #  - "elastic_ip_id=<id>" - attached already created elastic IP to this NAT gateway
      #  - "vpc_name=<string>"  - allows us to pull the subnet value from the vpc module using the name of a VPC defined in the internal_network module
      #  - tags="<tag_name1>=<tag_value1>,<tag_name2>=<tag_value2>,..."
      options        = map(string)
   
      #Need both of these values set to use a subnet name set in this module
      #If not, assumes you are using the subnet name
      subnet = string
    })
  )
  
}

variable "vpc_peering" {
  description = "Sets up a VPC peering connection between two VPCs"
  default     = null

  type = list(
    object({
      #Name for the connection
      name          = string

      #Use the VPC name from this module or an external VPC ID
      requestor_vpc = string

      #Use the VPC name from this module or an external VPC ID
      peer_vpc      = string

      #Sets optional values
      #Valid values include:
      #  - "auto_accept" - Accept the peering (both VPCs need to be in the same AWS account and region).
      #  - "accepter_allow_remote_dns_resolution" - Allow a local VPC to resolve public DNS hostnames to private IP addresses when queried from instances in the peer VPC
      #  - "requester_allow_remote_dns_resolution" - Allow a local VPC to resolve public DNS hostnames to private IP addresses when queried from instances in the peer VPC
      #  - "peer_region""=<region>" - region of the accepter VPC of the VPC Peering Connection (auto_accept must be false)
      #  - "peer_owner_id"="<id>" - The AWS account ID of the owner of the peer VPC. Defaults to the account ID the AWS provider is currently connected to.
      #  - tags="<tag_name1>=<tag_value1>,<tag_name2>=<tag_value2>,..."
      options       = map(string)
    })
  )
}


#variable "vpc_peering" {
#  description = "Sets up a VPC peering connection between two VPCs"
#  default     = null
#
#  type = list(
#    object({
#      #Name for the connection
#      name                                  = string 
#       
#      #Use the VPC name from this module or an external VPC ID
#      requestor_vpc_name_or_id              = string
#
#      #Use the VPC name from this module or an external VPC ID
#      peer_vpc_name_or_id                   = string
#      peer_owner_id                         = string
#      auto_accept                           = bool
#      peer_region                           = string
#      accepter_allow_remote_dns_resolution  = bool
#      requester_allow_remote_dns_resolution = bool
#      tags                                  = map(string) 
#    })
#  )
#}

variable "vpc_endpoints" {
  description = "Sets up VPC endpoint"
  default     = null
  type = list(
    object({
      name         = string
 
      #Specify the AWS service this endpoint is for
      service_name = string

      #The VPC this is assigned to
      vpc          = string

      #Sets optional values
      #Valid values include:
      #  - "auto_accept" - Accept the VPC endpoint (the VPC endpoint and service need to be in the same AWS account).
      #  - "private_dns_enabled" -  (AWS services and AWS Marketplace partner services only) Whether or not to associate a private hosted zone with the specified VPC. Applicable for endpoints of type Interface.
      #  - "ip_address_type"="<ipv4|ipv6|dual stack>" - The IP address type for the endpoint. Valid values are ipv4, dualstack, and ipv6.
      #  - "security_groups"="<list of security groups>" - list of security groups to associate with this endpoint. Applicable for endpoints of type Interface. Can be security group defined here or external security group
      #  - "subnets"="<list of subnets>" - list of subnets this endpoint is for. Applicable for endpoints of type GatewayLoadBalancer and Interface. Can be for subnets defined here or externally
      #  - "route_tables"="<route table name or IDs>" - One or more route table names or IDs. Applicable for endpoints of type Gateway.
      #  - "vpc_endpoint_type"="<Gateway|Interface|GatewayLoadBalancer>" - The VPC endpoint type. Gateway, GatewayLoadBalancer, or Interface. Defaults to Gateway.
      #  - "dns_record_ip_type"="<ipv4|dualstack|service-defined|ipv6>"
      #  - "iam_policy"=<string> - either the name of the iam policy or the ID
      #  - "iam_policy_file"=<path> - read in a JSON file of an IAM policy
      #  - "tags" - tags for this VPC endpoint
      options      = map(string)

    })
  )
}

variable "transit_gateways" {
  description = "Defines Transit Gateway setup"
  default     = null

  type = list(
    object({
      name                                   = string

      #Sets optional values for transit gateway
      #  Valid values:
      #    - "amazon_side_asn=<number>"=<true|false>               - Set if you have a specific ASN you need to use.
      #    - "auto_accept_shared_attachments"=<true|false>         - Whether resource attachment requests are automatically accepted
      #    - "enable_default_route_table_association"=<true|false> - Whether resource attachments are automatically associated with the default association route table
      #    - "enable_default_route_table_propagation"=<true|false> - Whether resource attachments automatically propagate routes to the default propagation route table
      #    - "enable_dns_support"=<true|false>                     - Whether DNS support is enabled
      #    - "enable_vpn_ecmp_support"=<true|false>                - Whether VPN Equal Cost Multipath Protocol support is enabled
      #    - tags="<tag_name1>=<tag_value1>,<tag_name2>=<tag_value2>,..."
      options                                = map(string)
    })
  )
}

variable "transit_gateway_vpc_attachments" {
  description = "Establishes connection between transit gateway and a VPC. Must have this in place before adding transit gateway to route table"
  default     = null

  type = list(
    object({
      name                       = string
      #If entry matches a name in the "transit_gateways" variable, we use that ID
      #Otherwise we assume this is the ID of an external transit gateway
      transit_gateway            = string
      #If entry matches a name in the "vpc_setup" variable, we use that. Otherwise we expect this is a VPC IS
      vpc                        = string
      #If we can resolve a name in "vpc_setup" variable, we use that ID. Otherwise we expect this is a subnet ID
      subnets                    = list(string)

      #Sets optional values for transit gateway VPC attachment
      #  Valid values:
      #    - "enable_appliance_mode_support"=<true|false> - If enabled, a traffic flow between a source and destination uses the same Availability Zone for the VPC attachment for the lifetime of that flow
      #    - "disable_dns_support"=<true|false> - Whether DNS support is enabled
      #    - "enable_ipv6_support"=<true|false> - Whether IPv6 support is enabled
      #    - "enable_transit_gateway_default_route_table_association"=<true|false> - Boolean whether the VPC Attachment should be associated with the EC2 Transit Gateway association default route table. This cannot be configured or perform drift detection with Resource Access Manager shared EC2 Transit Gateways
      #    - "enable_transit_gateway_default_route_table_propagation"=<true|false> - Boolean whether the VPC Attachment should propagate routes with the EC2 Transit Gateway propagation default route table. This cannot be configured or perform drift detection with Resource Access Manager shared EC2 Transit Gateways
      #  - tags="<tag_name1>=<tag_value1>,<tag_name2>=<tag_value2>,..."
      options                    = map(string)
    })
  )
}

variable "route_tables" { 
  description = "Defines route tables andtheir rules"
  default     = null

  type = list(
      object({
        #Name of route table
        name    = string

        #Can be set to VPC name set in this module in vpc_setup variable or external VPC id
        vpc     = string

        #Sets optional values for route table
        #Valid values:
        # - propagating_vgws - A list of virtual gateways for propagation.
        # - tags="<tag_name1>=<tag_value1>,<tag_name2>=<tag_value2>,..."
        options = map(string)

#        routes           = list(
#          object({
#            #Can specify three kinds of targets
#            #  - IPv4 CIDR block            - an IP range in the ##.##.##.##/## format. Most common, identified by '.' in string
#            #  - IPv6 CIDR block            - an IP range in IPv6 style (####:####:####/##). Identified by the ':' in the string
#            #  - destination prefix list ID - An AWS managed prefix list ID. Identified by starting with 'pl-'
#            target = string
#      
#            #Sets options for this route
#            #MUST SET THE VALUE 'type' or this module will error
#            #Valid values for 'type':
#            #  - "internet gateway" - automatically resolves route to internet gateway attached to VPC
#            #  - "egress only internet gateway" - automatically resolves route to egress only internet gateway attached to VPC
#            #  - "vpn gateway" - automatically resolves route to  vpn gateway attached to VPC
#            #  - "nat gateway" - resolves route to nat gateway specified in "destination". Can use name in module or external id
#            #  - "vpc peering" - resolves route to vpc peering setup specified in "destination". Can use name in module or external id
#            #  - "vpc endpoint" - resolves route to vpc endpoint specified in "destination". Can use name in module or external id
#            #  - "transit gateway" - resolves route to transit gateway in "destination". Must attach transit gateway to VPC. Can use name in module or external id
#            #  - "carrier gateway" - resolves route to carrier gateway in "destination". Can only use ID
#            #  - "network interface" - resolves route to network interface in "destination". Can only use ID
#            #OTHER options:
#            #  - destination="<The name or ID of the destination object. Be careful to match to the type>"
#            route_options = map(string)
# 
#          }) 
#        )
      })
  )
}

variable "security_groups" {
  description = "Security groups high level setup"
  default = null

  type = list(
    object({
      #Must define the name, use this value for identification in configuration
      #This value will NOT be used to name security group if you set value for 'name_prefix'
      name                   = string
      vpc                    = string

      #Sets optional values. Expected values:
      #  - "name_prefix"="<string>" - Sets the name prefix. Otherwise, security group name is set using 'name' value
      #  - "description"="<string>" - optional description
      #  - "revoke_rules_on_delete"=<true|false> - Makes it so rules are revoked on deletion
      #  - tags="<tag_name1>=<tag_value1>,<tag_name2>=<tag_value2>,..."
      options                = map(string)

      #Sets the options for rules
      #  - "is_egress"=<true|false> - sets the rule to be egress. Is ingress by default
      #  - "description"="<string>" - optional description
      # The below settings need to be put in place to ensure the correct traffic type is specified
      # Specifying a "traffic_type" will resolve the protocol and port range (from_port,to_port)
      # Leave this undefined and specify the protocol and ports yourself if you have a custom setup in mind
      #  - "traffic_type"=<string> - sets the traffic to a set of predefined values.
      #  - "protocol"=<protocol name or number> - set to icmp, icmpv6, tcp, udp, all, or the protocol number
      #  - "port"=<port number> - sets the port number if we only want to use one. Will set from_port and to_port to be equal
      #  - "from_port"=<beginning of port range> - lower bound of port range. Will set to same as "to_port" if not set
      #  - "to_port"=<end of port range> - upper bound of port range. Will set to same as "from_port" if not set
      # Only use these values if you set the protocol to icmp or icmpv6. Otherwise these are ignore
      #  - "icmp_type"=<ICMP type number> - sets the icmp type if the protcol is set to icmp
      #  - "icmp_code"=<ICMP code> - sets the icmp code if the protcol is set to icmp
      # Settings for the external traffic this rule is allowing
      # NOTE: remember, security groups can only ALLOW traffic, they cannot deny it
      # "cidr_blocks","ipv6_cidr_blocks", and "prefix_list_ids" can all be used together
      #  - "cidr_blocks"=<comma separated list of IPv4 CIDR blocks>
      #  - "ipv6_cidr_blocks"=<comma separated list of IPv4 CIDR blocks>
      #  - "prefix_list_ids"=<comma separated list of prefix list ids>
      # WARNING: "security_groups" will cause "cidr_blocks","ipv6_cidr_blocks", and "prefix_list_ids" to be ignore.
      #  - "security_groups"=<comma separated values of security group names or IDs> - can use security group names from this module
      # WARNING:"self" can only be used alone. Setting this will ignore "security_groups", "cidr_blocks","ipv6_cidr_blocks", and "prefix_list_ids"
      #  - "self"=<true|false> - uses this security group as the entity allowed access
      rules                  = list(map(string))
    })
  )
}

