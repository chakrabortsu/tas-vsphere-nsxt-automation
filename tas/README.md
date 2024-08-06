# Tanzu Application Service
Automation to install TAS on a vSphere NSX-T deployment type

Ensure you have an already provisioned [jumpbox](../jumpbox/README.md) and
you've cloned this repository and all of it's submodules via
`git clone --recurse-submodules` before continuing.

## Install TAS
Create a `tas.config` file as below making sure to
supply your [Tanzu Network API token](https://tanzu.vmware.com/developer/guides/tanzu-network-gs/#creating-an-api-token-for-your-user-account)

Sample tas.config file looks as below
```sh
tanzu_net_api_token='blahblah-r'
tas_infrastructure_nat_gateway_ip='10.220.16.209'
tas_deployment_nat_gateway_ip='10.220.16.210'
tas_services_nat_gateway_ip='10.220.16.211'
tas_ops_manager_public_ip='10.220.15.97'
tas_lb_web_virtual_server_ip_address='10.220.15.98'
tas_lb_tcp_virtual_server_ip_address='10.220.15.99'
tas_lb_ssh_virtual_server_ip_address='10.220.15.100'
vcenter_host='vc01.h2o-2-18562.h2o.vmware.com'
nsxt_host='nsxt01a.h2o-2-18562.h2o.vmware.com'
opsman_host='opsman.h2o-2-18562.h2o.vmware.com'
apps_domain='apps.h2o-2-18562.h2o.vmware.com'
sys_domain='sys.h2o-2-18562.h2o.vmware.com'
install_full_tas='false'
install_tasw='false'
tasw_stemcell_version='2019.72'
jammy_stemcell_version='1.445'
opsman_version='3.0.27+LTS-T'
tas_version='6.0.3+LTS-T'
```

- `tas_infrastructure_nat_gateway_ip` is the SNAT IP for all VMs on the private infrastructure network,
by default Operations Manager and the BOSH director (nsxt-egress).
- `tas_deployment_nat_gateway_ip` is the SNAT IP for all TAS VMs, so things like Diego cells, GoRouters,
Cloud Controller etc (nsxt-egress).
- `tas_services_nat_gateway_ip` is the SNAT IP for all optional service tile VMs, for example the MySQL tile (nsxt-egress).
- `tas_ops_manager_public_ip` is the DNAT IP address for Operations Manager that is reachable from
the VMware network. This is the IP address your `opsman` DNS entry should point to (nsxt-ingress).
- `tas_lb_web_virtual_server_ip_address` is the DNAT IP address for the NSX-T ingress load balancer that
sits in from of the TAS GoRouters. This is how the Cloud Controller and application's running on TAS are accessed.
This is the IP address that your `*.apps` and `*.sys` DNS entries should point to (nsxt-ingress).
- `tas_lb_tcp_virtual_server_ip_address` is the DNAT IP address if you're using TCP routing in TAS (nsxt-ingress).
- `tas_lb_ssh_virtual_server_ip_address` is the DNAT IP address when using `cf ssh` to SSH into running app instances (nsxt-ingress).
- `opsman_version` - the version of Operations Manager to deploy
- `tas_version` - the TAS version to deploy, versions 2.11.x through 4.0.x are supported.
- `install_full_tas` - when true the full (large) version of TAS is deployed, otherwise the TAS small footprint version.
- `install_tasw` - when true TASW is deployed with the Windows stack.

After completing the edits, run the following script

```sh
./install.sh
```

This will use the already provisioned jumpbox to run most of the heavy lifting
like downloading and uploading the Operations Manager OVA and TAS tile.

Once installation is complete the script generates an `.envrc` file for this
environment in the current `tas` directory. If you have [direnv] installed
you can execute `direnv allow` which will setup the environment connection
variables for `om`, `bosh`, etc.

## Install Optional Marketplace Services
After the TAS installation finishes, you can install Spring Cloud Services (SCS)
and MySQL for TAS:
```sh
./install-services.sh
```
You can optionally disable installing either by adding the following to your
tas.config: `install_scs=false` or `install_mysql=false`. By default both
MySQL and SCS will be installed.

[direnv]: https://direnv.net/
