resource "nsxt_policy_lb_service" "tas-lb-service" {
    display_name      = "tas-lb-service"
    description       = "TAS Load Balancing Service"
    connectivity_path = nsxt_policy_tier1_gateway.tas-deployment-t1-gw.path
    size              = "SMALL"
    enabled           = true
    error_log_level   = "ERROR"
}

resource "nsxt_policy_lb_pool" "tas-web-pool" {
    display_name        = "tas-web-pool"
    description         = "The server pool for web (HTTPS) traffic into TAS"
    algorithm           = "ROUND_ROBIN"
    active_monitor_path = data.nsxt_policy_lb_monitor.tas-web-monitor.path

    lifecycle {
        ignore_changes = [member]
    }

    snat {
        type = "IPPOOL"
        ip_pool_addresses = [var.tas_lb_web_virtual_server_ip_address]
    }
}

resource "nsxt_policy_lb_pool" "tas-tcp-pool" {
    display_name        = "tas-tcp-pool"
    description         = "The server pool for TCP traffic into TAS (when using TCP routers)"
    algorithm           = "ROUND_ROBIN"
    active_monitor_path = data.nsxt_policy_lb_monitor.tas-tcp-monitor.path

    lifecycle {
        ignore_changes = [member]
    }

    snat {
        type = "IPPOOL"
        ip_pool_addresses = [var.tas_lb_tcp_virtual_server_ip_address]
    }
}

resource "nsxt_policy_lb_pool" "tas-ssh-pool" {
    display_name        = "tas-ssh-pool"
    description         = "The server pool for SSH traffic into TAS diego brains"
    algorithm           = "ROUND_ROBIN"
    active_monitor_path = data.nsxt_policy_lb_monitor.tas-ssh-monitor.path

    lifecycle {
        ignore_changes = [member]
    }

    snat {
        type = "IPPOOL"
        ip_pool_addresses = [var.tas_lb_ssh_virtual_server_ip_address]
    }
}

resource "nsxt_policy_lb_virtual_server" "tas-web-virtualserver" {
  display_name              = "tas-web-virtualserver"
  description               = "The Virtual Server for TAS web traffic"
  enabled                   = true
  access_log_enabled        = true
  application_profile_path  = data.nsxt_policy_lb_app_profile.tas_lb_tcp_application_profile.path
  ip_address                = var.tas_lb_web_virtual_server_ip_address
  ports                     = ["443"]
  default_pool_member_ports = ["443"]
  service_path              = nsxt_policy_lb_service.tas-lb-service.path
  pool_path                 = nsxt_policy_lb_pool.tas-web-pool.path
}

resource "nsxt_policy_lb_virtual_server" "tas-tcp-virtualserver" {
  display_name              = "tas-tcp-virtualserver"
  description               = "The Virtual Server for TAS TCP traffic"
  enabled                   = true
  access_log_enabled        = true
  application_profile_path  = data.nsxt_policy_lb_app_profile.tas_lb_tcp_application_profile.path
  ip_address                = var.tas_lb_tcp_virtual_server_ip_address
  ports                     = var.tas_lb_tcp_virtual_server_ports
  default_pool_member_ports = var.tas_lb_tcp_virtual_server_ports
  service_path              = nsxt_policy_lb_service.tas-lb-service.path
  pool_path                 = nsxt_policy_lb_pool.tas-tcp-pool.path
}

resource "nsxt_policy_lb_virtual_server" "tas-ssh-virtualserver" {
  display_name              = "tas-ssh-virtualserver"
  description               = "The Virtual Server for TAS SSH traffic"
  access_log_enabled        = true
  enabled                   = true
  application_profile_path  = data.nsxt_policy_lb_app_profile.tas_lb_tcp_application_profile.path
  ip_address                = var.tas_lb_ssh_virtual_server_ip_address
  ports                     = ["2222"]
  default_pool_member_ports = ["2222"]
  service_path              = nsxt_policy_lb_service.tas-lb-service.path
  pool_path                 = nsxt_policy_lb_pool.tas-ssh-pool.path
}