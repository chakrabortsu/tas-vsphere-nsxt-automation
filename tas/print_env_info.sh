#!/usr/bin/env bash

# Check if the .envrc file exists
if [[ ! -f .envrc ]]; then
    echo "Error: .envrc file not found."
    exit 1
fi

# Function to source the .envrc file without executing commands
source_env_vars() {
    while IFS= read -r line; do
        if [[ $line =~ ^export ]]; then
            eval "$line"
        fi
    done < .envrc
}

# Call the function to source the environment variables
source_env_vars

# Construct the Apps Manager URL by replacing 'opsman' with 'apps.sys' in the OM_TARGET
apps_manager_url="${OM_TARGET//opsman/apps.sys}"

# Obtain the password for the Apps Manager site
appsmanpw=$(om credentials -p cf -c '.uaa.admin_credentials' -t json | jq -r .password)

# Print the Ops Manager URL, username, and password
echo "==========================="
echo "       Ops Manager"
echo "==========================="
echo "URL      : https://$OM_TARGET"
echo "Username : $OM_USERNAME"
echo "Password : $GOVC_PASSWORD"

echo ""

# Print the Apps Manager URL and password
echo "==========================="
echo "     Apps Manager"
echo "==========================="
echo "URL      : https://$apps_manager_url"
echo "Username : admin"
echo "Password : $appsmanpw"
echo "==========================="

