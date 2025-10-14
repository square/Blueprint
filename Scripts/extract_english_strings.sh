#!/usr/bin/env bash

# Generate a Localizable.strings file from the LocalizedStrings.swift file in BlueprintUICommonControls
# Usage: extract_english_strings

set -euo pipefail

# We want this to be runnable from Xcode or the root of the repo,
# so we cd to the script dir is and use paths relative to that.
cd "$(dirname "${BASH_SOURCE[0]}")"

genstrings -o ../BlueprintUIAccessibilityCore/Resources/en.lproj \
../BlueprintUIAccessibilityCore/Sources/LocalizedStrings.swift \


# Note: When invoking genstrings with new arguments, please ensure that the expected keys
# show up in Atlas after the changes have landed in main. https://block.atlassian.net/browse/UI-5655

# genstrings encodes its file in UTF-16, but UTF-8 is also supported and will show in diffs,
# so we'll convert the file to UTF-8
iconv -f UTF-16 -t UTF-8 ../BlueprintUIAccessibilityCore/Resources/en.lproj/Localizable.strings > temp && mv temp ../BlueprintUIAccessibilityCore/Resources/en.lproj/Localizable.strings
