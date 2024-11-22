#!/bin/bash

set -euo pipefail

branch="main"
diff_check=false

# Function to display usage
usage() {
  echo "Usage: $0 --version <version> [--branch <branch>] [--no-diff-check]"
  exit 1
}

# Parse options
while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--version) version="$2"; shift 2 ;;
    -b|--branch) branch="$2"; shift 2 ;;
    -n|--no-diff-check) diff_check=false; shift ;;
    --) shift; break ;;
    -*|--*) echo "Unknown option $1"; usage ;;
    *) break ;;
  esac
done

# Check if version argument is provided
if [ -z "${version:-}" ]; then
  echo "Error: You must provide a version number."
  usage
fi

# Ensure there are no unstaged changes
if [ "$diff_check" = true ] && ! git diff --quiet origin/"$branch"; then
  echo "Error: This branch has differences compared to origin/$branch. Please push or undo these changes before continuing."
  echo "You can bypass this check with the --no-diff-check flag."
  exit 1
fi

# This timestamp is used during branch creation.
# It's helpful in cases where the script fails and a new branch needs to
# be created on a subsequent attempt.
timestamp=$(date +"%Y-%m-%d-%H_%M_%S") 

git checkout "$branch"
git pull

# Create a new branch with the version and timestamp
branch_name="$(whoami)/release-$version-$timestamp"
git checkout -b "$branch_name"

# Define the git repo root
repo_root=$(git rev-parse --show-toplevel)

# Extract the previous version number from version.rb
previous_version=$(grep 'BLUEPRINT_VERSION' "$repo_root/version.rb" | awk -F"'" '{print $2}')

# Update the library version in version.rb
sed -i '' "s/BLUEPRINT_VERSION ||= .*/BLUEPRINT_VERSION ||= '$version'/" "$repo_root/version.rb"

# Update CHANGELOG.md using stamp-changelog.sh
"$repo_root/Scripts/stamp-changelog.sh" --version "$version" --previous-version "$previous_version"

# Change directory into the SampleApp dir and update Podfile.lock using a subshell
(
  cd "$repo_root/SampleApp"
  bundle exec pod install
)

# Commit the changes
git add .
git commit -m "Bumping versions to $version."

# Push the branch and open a PR into main
git push origin "$branch_name"

pr_body=$(cat <<-END
https://github.com/square/Blueprint/blob/main/CHANGELOG.md

Post-merge steps:

- Once the PR is merged, fetch changes and tag the release, using the merge commit:
  \`\`\`
  git fetch
  git tag $version <merge commit SHA>
  git push origin $version
  \`\`\`

- Publish to CocoaPods:
  \`\`\`
  bundle exec pod trunk push BlueprintUI.podspec
  bundle exec pod trunk push --synchronous BlueprintUICommonControls.podspec
  \`\`\`
END
)

gh pr create --draft --title "release: Blueprint $version" --body "$pr_body"

gh pr view --web

echo "Branch $branch_name created and pushed. A draft PR has been created."
