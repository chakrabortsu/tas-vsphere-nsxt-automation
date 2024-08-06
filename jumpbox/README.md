# Jumpbox
Automation to create a jumpbox or bastion host for TAS within the la environment

## Create Jumpbox
This script assumes you're running it from a Linux workstation. 
Before running the jumpbox configure or install script ensure
you have [govc], [ytt] installed and available on your PATH.

To create a jumpbox run the following commands, populate the `jumpbox.config` file with following details

```bash
# Required
slot_password='supersecret'
h2o_domain='h2o-11-255.h2o.vmware.com'
jumpbox_ip='10.220.41.199'
jumpbox_gateway='10.220.41.222'

# Optional - overrides defaults
jumpbox_netmask='255.255.255.224'
jumpbox_dns='10.220.136.2,10.220.136.3'
vm_name='jumpbox'
vm_network='user-workload'
root_disk_size='50G'
datastore='vsanDatastore'
ram='2048'
```

- `slot_password` is the global password for the H2O slot.
- `h2o_domain` is the domain suffix for the slot.
- `jumpbox_ip` is the IP address of the jumpbox.
- `jumpbox_netmask` is the network mask used by the jumpbox.
- `jumpbox_gateway` is the network gateway used by the jumpbox.
- `jumpbox_dns` is the comma delimited list of DNS servers used by the jumpbox.
- `vcenter_host` is the vCenter host name that is used by govc to spin up the jumpbox.
- `vm_name` is the VM name, by default jumpbox.
- `vm_network` is the network name the jumpbox is attached to, by default user-workload.
- `root_disk_size` is the size of the jumpbox HDD, by default 50G.
- `datastore` is the vCenter datastore name, by default vsanDatastore.
- `ram` is the amount of RAM to give the jumpbox, by default this is 8192 (8G).

After completing your edits, run the install script:
```sh
./install.sh
```

This will download the latest Ubuntu Focal OVA and spin up a jumpbox VM in
vSphere at the first IP in the user-workload provided vsphere network.

## SSH to Jumpbox

To SSH into the jumpbox use the key that the install script generated in the
`jumpbox/.ssh` directory. The jumpbox IP can be found in the `jumpbox.config`
file.

```bash
$ ssh -i .ssh/id_rsa ubuntu@yourjumpboxip
```

[govc]: https://github.com/vmware/govmomi/releases
[ytt]: https://github.com/vmware-tanzu/carvel-ytt/releases

