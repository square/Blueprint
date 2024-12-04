# Releasing a new version

1. Prepare a release by updating the changelog.

1. Make sure you're on the `main` branch, and `git pull` to get the latest commits.

1. Create a branch off `main`.

1. Update `CHANGELOG.md` (in the root of the repo), moving current changes under `Main` to a new section for the version you are releasing.
  
   The changelog uses [reference links](https://daringfireball.net/projects/markdown/syntax#link) to link each version's changes. Remember to add a link to the new version at the bottom of the file, and to update the link to `[main]`.

1. Push your branch and open a PR into `main`.

1. Go to the [Releases](https://github.com/square/Blueprint/releases) and `Draft a new release`.

1. `Choose a tag` and create a tag for the new version.

1. In the release notes, copy the changes from the changelog.

1. Ensure the `Title` corresponds to the version we're publishing.

1. Hit `Publish release`.
