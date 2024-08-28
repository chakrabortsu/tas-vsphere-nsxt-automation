resource "nsxt_policy_tier1_gateway" "tas-deployment-t1-gw" {
  description               = "Tier-1 Gateway for TAS Deployment Network"
  display_name              = "tas-deployment-t1"
  edge_cluster_path         = data.nsxt_policy_edge_cluster.ec.path
  tier0_path                = data.nsxt_policy_tier0_gateway.nsxt_active_t0_gateway.path
  route_advertisement_types = ["TIER1_STATIC_ROUTES", "TIER1_CONNECTED", "TIER1_NAT", "TIER1_LB_VIP", "TIER1_LB_SNAT"]
  pool_allocation           = "ROUTING"
}

resource "nsxt_policy_segment" "tas-deployment-segment" {
  description         = "TAS Deployment Network Segment"
  display_name        = "tas-deployment-segment"
  connectivity_path   = nsxt_policy_tier1_gateway.tas-deployment-t1-gw.path
  transport_zone_path = data.nsxt_policy_transport_zone.overlay_tz.path

  subnet {
    # this turns "192.168.3.0/24" to "192.168.3.1/24" (uses the first host in the CIDR)
    cidr = join("/", tolist([cidrhost(var.tas_deployment_cidr, 1), split("/", var.tas_deployment_cidr)[1]]))
  }
}

resource "nsxt_policy_nat_rule" "tas-deployment-snat" {
  display_name        = "tas-deployment-snat"
  description         = "SNAT rule for all VMs in the TAS deployment network"
  action              = "SNAT"
  gateway_path        = nsxt_policy_tier1_gateway.tas-deployment-t1-gw.path
  logging             = false
  source_networks     = [var.tas_deployment_cidr]
  translated_networks = [var.tas_deployment_nat_gateway_ip]
  rule_priority       = 1000
}
