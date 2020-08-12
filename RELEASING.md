# Releasing a new version

1. You must be listed as an owner of the pods `BlueprintUI` and `BlueprintUICommonControls`.

   To check this run:

   ```bash
   bundle exec pod trunk info BlueprintUI
   bundle exec pod trunk info BlueprintUICommonControls
   ```

   See [the CocoaPods documentation for pod trunk](https://guides.cocoapods.org/making/getting-setup-with-trunk) for more information about setting up credentials on your device. If you need to be added as an owner, ping in #blueprint on Slack (Square only).

1. Make sure you're on the `main` branch, and `git pull` to get the latest commits.

1. Create a branch off `main` to update the version numbers and `Podfile.lock`. An example name would be `your-username/release-0.1.0`.

1. Update the library version in both `BlueprintUI.podspec` and `BlueprintUICommonControls.podspec` if it has not already been updated (it should match the version number that you are about to release).

1. Update `CHANGELOG.md` (in the root of the repo), moving current changes under `Main` to a new section under `Past Releases` for the version you are releasing.
  
   The changelog uses [reference links](https://daringfireball.net/projects/markdown/syntax#link) to link each version's changes. Remember to add a link to the new version at the bottom of the file, and to update the link to `[main]`.

1. Change directory into the `SampleApp` dir: `cd SampleApp`.

1. Run `bundle exec pod install` to update the `Podfile.lock` with the new versions.

1. Change back to the root directory (`cd ..`) to commit the podspec version bumps and the `Podfile.lock` update.
   ```bash
   git commit -am "Bumping versions to 0.1.0."
   ```

1. Push your branch and open a PR into `main`.

1. Once the PR is merged, fetch changes and tag the release, using the merge commit:
   ```bash
   git fetch
   git tag 0.1.0 <merge commit SHA>
   git push origin 0.1.0
   ```

1. Publish to CocoaPods

   Note: You may also need to quit Xcode before running these commands in order for the linting builds to succeed.

   ```bash
   bundle exec pod trunk push BlueprintUI.podspec
   # The --synchronous argument ensures this command builds against the
   # version of BlueprintUI that we just published.
   bundle exec pod trunk push --synchronous BlueprintUICommonControls.podspec
   ```
