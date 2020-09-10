#!/bin/bash

set -euxo pipefail

# Find the sourcekitten binary embedded in jazzy
sourcekitten=`gem contents jazzy | grep 'bin/sourcekitten$' | head -1`

platform="iOS Simulator"
device=`instruments -s -devices | grep -oE 'iPhone.*?[^\(]+' | head -1 | awk '{$1=$1;print}'`
destination="platform=$platform,name=$device"

$sourcekitten doc \
  --module-name BlueprintUI \
  -- \
  -scheme "BlueprintUI-Package" -destination "$destination" \
  > BlueprintUI.json

$sourcekitten doc \
  --module-name BlueprintUICommonControls \
  -- \
  -scheme "BlueprintUI-Package" -destination "$destination" \
  > BlueprintUICommonControls.json

jazzy --sourcekitten-sourcefile BlueprintUI.json,BlueprintUICommonControls.json
