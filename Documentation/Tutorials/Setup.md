# Tutorial setup instructions

The easiest way to complete the Blueprint tutorials is to use the sample app included with the project.

1. Clone the Blueprint repo

```bash
git clone git@github.com:square/Blueprint.git
```

```bash
cd Blueprint
```

2. CocoaPods

The sample app uses CocoaPods to integrate dependencies. First, we'll make sure CocoaPods and all of its dependencies are installed.

```bash
bundle install
```

Next, we'll use CocoaPods to integrate the workspace that we will use for completing the tutorials.

```bash
cd SampleApp
bundle exec pod install
```

Finally...

```bash
open SampleApp.xcworkspace
```

3. Code!

The SampleApp project contains multiple app targets. `SampleApp` is a standalone demonstration of Blueprint. The project also contains targets for each tutorial (along with a target showing the tutorial in its completed state).

```
SampleApp
Tutorial 1
Tutorial 1 (Completed)
/// etc...
```

To follow along with [Tutorial 1](./Tutorial1.md), navigate to `Tutorials` > `Tutorial 1` in the project navigator to see the source code. Also be sure to select the `Tutorial 1` target before building so you can see the tutorial running in the simulator.
