data "nsxt_policy_transport_zone" "overlay_tz" {
  display_name = var.east_west_transport_zone_name
}

data "nsxt_policy_edge_cluster" "ec" {
  display_name = var.nsxt_edge_cluster_name
}

data "nsxt_policy_tier0_gateway" "nsxt_active_t0_gateway" {
  display_name = var.nsxt_active_t0_gateway_name
}

# NOTE: the NSX-T provider does not current support creating LB monitors
# with the policy API, so these must be created manually ahead of time.

data "nsxt_policy_lb_monitor" "tas-web-monitor" {
  type         = "HTTP"
  display_name = "tas-web-monitor"
  description  = "Monitor for web (HTTPS) traffic to gorouters" 
}

data "nsxt_policy_lb_monitor" "tas-tcp-monitor" {
  type         = "HTTP"
  display_name = "tas-tcp-monitor"
  description  = "Monitor for TCP traffic to TCP routers" 
}

data "nsxt_policy_lb_monitor" "tas-ssh-monitor" {
  type         = "TCP"
  display_name = "tas-ssh-monitor"
  description  = "Monitor for SSH traffic to diego brains"
}

data "nsxt_policy_lb_app_profile" "tas_lb_tcp_application_profile" {
  type         = "TCP"
  display_name = "tas_lb_tcp_application_profile"
}
