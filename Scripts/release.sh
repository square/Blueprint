#!/usr/bin/env bash

set -euo pipefail

target="origin/main"
draft=true
open_release=true
dry_run=false
fail_on_no_commits=true
prerelease=false
notes_start_tag=""

usage() {
  cat <<'END'
Usage: Scripts/release.sh --version <version> [options]

Creates a GitHub release with auto-generated release notes.

Options:
  -v, --version <version>          Version tag to release, for example 6.8.0.
  -t, --target <ref-or-sha>        Git ref or commit SHA to release. Defaults to origin/main.
      --notes-start-tag <tag>      Tag to start generated release notes from.
      --publish                    Publish immediately instead of creating a draft.
      --draft                      Create a draft release. This is the default.
      --prerelease                 Mark the release as a prerelease.
      --allow-no-commits           Allow a release with no commits since the previous release.
      --no-open                    Do not open the release in a browser.
      --dry-run                    Print the gh command without creating the release.
  -h, --help                       Show this help text.
END
}

require_value() {
  if [[ $# -lt 2 || -z "${2:-}" ]]; then
    echo "Error: $1 requires a value." >&2
    usage
    exit 1
  fi

  if [[ "${2:0:1}" == "-" ]]; then
    echo "Error: $1 requires a value." >&2
    usage
    exit 1
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -v|--version)
      require_value "$@"
      version="${2:-}"
      shift 2
      ;;
    -t|--target)
      require_value "$@"
      target="${2:-}"
      shift 2
      ;;
    --notes-start-tag)
      require_value "$@"
      notes_start_tag="${2:-}"
      shift 2
      ;;
    --publish)
      draft=false
      shift
      ;;
    --draft)
      draft=true
      shift
      ;;
    --prerelease)
      prerelease=true
      shift
      ;;
    --allow-no-commits)
      fail_on_no_commits=false
      shift
      ;;
    --no-open)
      open_release=false
      shift
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*|--*)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
    *)
      echo "Unexpected argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "${version:-}" ]]; then
  echo "Error: You must provide a version number." >&2
  usage
  exit 1
fi

if [[ -z "$target" ]]; then
  echo "Error: --target cannot be empty." >&2
  exit 1
fi

if ! command -v gh > /dev/null; then
  echo "Error: GitHub CLI (gh) is required. Install it from https://cli.github.com/ and authenticate before retrying." >&2
  exit 1
fi

if ! gh auth status > /dev/null 2>&1; then
  echo "Error: GitHub CLI (gh) is not authenticated. Run 'gh auth login' before retrying." >&2
  exit 1
fi

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

if [[ "$dry_run" == false ]] && { ! git diff --quiet || ! git diff --cached --quiet; }; then
  echo "Error: The working tree has uncommitted changes. Commit or stash them before cutting a release." >&2
  exit 1
fi

git fetch origin --tags

target_sha=$(git rev-parse --verify "$target^{commit}")
existing_tag_sha=$(git rev-parse --verify --quiet "refs/tags/$version^{commit}" || true)

if [[ -n "$existing_tag_sha" && "$existing_tag_sha" != "$target_sha" ]]; then
  echo "Error: Tag $version already exists at $existing_tag_sha, not $target_sha." >&2
  echo "Choose a different version, delete or move the tag if it is wrong, or pass --target $existing_tag_sha." >&2
  exit 1
fi

if gh release view "$version" > /dev/null 2>&1; then
  echo "Error: A GitHub release already exists for $version." >&2
  exit 1
fi

release_command=(
  gh release create "$version"
  --target "$target_sha"
  --title "$version"
  --generate-notes
)

if [[ "$draft" == true ]]; then
  release_command+=(--draft)
fi

if [[ "$prerelease" == true ]]; then
  release_command+=(--prerelease)
fi

if [[ "$fail_on_no_commits" == true ]]; then
  release_command+=(--fail-on-no-commits)
fi

if [[ -n "$notes_start_tag" ]]; then
  release_command+=(--notes-start-tag "$notes_start_tag")
fi

release_kind=""
if [[ "$draft" == true ]]; then
  release_kind="draft "
fi

printf 'Creating %srelease %s from %s (%s).\n' "$release_kind" "$version" "$target" "$target_sha"

if [[ "$dry_run" == true ]]; then
  printf 'Dry run:'
  printf ' %q' "${release_command[@]}"
  printf '\n'
  exit 0
fi

"${release_command[@]}"

if [[ "$open_release" == true ]]; then
  gh release view "$version" --web
fi

echo "Release $version created. Review the generated notes in GitHub before publishing if this is a draft."
