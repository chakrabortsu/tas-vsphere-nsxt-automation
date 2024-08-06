resource "nsxt_policy_tier1_gateway" "tas-infra-t1-gw" {
  description               = "Tier-1 Gateway for TAS Infrastructure Network"
  display_name              = "tas-infra-t1"
  edge_cluster_path         = data.nsxt_policy_edge_cluster.ec.path
  tier0_path                = data.nsxt_policy_tier0_gateway.nsxt_active_t0_gateway.path
  route_advertisement_types = ["TIER1_STATIC_ROUTES", "TIER1_CONNECTED", "TIER1_NAT", "TIER1_LB_VIP", "TIER1_LB_SNAT"]
  pool_allocation           = "ROUTING"
}

resource "nsxt_policy_segment" "tas-infra-segment" {
  display_name        = "tas-infra-segment"
  description         = "TAS Infrastructure Network Segment"
  connectivity_path   = nsxt_policy_tier1_gateway.tas-infra-t1-gw.path
  transport_zone_path = data.nsxt_policy_transport_zone.overlay_tz.path

  subnet {
    # this turns "192.168.3.0/24" to "192.168.3.1/24" (uses the first host in the CIDR)
    cidr = join("/", tolist([cidrhost(var.tas_infra_cidr, 1), split("/", var.tas_infra_cidr)[1]]))
  }
}

resource "nsxt_policy_nat_rule" "ops-manager-snat" {
  display_name        = "ops-manager-snat"
  description         = "SNAT rule for Operations Manager egress"
  action              = "SNAT"
  source_networks     = ["${var.tas_ops_manager_private_ip}"]
  translated_networks = [var.tas_ops_manager_public_ip]
  gateway_path        = nsxt_policy_tier1_gateway.tas-infra-t1-gw.path
  logging             = false
}

resource "nsxt_policy_nat_rule" "ops-manager-dnat" {
  display_name         = "ops-manager-dnat"
  description          = "DNAT rule for Operations Manager ingress"
  action               = "DNAT"
  translated_networks  = ["${var.tas_ops_manager_private_ip}"]
  destination_networks = [var.tas_ops_manager_public_ip]
  gateway_path         = nsxt_policy_tier1_gateway.tas-infra-t1-gw.path
  logging              = false
}

resource "nsxt_policy_nat_rule" "tas-infra-snat" {
  display_name        = "tas-infra-snat"
  description         = "SNAT rule for all VMs in the TAS infrastructure network"
  action              = "SNAT"
  gateway_path        = nsxt_policy_tier1_gateway.tas-infra-t1-gw.path
  logging             = false
  source_networks     = [var.tas_infra_cidr]
  translated_networks = [var.tas_infrastructure_nat_gateway_ip]
  rule_priority       = 1000
}
