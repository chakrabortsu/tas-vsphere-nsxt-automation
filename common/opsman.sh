#!/usr/bin/env bash
set -e
set -u
set -o pipefail

function tanzuNetFileVersion {
  local version="$1"

  # trim -rc.5 etc from the version number if it has one
  version="$(echo "$version" | sed 's/[+*/-].*$//')"
  echo "$version"
}

function findDownloadedOpsmanTile {
  local download_dir="$1"
  local product_prefix="$2"
  local version="$3"

  # Get the version number used in the file name
  file_version=$(tanzuNetFileVersion "$version")
  tile_name="${product_prefix}-${file_version}"

  # Find the downloaded tile
  tiles=("${download_dir}"/"${tile_name}"*.pivotal)
  [[ -e "${tiles[*]}" ]] && tile="${tiles=[0]}"

  if [ -z "${tile}" ]; then
    echo "could not find ${tile} in ${download_dir} folder"
    exit 1
  fi

  echo "$tile"
}

function remote::deployOpsman {
  remoteExec 'deployOpsman' "$@"
}

function deployOpsman {
  local vcenter_host="$1"
  local slot_password="$2"
  local opsman_version="$3"
  local vcenter_pool="$4"
  local opsman_network="$5"
  local opsman_vm_name="${6:-ops-manager}"
  local opsman_private_ip="${7:-192.168.1.3}"
  local opsman_gateway="${8:-192.168.1.1}"

  opsman_ovas=("${HOME}"/Downloads/ops-manager-vsphere-"${opsman_version}"*.ova)
  opsman_ova="${opsman_ovas=[0]}"

  # Deploy Opsman VM
  export \
    GOVC_URL="${vcenter_host}" \
    GOVC_INSECURE=1 \
    GOVC_USERNAME='administrator@vsphere.local' \
    GOVC_PASSWORD="${slot_password}"

  returnsSomething() {
    local bytes
    bytes="$( "$@" | wc -c )"

    [[ "$bytes" -ne 0 ]]
  }

  if returnsSomething govc pool.info "/vc01/host/vc01cl01/Resources/$vcenter_pool" ; then
    echo >&2 "Pool $vcenter_pool already exists, skipping creation"
  else
    govc pool.create "/vc01/host/vc01cl01/Resources/$vcenter_pool"
  fi

  if returnsSomething govc vm.info "$opsman_vm_name" ; then
    echo >&2 "Opsmanager VM already exists, skipping creation"
  else
    # generate the VApp properties file for the opsman OVA
    public_ssh_key=$(cat ~/.ssh/id_rsa.pub)
cat << EOF > /tmp/opsman.json
{
    "DiskProvisioning": "flat",
    "IPAllocationPolicy": "dhcpPolicy",
    "IPProtocol": "IPv4",
    "PropertyMapping": [
      {
        "Key": "ip0",
        "Value": "$opsman_private_ip"
      },
      {
        "Key": "netmask0",
        "Value": "255.255.255.0"
      },
      {
        "Key": "gateway",
        "Value": "$opsman_gateway"
      },
      {
        "Key": "DNS",
        "Value": "10.79.2.5,10.79.2.6"
      },
      {
        "Key": "ntp_servers",
        "Value": "time1.oc.vmware.com,time2.oc.vmware.com"
      },
      {
        "Key": "public_ssh_key",
        "Value": "$public_ssh_key"
      },
      {
        "Key": "custom_hostname",
        "Value": ""
      }
    ],
    "NetworkMapping": [
      {
        "Name": "Network 1",
        "Network": "$opsman_network"
      }
    ],
    "Annotation": "Tanzu Ops Manager installs and manages products and services.",
    "MarkAsTemplate": false,
    "PowerOn": false,
    "InjectOvfEnv": false,
    "WaitForIP": false,
    "Name": null
}
EOF
    govc import.ova -name "$opsman_vm_name" -pool "$vcenter_pool" --options /tmp/opsman.json "${opsman_ova}"
    govc vm.power -on "$opsman_vm_name"
    rm /tmp/opsman.json
  fi
}

function remote::configureAndDeployBOSH {
  local director_config="$5"
  scpFile "$director_config" /tmp/director.yml
  remoteExec 'configureAndDeployBOSH' "$@"
}

function configureAndDeployBOSH {
  local vcenter_host="$1"
  local nsxt_host="$2"
  local opsman_host="$3"
  local slot_password="$4"

  # wait until opsman is responding on port 443
  until nc -vzw5 "$opsman_host" 443; do sleep 5; done

  # Set om connection info
  export \
    OM_USERNAME='admin' \
    OM_PASSWORD="${slot_password}" \
    OM_DECRYPTION_PASSPHRASE="${slot_password}" \
    OM_SKIP_SSL_VALIDATION='true' \
    OM_TARGET="${opsman_host}"

  # Configure Opsman auth
  om -o 360 configure-authentication \
    --username admin \
    --password "${slot_password}" \
    --decryption-passphrase "${slot_password}"

  # Configure BOSH director
  openssl s_client -showcerts -connect "${nsxt_host}:443" < /dev/null 2> /dev/null | openssl x509 > /tmp/nsxt_host.pem
  om configure-director \
    --config /tmp/director.yml \
    --var "iaas-configurations_0_nsx_address=${nsxt_host}" \
    --var "iaas-configurations_0_nsx_ca_certificate=$(cat /tmp/nsxt_host.pem)" \
    --var "iaas-configurations_0_nsx_password='${slot_password}'" \
    --var "iaas-configurations_0_vcenter_host=${vcenter_host}" \
    --var "iaas-configurations_0_vcenter_password=${slot_password}"

  # Deploy only the BOSH director
  om apply-changes --skip-deploy-products
}

function createOpsmanDirEnv {
  cat << EOF > .envrc
#!/usr/bin/env bash

export OM_USERNAME='admin'
export OM_PASSWORD='${slot_password}'
export OM_DECRYPTION_PASSPHRASE='${slot_password}'
export OM_SKIP_SSL_VALIDATION='true'
export OM_TARGET="${opsman_host}"
export OM_CONNECT_TIMEOUT='30'

# Set the BOSH env vars from opsman
eval "\$(om bosh-env -i "../jumpbox/.ssh/id_rsa")"

export GOVC_URL="${vcenter_host}"
export GOVC_USERNAME='administrator@vsphere.local'
export GOVC_PASSWORD='${slot_password}'
export GOVC_INSECURE=true
EOF
}
