fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios beta

```sh
[bundle exec] fastlane ios beta
```

TestFlight에 업로드

### ios release

```sh
[bundle exec] fastlane ios release
```

App Store에 제출 (메타데이터 포함)

### ios metadata

```sh
[bundle exec] fastlane ios metadata
```

메타데이터만 업로드 (빌드 없이)

### ios deploy

```sh
[bundle exec] fastlane ios deploy
```

빌드 번호 증가 후 TestFlight 업로드

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
