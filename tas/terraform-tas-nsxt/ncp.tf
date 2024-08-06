resource "nsxt_policy_ip_pool" "tas_orgs_external_snat_ip_pool" {
  display_name = "tas-orgs-external-snat-ip-pool"
  description  = "Subnets are allocated from this pool to each newly-created org"
  count        = var.use_ncp_container_networking ? 1 : 0
}

resource "nsxt_policy_ip_pool_static_subnet" "tas_orgs_external_snat_ip_pool" {
  display_name = "tas-orgs-external-ip-pool-static-subnet"
  description  = "Static pool of external SNAT IPs (1 IP for each CF org)"
  pool_path    = nsxt_policy_ip_pool.tas_orgs_external_snat_ip_pool[count.index].path
  cidr         = var.tas_ncp_external_snat_ip_pool_cidr
  count        = var.use_ncp_container_networking ? 1 : 0

  allocation_range {
    start = var.tas_orgs_external_snat_ip_pool_start
    end   = var.tas_orgs_external_snat_ip_pool_stop
  }
}

resource "nsxt_policy_ip_block" "container_ip_block" {
  description  = "Subnets are allocated from this pool for each CF org, and IPs from those subnets are used for app containers in the org"
  display_name = "tas-container-ip-block"
  cidr         = var.tas_container_ip_block_cidr
  count        = var.use_ncp_container_networking ? 1 : 0
}