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

Fastlane.load_actions # load other actions (in case your plugin calls other actions or shared values)

WebMock.disable_net_connect!(allow_localhost: true)
