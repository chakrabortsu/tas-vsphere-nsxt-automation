#!/usr/bin/env bash

set -e
set -u
set -o pipefail

# shellcheck source=common/local.sh
source ../common/local.sh

# shellcheck source=common/install.sh
source ../common/install.sh

# shellcheck source=common/opsman.sh
source ../common/opsman.sh

# shellcheck source=common/dns.sh
#source ../common/dns.sh

# shellcheck source=tas/tas.sh
source ./tas.sh

loadJumpboxConfig
loadConfig "tas.config"

# Prereqs from jumpbox.config
: "${slot_id?Must provide a slot_id env var}"
: "${jumpbox_ip?Must provide a jumpbox_ip env var}"
: "${slot_password?Must provide a slot_password env var}"
: "${h2o_domain?Must provide a h2o_domain env var}"

# Prereqs from tas.config
: "${tanzu_net_api_token?Must provide a tanzu_net_api_token env var}"
: "${tas_infrastructure_nat_gateway_ip?Must provide a tas_infrastructure_nat_gateway_ip env var}"
: "${tas_deployment_nat_gateway_ip?Must provide a tas_deployment_nat_gateway_ip env var}"
: "${tas_services_nat_gateway_ip?Must provide a tas_services_nat_gateway_ip env var}"
: "${tas_ops_manager_public_ip?Must provide a tas_ops_manager_public_ip env var}"
: "${tas_lb_web_virtual_server_ip_address?Must provide a tas_lb_web_virtual_server_ip_address env var}"
: "${tas_lb_tcp_virtual_server_ip_address?Must provide a tas_lb_tcp_virtual_server_ip_address env var}"
: "${tas_lb_ssh_virtual_server_ip_address?Must provide a tas_lb_ssh_virtual_server_ip_address env var}"

# Defaults
: "${vcenter_host:=vc01.${h2o_domain}}"
: "${nsxt_host:=nsxt01a.${h2o_domain}}"
: "${opsman_host:=opsman.${h2o_domain}}"
: "${apps_domain:=apps.${h2o_domain}}"
: "${sys_domain:=sys.${h2o_domain}}"
: "${install_full_tas:=false}"
: "${install_tasw:=false}"
: "${xenial_stemcell_version:=621.897}"
: "${jammy_stemcell_version:=1.406}"
: "${windows_stemcell_version:=2019.71}"
: "${opsman_version:=3.0.25+LTS-T}"
: "${tas_version:=4.0.20+LTS-T}"

# Pick a linux stemcell based off TAS version
linux_stemcell_name='jammy'
linux_stemcell_version="$jammy_stemcell_version"
if [[ "$tas_version" =~ ^2\.11.* ]] || [[ "$tas_version" =~ ^2.12.* ]] || [[ "$tas_version" =~ ^2.13.* ]]; then
  linux_stemcell_name='xenial'
  linux_stemcell_version="$xenial_stemcell_version"
fi

#declare -A hosts
# shellcheck disable=SC2034 #indirect reference
#hosts=(["*.apps"]="$tas_lb_web_virtual_server_ip_address" \
#  ["*.sys"]="$tas_lb_web_virtual_server_ip_address" \
#  ["tcp.apps"]="$tas_lb_tcp_virtual_server_ip_address" \
#  ["ssh.sys"]="$tas_lb_ssh_virtual_server_ip_address" \
#  ["opsman"]="$tas_ops_manager_public_ip")
#addDNSEntries "$slot_id" "$slot_password" "$h2o_domain" hosts

addHostToSSHConfig 'opsman' "$opsman_host" 'ubuntu'
createOpsmanDirEnv

remote::installTASTools
remote::paveNSXT \
  "$nsxt_host" \
  "'$slot_password'" \
  "$tas_ops_manager_public_ip" \
  "$tas_lb_web_virtual_server_ip_address" \
  "$tas_lb_tcp_virtual_server_ip_address" \
  "$tas_lb_ssh_virtual_server_ip_address" \
  "$tas_infrastructure_nat_gateway_ip" \
  "$tas_deployment_nat_gateway_ip" \
  "$tas_services_nat_gateway_ip"
remote::downloadTanzuNetPackages \
  "$tanzu_net_api_token" \
  "$opsman_version" \
  "$tas_version" \
  "$linux_stemcell_name" \
  "$linux_stemcell_version" \
  "$windows_stemcell_version" \
  "$install_full_tas" \
  "$install_tasw"
remote::deployOpsman \
  "$vcenter_host" \
  "$slot_password" \
  "$opsman_version" \
  'tas1' \
  'tas-infra-segment'
remote::configureAndDeployBOSH \
  "$vcenter_host" \
  "$nsxt_host" \
  "$opsman_host" \
  "'$slot_password'" \
  "./director.yml"
remote::configureAndDeployTAS \
  "$opsman_host" \
  "'$slot_password'" \
  "$sys_domain" \
  "$apps_domain" \
  "$tas_version" \
  "$linux_stemcell_name" \
  "$linux_stemcell_version" \
  "$install_full_tas" \
  "$install_tasw"

addCFLoginToDirEnv "$sys_domain"

echo
echo "SSH to ${opsman_host}:"
echo "  ssh -F ../jumpbox/.ssh/config opsman"
echo
echo "List BOSH VMs:"
echo "  bosh vms"
echo 
echo "List Operations Manager tiles"
echo "  om products"
echo
