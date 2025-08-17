require 'fastlane/action'
require_relative '../helper/instabug_stores_upload_helper'

module Fastlane
  module Actions
    class InstabugStoresUploadAction < Action
      def self.run(params)
        UI.message("The instabug_stores_upload plugin is working!")
      end

      def self.description
        "Wrapper plugin for uploading builds to App Store and Play Store with Instabug-specific metadata reporting."
      end

      def self.authors
        ["Instabug Company"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "This Fastlane plugin provides wrapper actions around the standard `upload_to_app_store` and `upload_to_play_store` actions. it automatically reports these to the Instabug systems via a secure HTTP request. This allows engineering teams to track build upload steps per branch and platform with better observability and integration into internal pipelines."
      end

      def self.available_options
        [
          # FastlaneCore::ConfigItem.new(key: :your_option,
          #                         env_name: "INSTABUG_STORES_UPLOAD_YOUR_OPTION",
          #                      description: "A description of your option",
          #                         optional: false,
          #                             type: String)
        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
        #
        # [:ios, :mac, :android].include?(platform)
        true
      end
    end
  end
end
