#!/usr/bin/env bash

setup() {
  load '../test/test_helper/bats-support/load'
  load '../test/test_helper/bats-assert/load'

  # get the containing directory of this file
  DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
  BATS_SUITE_TEMP_DIR="$BATS_TMPDIR/tas"
  mkdir -p "$BATS_SUITE_TEMP_DIR"

  # shellcheck source=./tas/tas.sh
  source "$DIR/tas.sh"
}

teardown() {
  rm -rf "$BATS_SUITE_TEMP_DIR"
}

@test "can find product config file" {
  echo ' ' > "$BATS_SUITE_TEMP_DIR/cf-2.11.yml"
  echo ' ' > "$BATS_SUITE_TEMP_DIR/srt-2.11.yml"
  echo ' ' > "$BATS_SUITE_TEMP_DIR/cf-4.0.yml"
  echo ' ' > "$BATS_SUITE_TEMP_DIR/srt-4.0.yml"

  config_file=$(findTASProductConfigFile "$BATS_SUITE_TEMP_DIR" '4.0.6+LTS-T' true)
  assert_equal "$config_file" "$BATS_SUITE_TEMP_DIR/cf-4.0.yml"
  config_file=$(findTASProductConfigFile "$BATS_SUITE_TEMP_DIR" '4.0.6+LTS-T' false)
  assert_equal "$config_file" "$BATS_SUITE_TEMP_DIR/srt-4.0.yml"
  config_file=$(findTASProductConfigFile "$BATS_SUITE_TEMP_DIR" '2.11.59' true)
  assert_equal "$config_file" "$BATS_SUITE_TEMP_DIR/cf-2.11.yml"
}
