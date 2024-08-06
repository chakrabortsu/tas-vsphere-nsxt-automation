#!/usr/bin/env bash
set -e
set -u
set -o pipefail

function installOm {
  echo "Installing om"
  if [ ! -f /usr/local/bin/om ]; then
    wget -q https://github.com/pivotal-cf/om/releases/download/7.12.0/om-linux-amd64-7.12.0
    sudo install om-linux-amd64-7.12.0 /usr/local/bin/om
    rm -f om-linux-amd64-7.12.0
  fi
}

function installJq {
  echo "Installing jq"
  if [ ! -f /usr/local/bin/jq ]; then
    wget -q https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
    sudo install jq-linux64 /usr/local/bin/jq
    rm -f jq-linux64
  fi
}

function installTerraform {
  echo "Installing terraform"
  if [ ! -f /usr/local/bin/terraform ]; then
      wget -q https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
      unzip terraform_1.5.0_linux_amd64.zip
      sudo install terraform /usr/local/bin/terraform
      rm -f terraform_1.5.0_linux_amd64.zip
      rm -f terraform
  fi
}

function installVcc {
  echo "Installing vcc"
  if [ ! -f /usr/local/bin/vcc ]; then
      wget -q https://github.com/vmware-labs/vmware-customer-connect-cli/releases/download/v1.1.2/vcc-linux-v1.1.2
      sudo install vcc-linux-v1.1.2 /usr/local/bin/vcc
      rm -f vcc-linux-v1.1.2
  fi
}

function installGovc {
  echo "Installing govc"
  if [ ! -f /usr/local/bin/govc ]; then
      wget -q https://github.com/vmware/govmomi/releases/download/v0.27.5/govc_Linux_x86_64.tar.gz
      tar -xf govc_Linux_x86_64.tar.gz
      sudo install govc /usr/local/bin/govc
      rm -f govc_Linux_x86_64.tar.gz
      rm -f govc
      rm -f CHANGELOG.md
      rm -f LICENSE.txt
      rm -f README.md
  fi
}

function installYtt {
  echo "Installing ytt"
  if [ ! -f /usr/local/bin/ytt ]; then
      wget -q https://github.com/vmware-tanzu/carvel-ytt/releases/download/v0.41.1/ytt-linux-amd64
      sudo install ytt-linux-amd64 /usr/local/bin/ytt 
      rm -f ytt-linux-amd64
  fi
}

function installDocker {
  echo "Installing docker"
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo apt-get -qq update
  sudo apt-get -qq install -y ca-certificates curl gnupg lsb-release jq docker-ce docker-ce-cli containerd.io docker-compose-plugin
  sudo usermod -aG docker ubuntu
}

function installKind {
  echo "Installing kind"
  if [ ! -f /usr/local/bin/kind ]; then
      wget -q https://kind.sigs.k8s.io/dl/v0.14.0/kind-linux-amd64
      sudo install kind-linux-amd64 /usr/local/bin/kind
      rm -f kind-linux-amd64
  fi
}

function installBosh {
  echo "Installing bosh"
  if [ ! -f /usr/local/bin/bosh ]; then
      wget -q https://github.com/cloudfoundry/bosh-cli/releases/download/v7.5.5/bosh-cli-7.5.5-linux-amd64
      sudo install bosh-cli-7.5.5-linux-amd64 /usr/local/bin/bosh
      rm -f bosh-cli-7.5.5-linux-amd64
  fi
}

function installZip {
    # Required for surgery on .pivotal files
    echo "Installing zip"
    if [ ! -f /usr/bin/zip ]; then
        sudo apt-get -qq update
        sudo apt-get -qq install -y zip
    fi
}
