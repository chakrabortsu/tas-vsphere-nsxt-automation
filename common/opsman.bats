#!/usr/bin/env bash

setup() {
  load '../test/test_helper/bats-support/load'
  load '../test/test_helper/bats-assert/load'

  # get the containing directory of this file
  DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
  BATS_SUITE_TEMP_DIR="$BATS_TMPDIR/common"
  mkdir -p "$BATS_SUITE_TEMP_DIR"

  # shellcheck source=./common/opsman.sh
  source "$DIR/opsman.sh"
}

teardown() {
  rm -rf "$BATS_SUITE_TEMP_DIR"
}

@test "can turn pivnet versions into file name versions" {
  declare -A versions
  versions=(["5.0.0-build.7"]="5.0.0" \
    ["5.0.0-rc.2"]="5.0.0" \
    ["4.0.6-build.2+LTS-T"]="4.0.6" \
    ["2.11.43"]="2.11.43" \
    ["2.13.13-build.2"]="2.13.13" \
    ["4.0.5+LTS-T"]="4.0.5")

  for pivnet_version in "${!versions[@]}"; do
    file_version="${versions[$pivnet_version]}"

    ver=$(tanzuNetFileVersion "$pivnet_version")
    assert_equal "$ver" "$file_version"
  done
}

@test "can find downloaded small TAS tile" {
  # create a few files to sort through, last one is correct
  echo ' ' > "$BATS_SUITE_TEMP_DIR/cf-4.0.6-build.2.pivotal"
  echo ' ' > "$BATS_SUITE_TEMP_DIR/srt-4.0.5-build.2.pivotal"
  echo ' ' > "$BATS_SUITE_TEMP_DIR/srt-4.0.6-build.2.pivotal"

  opsman_tile=$(findDownloadedOpsmanTile "$BATS_SUITE_TEMP_DIR" 'srt' '4.0.6+LTS-T')
  assert_equal "$opsman_tile" "$BATS_SUITE_TEMP_DIR/srt-4.0.6-build.2.pivotal"
}

@test "can find downloaded tiles" {
  # create a few files to sort through in the Downloads dir
  echo ' ' > "$BATS_SUITE_TEMP_DIR/cf-4.0.6-build.2.pivotal"
  echo ' ' > "$BATS_SUITE_TEMP_DIR/srt-4.0.5-build.2.pivotal"
  echo ' ' > "$BATS_SUITE_TEMP_DIR/srt-4.0.6-build.2.pivotal"
  echo ' ' > "$BATS_SUITE_TEMP_DIR/pivotal-mysql-3.2.1.pivotal"
  echo ' ' > "$BATS_SUITE_TEMP_DIR/p_spring-cloud-services-3.2.4.pivotal"

  opsman_tile=$(findDownloadedOpsmanTile "$BATS_SUITE_TEMP_DIR" 'srt' '4.0.6+LTS-T')
  assert_equal "$opsman_tile" "$BATS_SUITE_TEMP_DIR/srt-4.0.6-build.2.pivotal"

  mysql_tile=$(findDownloadedOpsmanTile "$BATS_SUITE_TEMP_DIR" 'pivotal-mysql' '3.2.1')
  assert_equal "$mysql_tile" "$BATS_SUITE_TEMP_DIR/pivotal-mysql-3.2.1.pivotal"
}
