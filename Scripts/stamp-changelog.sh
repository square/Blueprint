#!/bin/bash

# Function to display usage
usage() {
  echo "Usage: $0 -v <version> -p <previous-version>"
  echo "  -v, --version           Version number (required)"
  echo "  -p, --previous-version  Previous version number (required)"
  echo "  -d, --release-date      The date of the release (optional). Defaults to: date +%Y-%m-%d"
  exit 1
}

# Parse options
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -v|--version) version="$2"; shift 2 ;;
        -p|--previous-version) previous_version="$2"; shift 2 ;;
        -d|--release-date) release_date="$2"; shift 2 ;;
        --) shift; break ;;
        -*|--*) echo "Unknown option $1"; usage ;;
        *) break ;;
  esac
done

# Check if both version and previous_version arguments are provided
if [ -z "$version" ] || [ -z "$previous_version" ]; then
  echo "Error: You must provide both version and previous version numbers."
  usage
fi

if [ -z "$release_date" ]; then
    release_date=$(date +%Y-%m-%d)
fi

repo_root=$(git rev-parse --show-toplevel)
changelog_file="$repo_root/CHANGELOG.md"

changelog=$(ruby <<EOF
changelog_contents = File.read('$changelog_file')
changelog_contents.gsub!(/(###.*\n\n)+#/, '#')
puts changelog_contents
EOF
)

# Define the changelog template
unreleased_changelog_template="## [Main]\n\
\n\
### Fixed\n\
\n\
### Added\n\
\n\
### Removed\n\
\n\
### Changed\n\
\n\
### Deprecated\n\
\n\
### Security\n\
\n\
### Documentation\n\
\n\
### Misc\n\
\n\
### Internal\n\
\n\
## [$version] - $release_date"

# Replace the Main section with the new template
changelog=$(echo "$changelog" | sed "s/^## \[Main\]/$unreleased_changelog_template/")

# Replace the line starting with "[main]: " to the new URL
changelog=$(echo "$changelog" | sed "s|^\[main\]: .*|\[main\]: https://github.com/square/Blueprint/compare/$version...HEAD|")

# Append the new version comparison link at the end of the file
changelog="$changelog"$'\n'"[$version]: https://github.com/square/Blueprint/compare/$previous_version...$version"

# Write the updated contents back to the changelog file
echo "$changelog" > "$changelog_file"

echo "CHANGELOG.md updated for version $version."