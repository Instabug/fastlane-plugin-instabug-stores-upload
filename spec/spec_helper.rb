$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'simplecov'

# SimpleCov.minimum_coverage 95
SimpleCov.start

# This module is only used to check the environment is currently a testing env
module SpecHelper
end

require 'fastlane' # to import the Action super class
require 'fastlane/plugin/instabug_stores_upload' # import the actual plugin
require 'webmock/rspec'

# Override the helper method for tests to handle plain hashes
class Fastlane::Helper::InstabugStoresUploadHelper
  def self.filter_instabug_params(params, target_action_class)
    # In test environment, params are plain hashes - just filter them
    return params.reject { |key, _value| INSTABUG_KEYS.include?(key) }
  end
end

Fastlane.load_actions # load other actions (in case your plugin calls other actions or shared values)

WebMock.disable_net_connect!(allow_localhost: true)
