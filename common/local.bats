#!/usr/bin/env bash

setup() {
  load '../test/test_helper/bats-support/load'
  load '../test/test_helper/bats-assert/load'

  # get the containing directory of this file
  DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"

  # shellcheck source=./common/local.sh
  source "$DIR/local.sh"
}

@test "can calc CIDR bits from subnet mask" {
  declare -A masks
  masks=(["255.255.255.224"]="27" \
    ["255.255.255.240"]="28" \
    ["255.255.255.0"]="24")

  for mask in "${!masks[@]}"; do
    bits="${masks[$mask]}"

    b=$(netmaskToCidrBits "$mask")
    assert_equal "$b" "$bits"
  done
}
