# Releasing a new version

1. You must be listed as an owner of the pods `BlueprintUI` and `BlueprintUICommonControls`.

To check this run:

```bash
bundle exec pod trunk info BlueprintUI
bundle exec pod trunk info BlueprintUICommonControls
```

See [the CocoaPods documentation for pod trunk](https://guides.cocoapods.org/making/getting-setup-with-trunk) for more information about setting up credentials on your device. If you need to be added as an owner, ping in #blueprint on Slack (Square only).

1. Make sure you're on the `master` branch, and `git pull` to get the latest commits.

1. Create a branch off `master` to update the version numbers and `Podfile.lock`. An example name would be `your-username/release-0.1.0`.

1. Update the library version in both `BlueprintUI.podspec` and `BlueprintUICommonControls.podspec` if it has not already been updated (it should match the version number that you are about to release).

1. Change directory into the `SampleApp` dir: `cd SampleApp`.

1. Run `bundle exec pod install` to update the `Podfile.lock` with the new versions.

1. Change back to the root directory (`cd ..`) to commit the podspec version bumps and the `Podfile.lock` update.
   ```bash
   git commit -am "Bumping versions to 0.1.0."
   ```

1. Push your branch and open a PR into `master`.

1. Once the PR is merged, fetch changes and tag the release, using the merge commit:
   ```bash
   git fetch
   git tag 0.1.0 <merge commit SHA>
   git push origin 0.1.0
   ```

1. Publish to CocoaPods

When linting before publishing, CocoaPods will build `BlueprintUICommonControls` using the latest published version of `BlueprintUI` (not your local version). You will need to run `pod repo update` to pull the new version of `BlueprintUI` into your local specs repo immediately after publishing it.

Note: You may also need to quit Xcode before running these commands in order for the linting builds to succeed.

```bash
bundle exec pod trunk push BlueprintUI.podspec
bundle exec pod repo update
bundle exec pod trunk push BlueprintUICommonControls.podspec
```
