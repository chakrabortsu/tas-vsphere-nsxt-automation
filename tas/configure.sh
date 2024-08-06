#!/usr/bin/env bash

set -e
set -u
set -o pipefail

# shellcheck source=common/local.sh
source ../common/local.sh

# shellcheck source=./common/h2o-cli.sh
source ../common/h2o-cli.sh

loadJumpboxConfig

# Prereqs from jumpbox.config
: "${slot_id?Must provide a slot_id env var}"

ex() {
  echo "$1='$2'" >> tas.config
}

main() {
  local tanzu_net_api_token="$1"
  local res proj nets ingress_net egress_net h2o_domain

  res="$( getResource "$slot_id" )"
  proj="$( getProjectID <<< "$res" )"
  nets="$( getNetworks <<< "$res" )"
  h2o_domain="$( getDomain <<< "$res" )"

  read -r ingress_net _ _ <<< "$( getNetwork 'nsxt-ingress' <<< "$nets" )"
  read -r egress_net _ _ <<< "$( getNetwork 'nsxt-egress' <<< "$nets" )"

  : > tas.config
  ex tanzu_net_api_token                  "${tanzu_net_api_token}"
  ex tas_infrastructure_nat_gateway_ip    "$( incrementIP "$egress_net" 1 )"
  ex tas_deployment_nat_gateway_ip        "$( incrementIP "$egress_net" 2 )"
  ex tas_services_nat_gateway_ip          "$( incrementIP "$egress_net" 3 )"
  ex tas_ops_manager_public_ip            "$( incrementIP "$ingress_net" 1 )"
  ex tas_lb_web_virtual_server_ip_address "$( incrementIP "$ingress_net" 2 )"
  ex tas_lb_tcp_virtual_server_ip_address "$( incrementIP "$ingress_net" 3 )"
  ex tas_lb_ssh_virtual_server_ip_address "$( incrementIP "$ingress_net" 4 )"
  ex vcenter_host                         "vc01.${h2o_domain}"
  ex nsxt_host                            "nsxt01a.${h2o_domain}"
  ex opsman_host                          "opsman.${h2o_domain}"
  ex apps_domain                          "apps.${h2o_domain}"
  ex sys_domain                           "sys.${h2o_domain}"
  ex install_full_tas                     false
  ex install_tasw                         false
  ex xenial_stemcell_version              '621.897'
  ex jammy_stemcell_version               '1.445'
  ex windows_stemcell_version             '2019.72'
  ex opsman_version                       '3.0.27+LTS-T'
  ex tas_version                          '6.0.3+LTS-T'
}

main "$@"
