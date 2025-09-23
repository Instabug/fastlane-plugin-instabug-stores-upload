lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/luciq_agent_release_tracking/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-luciq_agent_release_tracking'
  spec.version       = Fastlane::LuciqAgentReleaseTracking::VERSION
  spec.author        = 'Luciq'
  spec.email         = 'support@luciq.ai'

  spec.summary       = 'Luciq agent for tracking release builds and uploads to App Store and Play Store with comprehensive metadata reporting.'
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
