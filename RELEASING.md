# Releasing a new version

1. You must be listed as an owner of the pods `BlueprintUI` and `BlueprintUICommonControls`.

To check this run:

```bash
bundle exec pod trunk info BlueprintUI
bundle exec pod trunk info BlueprintUICommonControls
```

See [the CocoaPods documentation for pod trunk](https://guides.cocoapods.org/making/getting-setup-with-trunk) for more information about setting up credentials on your device.

1. Make sure you're on the `master` branch

1. Make sure that the library version in both `BlueprintUI.podspec` and `BlueprintUICommonControls.podspec` is correct (it should match the version number that you are about to release).

1. Run `bundle exec pod install` to update the `Podfile.lock` with the new versions.

1. Create a commit containing the podspec version bumps and the `Podfile.lock` update, and tag the commit with the version number.
   ```bash
   git commit -am "Releasing 0.1.0."
   git tag 0.1.0
   ```

1. Push your changes
   ```bash
   git push origin master && git push origin 0.1.0
   ```

1. Publish to CocoaPods

When linting before publishing, CocoaPods will build `BlueprintUICommonControls` using the latest published version of `BlueprintUI` (not your local version). You will need to run `pod repo update` to pull the new version of `BlueprintUI` into your local specs repo immediately after publishing it.

You may also need to quit Xcode before running these commands in order for the linting builds to succeed.

```bash
bundle exec pod trunk push BlueprintUI.podspec
bundle exec pod repo update
bundle exec pod trunk push BlueprintUICommonControls.podspec
```
