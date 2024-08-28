Terraform scripts to prepare NSXT with vSphere for TAS deployment


Creating Profiles & Monitors to be executed first before running terraform apply

curl -k -v -u "${TF_VAR_nsxt_username}:${TF_VAR_nsxt_password}" \
    -X PATCH \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -d @profiles_and_monitors.json \
    "https://${TF_VAR_nsxt_host}/policy/api/v1/infra/"



