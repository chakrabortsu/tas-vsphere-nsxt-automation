#!/usr/bin/env bash

set -e
set -u
set -o pipefail

# shellcheck source=./common/h2o-cli.sh
source ../common/h2o-cli.sh

ex() {
  echo "$1='$2'" >> jumpbox.config
}

main() {
  local slot_id="$1"
  local res proj nets net mask gw h2o_domain

  res="$( getResource "$slot_id" )"
  proj="$( getProjectID <<< "$res" )"
  nets="$( getNetworks <<< "$res" )"
  h2o_domain="$( getDomain <<< "$res" )"

  read -r net mask gw <<< "$( getNetwork 'user-workload' <<< "$nets" )"

  : > jumpbox.config
  ex slot_id         "${slot_id}"
  ex slot_password   "$( getSlotPass "$slot_id" "$proj" <<< "$res" )"
  ex h2o_domain      "${h2o_domain}"
  ex jumpbox_ip      "$( incrementIP "$net" 4 )"
  ex jumpbox_netmask "${mask}"
  ex jumpbox_gateway "${gw}"
  ex jumpbox_dns     "$( getDNSServers <<< "$res" )"
  ex vcenter_host    "vc01.${h2o_domain}"
  ex vm_name         'jumpbox'
  ex vm_network      'user-workload'
  ex root_disk_size  '50G'
  ex datastore       'vsanDatastore'
  ex ram             '8192'
}

main "$@"
