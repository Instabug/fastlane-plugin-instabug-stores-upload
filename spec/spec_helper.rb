$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'simplecov'

# SimpleCov.minimum_coverage 95
SimpleCov.start

# This module is only used to check the environment is currently a testing env
module SpecHelper
end

require 'fastlane' # to import the Action super class
require 'fastlane/plugin/luciq_agent_release_tracking' # import the actual plugin
require 'webmock/rspec'

# Override the helper method for tests to handle plain hashes
class Fastlane::Helper::LuciqAgentReleaseTrackingHelper
  def self.filter_luciq_params(params, target_action_class)
    # In test environment, params are plain hashes - just filter them
    return params.except(*LUCIQ_KEYS)
  end
end

Fastlane.load_actions # load other actions (in case your plugin calls other actions or shared values)

WebMock.disable_net_connect!(allow_localhost: true)
