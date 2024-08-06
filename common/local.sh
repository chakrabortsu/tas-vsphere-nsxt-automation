#!/usr/bin/env bash
set -e
set -u
set -o pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
H2O_HELPER_DIR="$(dirname "$SCRIPT_DIR")"
export H2O_HELPER_DIR

function validateJumpboxKeyExists {
  if [ ! -f "$H2O_HELPER_DIR/jumpbox/.ssh/id_rsa.pub" ]; then 
    echo "Ensure you have installed the jumphost prior to running"
    exit 1
  fi
}

function addHostToSSHConfig {
  local alias="$1"
  local host="$2"
  local user="$3"

  if ! grep -q "$host" "$H2O_HELPER_DIR/jumpbox/.ssh/config" 2> /dev/null; then
    cat >> "$H2O_HELPER_DIR/jumpbox/.ssh/config" <<EOF
Host ${alias}
  Hostname ${host}
  User ${user}
  IdentityFile ${H2O_HELPER_DIR}/jumpbox/.ssh/id_rsa
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  LogLevel ERROR
EOF
  fi
}

function scpFile {
  srcFile="$1"
  destFile="$2"

  validateJumpboxKeyExists
  scp -F "$H2O_HELPER_DIR/jumpbox/.ssh/config" "$srcFile" "jumpbox:$destFile"
}

function scpDir {
  srcDir="$1"
  destDir="$2"

  validateJumpboxKeyExists
  scp -rp -F "$H2O_HELPER_DIR/jumpbox/.ssh/config" "$srcDir" "jumpbox:$destDir"
}

function remoteExec {
  validateJumpboxKeyExists
  ssh jumpbox -F "$H2O_HELPER_DIR/jumpbox/.ssh/config" "$(typeset -f); $*"
}

function loadConfig {
  local config="$1"
  if [ -f "$config" ]; then
    # shellcheck disable=SC1090
    source "$config"
  fi
}

function loadJumpboxConfig {
  loadConfig "$H2O_HELPER_DIR/jumpbox/jumpbox.config"
}

function checkBashVersion5(){
  if ((BASH_VERSINFO[0] < 5))
  then
    echo "BASH 5.0+ is required to run this script."
    echo "Please upgrade your version of BASH via Homebrew/package manager"
    exit 1
  fi
}

function checkLocalPrereqs() {
  checkBashVersion5

  if ! [ -x "$(command -v ytt)" ]; then
    echo 'ytt must be installed in your PATH' 1>&2
    exit 1
  fi

  if ! [ -x "$(command -v govc)" ]; then
    echo 'govc must be installed in your PATH' 1>&2
    exit 1
  fi
}

function netmaskToCidrBits () {
  local netmask="$1"
  local bits=0
  for octet in $(echo "$netmask" | tr '.' "\n"); do
    binbits=$(echo "obase=2; ibase=10; ${octet}"| bc | sed 's/0//g') 
    ((bits+=${#binbits}))
  done
  echo "${bits}"
}
