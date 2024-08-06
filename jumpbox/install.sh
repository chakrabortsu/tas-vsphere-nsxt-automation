#!/usr/bin/env bash

set -e
set -u
set -o pipefail

# shellcheck source=common/local.sh
source ../common/local.sh

loadJumpboxConfig

# Prereqs
: "${slot_password?Must provide a slot_password env var}"
: "${h2o_domain?Must provide a h2o_domain env var}"
: "${jumpbox_ip?Must provide a jumpbox_ip env var}"
: "${jumpbox_gateway?Must provide a jumpbox_gateway env var}"

# Defaults
: "${jumpbox_netmask:=255.255.255.224}"
: "${vcenter_host:=vc01.${h2o_domain}}"
: "${jumpbox_dns:=10.220.136.2,10.220.136.3}"
: "${vm_name:=jumpbox}"
: "${vm_network:=user-workload}"
: "${root_disk_size:=50G}"
: "${datastore:=vsanDatastore}"
: "${ram:=8192}"

function createSSHKey() {
  if [ -f ./.ssh/id_rsa ]; then
    echo >&2 "SSH key already exists, skipping creation" 
  else
    # Generate SSH key for the jumpbox
    mkdir -p ./.ssh
    < /dev/zero ssh-keygen -b 2048 -t rsa -m PEM -f ./.ssh/id_rsa -q -N ''
  fi
}

function createJumpboxVM() {
  local slot_password="$1"
  local vcenter_host="$2"
  local vm_name="$3"
  local network="$4"
  local datastore="$5"
  local disk_size="$6"
  local ram="$7"
  local ip="$8"
  local netmask="$9"
  local gateway="${10}"
  local dns="${11}"

  returnsSomething() {
    local bytes
    bytes="$( "$@" | wc -c )"

    [[ "$bytes" -ne 0 ]]
  }

  # setup govc creds
  export \
    GOVC_INSECURE=1 \
    GOVC_USERNAME='administrator@vsphere.local' \
    GOVC_PASSWORD="${slot_password}" \
    GOVC_URL="${vcenter_host}"

  if returnsSomething govc vm.info "${vm_name}" ; then
    echo >&2 "${vm_name} VM already exists, skipping creation"
  else
    # create the cloud-init config for the OVA
    user_data="$(
      ytt --ignore-unknown-comments -f user-data.yml \
      -v public_ssh_key="$(cat .ssh/id_rsa.pub)" \
      -v slot_password="${slot_password}"
    )"

    # create the VM
    govc import.ova \
      -ds "${datastore}" \
      -name "${vm_name}" \
      -options=<(ytt -o json -f jumpbox.yml -v user_data="${user_data}" -v name="$vm_name" -v network="$network")  \
      https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.ova

    # Update ram
    govc vm.change \
      -vm "${vm_name}" \
      -m "${ram}"

    # resize the root disk
    govc vm.disk.change -vm "${vm_name}" -disk.label "Hard disk 1" -size "${disk_size}"

    # set vm ip
    govc vm.customize \
      -vm "${vm_name}" \
      -ip "${ip}" \
      -netmask "${netmask}" \
      -dns-server "${dns}" \
      -gateway "${gateway}"

    # power on VM
    govc vm.power \
      -on "${vm_name}"
  fi
}

function waitForSSHToRespond() {
  local jumpbox_ip="$1"

  # wait until jumpbox is responding on port 22
  until nc -vzw5 "$jumpbox_ip" 22; do sleep 5; done

  # give the VM a chance to finish initializing
  sleep 30
}

function copySSHKeysToJumpbox() {
  echo "Copying SSH keys to ${vm_name}"
  scpFile ./.ssh/id_rsa /home/ubuntu/.ssh/id_rsa
  scpFile ./.ssh/id_rsa.pub /home/ubuntu/.ssh/id_rsa.pub
}

function main() {
  checkLocalPrereqs
  createSSHKey
  createJumpboxVM \
    "$slot_password" \
    "$vcenter_host" \
    "$vm_name" \
    "$vm_network" \
    "$datastore" \
    "$root_disk_size" \
    "$ram" \
    "$jumpbox_ip" \
    "$jumpbox_netmask" \
    "$jumpbox_gateway" \
    "$jumpbox_dns"
  waitForSSHToRespond "$jumpbox_ip"
  addHostToSSHConfig "${vm_name}" "$jumpbox_ip" 'ubuntu'
  copySSHKeysToJumpbox

  echo
  echo "SSH into ${vm_name}:"
  echo " ssh -F .ssh/config ${vm_name}"
  echo
}

main
