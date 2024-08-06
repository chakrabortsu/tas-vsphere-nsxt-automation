#!/usr/bin/env bash

set -e
set -u
set -o pipefail

# shellcheck source=common/local.sh
source ../common/local.sh

# shellcheck source=common/opsman.sh
source ../common/opsman.sh

loadJumpboxConfig
loadConfig "tas.config"

# Prereqs from jumpbox.config
: "${slot_id?Must provide a slot_id env var}"
: "${jumpbox_ip?Must provide a jumpbox_ip env var}"
: "${slot_password?Must provide a slot_password env var}"
: "${h2o_domain?Must provide a h2o_domain env var}"

# Prereqs from tas.config
: "${tanzu_net_api_token?Must provide a tanzu_net_api_token env var}"

# Defaults
: "${opsman_host:=opsman.${h2o_domain}}"
: "${install_scs:=true}"
: "${install_mysql:=true}"
: "${scs_version:=3.2.4}"
: "${mysql_version:=3.2.1}"


function remote::downloadTanzuNetServicePackages {
  remoteExec 'downloadTanzuNetServicePackages' "$@"
}

function downloadTanzuNetServicePackages {
  local tanzu_net_api_token="$1"
  local install_scs="$2"
  local scs_version="$3"
  local install_mysql="$4"
  local mysql_version="$5"

  mkdir -p ~/Downloads

  # Download service tiles
  if $install_scs; then
    om download-product -p p-spring-cloud-services \
      -t "$tanzu_net_api_token" \
      -f 'p_spring-cloud-services-*.pivotal' \
      --product-version "$scs_version" \
      -o ~/Downloads
  fi

  if $install_mysql; then
    om download-product -p pivotal-mysql \
      -t "$tanzu_net_api_token" \
      -f 'pivotal-mysql-*.pivotal' \
      --product-version "$mysql_version" \
      -o ~/Downloads
  fi
}

function remote::configureAndDeployServices {
  scpFile ./services/mysql.yml /tmp/mysql.yml
  scpFile ./services/scs.yml /tmp/scs.yml
  remoteExec 'configureAndDeployServices' "$@"
}

function configureAndDeployServices {
  local opsman_host="$1"
  local slot_password="$2"
  local install_scs="$3"
  local scs_version="$4"
  local install_mysql="$5"
  local mysql_version="$6"
  
  # Set om connection info
  export \
    OM_USERNAME='admin' \
    OM_PASSWORD="${slot_password}" \
    OM_DECRYPTION_PASSPHRASE="${slot_password}" \
    OM_SKIP_SSL_VALIDATION='true' \
    OM_TARGET="${opsman_host}"

  if $install_scs; then
    # get the path to the downloaded SCS tile
    scs_tile=$(findDownloadedOpsmanTile "${HOME}/Downloads" 'p_spring-cloud-services' "$scs_version")

    # upload and stage SCS tile
    om upload-product -p "$scs_tile"
    scs_tile_version=$(om products -a -f json | jq -r '.[] | select(.name == "p_spring-cloud-services") | .available | .[]')
    om stage-product --product-name=p_spring-cloud-services --product-version="$scs_tile_version"

    # configure and deploy SCS
    om configure-product --config /tmp/scs.yml
    om apply-changes --product-name=p_spring-cloud-services
  fi

  if $install_mysql; then
    # get the path to the downloaded MySQL tile
    mysql_tile=$(findDownloadedOpsmanTile "${HOME}/Downloads" 'pivotal-mysql' "$mysql_version")

    # upload and stage MySQL tile
    om upload-product -p "$mysql_tile"
    mysql_tile_version=$(om products -a -f json | jq -r '.[] | select(.name == "pivotal-mysql") | .available | .[]')
    om stage-product --product-name=pivotal-mysql --product-version="$mysql_tile_version"

    # configure and deploy MySQL
    om configure-product --config /tmp/mysql.yml
    om apply-changes --product-name=pivotal-mysql
  fi
}

remote::downloadTanzuNetServicePackages \
  "$tanzu_net_api_token" \
  "$install_scs" \
  "$scs_version" \
  "$install_mysql" \
  "$mysql_version"
remote::configureAndDeployServices \
  "$opsman_host" \
  "$slot_password" \
  "$install_scs" \
  "$scs_version" \
  "$install_mysql" \
  "$mysql_version"
