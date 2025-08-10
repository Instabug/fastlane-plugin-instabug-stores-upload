lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/instabug_stores_upload/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-instabug-stores-upload'
  spec.version       = Fastlane::InstabugStoresUpload::VERSION
  spec.author        = 'Instabug'
  spec.email         = 'backend-team@instabug.com'

  spec.summary       = 'Wrapper plugin for uploading builds to App Store and Play Store with Instabug-specific metadata reporting.'
  spec.homepage      = "https://github.com/Instabug/fastlane-plugin-instabug-stores-upload"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*"] + %w(README.md LICENSE)
  spec.require_paths = ['lib']
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.required_ruby_version = '>= 3.2.2'

  spec.add_development_dependency('bundler')
  spec.add_development_dependency('fastlane', '~> 2.228.0')
  spec.add_development_dependency('rake')
  spec.add_development_dependency('rspec')
  spec.add_development_dependency('rubocop', '1.50.2')
  spec.add_development_dependency('rubocop-performance')
  spec.add_development_dependency('rubocop-require_tools')
  spec.add_development_dependency('simplecov')
end
