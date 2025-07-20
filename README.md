# instabug-stores-upload plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-instabug-stores-upload)

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-instabug-stores-upload`, add it to your project by running:

```bash
fastlane add_plugin instabug-stores-upload
```

## About instabug-stores-upload

Wrapper plugin for uploading builds to App Store and Play Store with Instabug-specific metadata reporting. This plugin provides custom actions that wrap the standard Fastlane actions and automatically report build and upload events to Instabug systems for better observability and integration into internal pipelines.

### Available Actions

- `instabug_build_ios_app` - Build iOS apps with Instabug reporting
- `instabug_build_android_app` - Build Android apps with Instabug reporting
- `instabug_upload_to_app_store` - Upload iOS builds to App Store with Instabug reporting
- `instabug_upload_to_play_store` - Upload Android builds to Play Store with Instabug reporting

### Features

- Automatic reporting of build and upload events to Instabug
- Branch-based tracking for Instabug Agents observability
- Integration with existing Fastlane workflows
- Support for both iOS and Android platforms
- Secure API communication with Instabug services

## Example

Check out the [example `Fastfile`](fastlane/Fastfile) to see how to use this plugin. Try it by cloning the repo, running `fastlane install_plugins` and `bundle exec fastlane test`.

### Usage Examples

#### iOS Build
```ruby
lane :build_ios do
  instabug_build_ios_app(
    branch_name: "main",
    instabug_api_key: ENV["INSTABUG_API_KEY"],
    workspace: "MyApp.xcworkspace",
    scheme: "MyApp",
    export_method: "app-store",
    configuration: "Release"
  )
end
```

#### Android Build
```ruby
lane :build_android do
  instabug_build_android_app(
    branch_name: "main",
    instabug_api_key: ENV["INSTABUG_API_KEY"],
    task: "assembleRelease",
    project_dir: "android/",
    properties: {
      "android.injected.signing.store.file" => "keystore.jks",
      "android.injected.signing.store.password" => ENV["KEYSTORE_PASSWORD"],
      "android.injected.signing.key.alias" => "key0",
      "android.injected.signing.key.password" => ENV["KEY_PASSWORD"]
    }
  )
end
```

#### iOS Upload
```ruby
lane :upload_ios do
  instabug_upload_to_app_store(
    branch_name: "main",
    instabug_api_key: ENV["INSTABUG_API_KEY"],
    ipa: "path/to/your/app.ipa",
    skip_screenshots: true,
    skip_metadata: true
  )
end
```

#### Android Upload
```ruby
lane :upload_android do
  instabug_upload_to_play_store(
    branch_name: "main",
    instabug_api_key: ENV["INSTABUG_API_KEY"],
    package_name: "com.example.app",
    aab: "path/to/your/app.aab",
    track: "internal",
    skip_upload_screenshots: true
  )
end
```

## Run tests for this plugin

To run both the tests, and code style validation, run

```
rake
```

To automatically fix many of the styling issues, use
```
rubocop -a
```

## Issues and Feedback

For any other issues and feedback about this plugin, please submit it to this repository.

## Troubleshooting

If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## Using _fastlane_ Plugins

For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://docs.fastlane.tools/plugins/create-plugin/).

## About _fastlane_

_fastlane_ is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).
