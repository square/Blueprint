#!/bin/bash

set -euxo pipefail

# Find the sourcekitten binary embedded in jazzy
sourcekitten=`gem contents jazzy | grep 'bin/sourcekitten$' | head -1`

platform="iOS Simulator"
device=`xcrun xctrace list devices 2>&1 | grep -oE 'iPhone.*?[^\(]+' | sed 's/Simulator//' | head -1 | awk '{$1=$1;print}'`
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
