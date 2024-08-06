#!/usr/bin/env bash

set -e
set -u
set -o pipefail

# shellcheck source=common/local.sh
source ../common/local.sh

loadJumpboxConfig

# Prereqs
: "${slot_password?Must provide a slot_password env var}"

# Defaults
: "${vcenter_host:=vc01.${h2o_domain}}"
: "${vm_name:=jumpbox}"

# Setup govc creds n' stuff
export \
  GOVC_INSECURE=1 \
  GOVC_USERNAME='administrator@vsphere.local' \
  GOVC_PASSWORD="${slot_password}" \
  GOVC_URL="${vcenter_host}"

# Ensure govc is installed
checkLocalPrereqs

# delete VM and disks
govc vm.destroy \
  "${vm_name}" \
