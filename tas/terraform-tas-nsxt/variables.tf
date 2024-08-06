variable "nsxt_host" {
  description = "The NSX-T Manager host. Must resolve to a reachable IP address, e.g. `nsxmgr.example.tld`"
  type        = string
}

variable "nsxt_username" {
  description = "The NSX-T username, probably `admin`"
  type        = string
}

variable "nsxt_password" {
  description = "The NSX-T password"
  type        = string
  sensitive   = true
}

variable "allow_unverified_ssl" {
  description = "Allow connection to NSX-T manager with self-signed certificates. Set to `true` for POC or development environments"
  default     = false
  type        = bool
}

variable "nsxt_edge_cluster_name" {
  default     = "edge-cluster-1"
  description = "The name of the edge cluster where the T1 gateways will be provisioned"
  type        = string
}

variable "nsxt_active_t0_gateway_name" {
  description = "The name of the T0 gateway where the T1s will be connected to"
  type        = string
}


variable "east_west_transport_zone_name" {
  description = "The name of the Transport Zone that carries internal traffic between the NSX-T components. Also known as the `overlay` transport zone"
  type        = string
}

variable "tas_infra_cidr" {
  description = "CIDR for the TAS infrastructure segment"
  type        = string
  default     = "192.168.1.0/24"
}

variable "tas_deployment_cidr" {
  description = "CIDR for the TAS deployment segment"
  type        = string
  default     = "192.168.2.0/24"
}

variable "tas_services_cidr" {
  description = "CIDR for the TAS services segment"
  type        = string
  default     = "192.168.3.0/24"
}

variable "tas_infrastructure_nat_gateway_ip" {
  description = "The source IP address to use for all traffic leaving the TAS infrastructure network"
  type        = string
}

variable "tas_deployment_nat_gateway_ip" {
  description = "The source IP address to use for all traffic leaving the TAS deployment network"
  type        = string
}

variable "tas_services_nat_gateway_ip" {
  description = "The source IP address to use for all traffic leaving the TAS services network"
  type        = string
}

variable "tas_ops_manager_public_ip" {
  description = "The public IP address to use for Operations Manager"
  type        = string
}

variable "tas_ops_manager_private_ip" {
  description = "The private (NAT) IP address to use for Operations Manager. Must be in the tas_infrastructure_cidr range"
  type        = string
}

variable "tas_lb_web_virtual_server_ip_address" {
    description = "The IP address on which the web virtual server listens for HTTPS traffic"
    type        = string
}

variable "tas_lb_tcp_virtual_server_ip_address" {
    description = "The IP address on which the TCP virtual server listens for TCP traffic"
    type        = string
}

variable "tas_lb_tcp_virtual_server_ports" {
  description = "The list of port(s) on which the Virtual Server listens for TCP traffic, e.g. `[\"8080\", \"52135\", \"34000-35000\"]`"
  type        = list(string)
}

variable "tas_lb_ssh_virtual_server_ip_address" {
    description = "The IP address on which the SSH virtual server listens for SSH traffic"
    type        = string
}

variable "use_ncp_container_networking" {
    description = "Set to true if you plan to use the Network Container Plugin (NCP) for TAS container networking."
    type        = bool
    default     = true
}

variable "tas_ncp_external_snat_ip_pool_cidr" {
    description = "CIDR range for the IP pool that provides 1 public IP for each CF org"
    type        = string
}

variable "tas_orgs_external_snat_ip_pool_start" {
    description = "Starting IP for allocating SNAT IPs from the TAS external SNAT IP pool"
    type        = string
}

variable "tas_orgs_external_snat_ip_pool_stop" {
    description = "Ending IP for allocating SNAT IPs from the TAS external SNAT IP pool"
    type        = string
}

variable "tas_container_ip_block_cidr" {
    description = "IP block for CF orgs. Subnets will be carved from this block for each org."
    type        = string
}