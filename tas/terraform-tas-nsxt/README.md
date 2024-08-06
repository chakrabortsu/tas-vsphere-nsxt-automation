# terraform-tas-nsxt

[Terraform](https://www.terraform.io) templates for provisioning NSX-T objects
in preparation for installing Tanzu Application Service (TAS). This approach
automates the setup described in the
[installation docs](https://docs.vmware.com/en/VMware-Tanzu-Application-Service/5.0/tas-for-vms/vsphere-nsx-t.html).

These templates leverage VMware's
[NSX-T provider](https://registry.terraform.io/providers/vmware/nsxt/latest/docs)
and prefer to use the newer Policy API over the older Manager API.

## Prerequisites

These templates assume a base level of NSX-T setup already exists, including:

- the edge cluster
- the overlay transport zone
- the T0 gateway

## Getting Started

### Populate Variables

Start to enter your configuration variables. Use the `terraform.tfvars.example`
file as your starting point by copying it to `terraform.tfvars` and editing it.

For the NSX-T coordinates it's easiest to set them in your environment, so that

- they can be reused for the "Create the required LB Objects" step
- you don't store creds in the tfvars file and commit thos by accident

```bash
# the leading space is intentional, depending on the setup of your shell it
# might exclude those commands from your shell's history
 export TF_VAR_nsxt_host='...'
 export TF_VAR_nsxt_username='...'
 export TF_VAR_nsxt_password='...'
```

### Create the required LB Objects

At the time of this writing (May 2022), the NSX-T provider does not support
creating all necessary LB objects with the NSX-T policy API. Until this support
is added, it is necessary to create these objects out of band prior to running
terraform.

```bash
curl -v -u "${TF_VAR_nsxt_username}:${TF_VAR_nsxt_password}" \
    -X PATCH \
    -H 'Content-Type: application-json' \
    -d @profiles_and_monitors.json \
    "https://${TF_VAR_nsxt_host}/policy/api/v1/infra/"
```

This will create:

- LB Application Profile `tas_lb_tcp_application_profile`
- LB Monitors:
  - HTTP monitor `tas-web-monitor`
  - HTTP monitor `tas-tcp-monitor`
  - TCP monitor `tas-ssh-monitor`

### Run Terraform

```bash
$ terraform init
$ terraform fmt && terraform validate
$ terraform plan
$ terraform apply
```
