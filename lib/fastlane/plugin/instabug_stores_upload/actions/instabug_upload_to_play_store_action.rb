require 'fastlane/action'
require_relative '../helper/instabug_stores_upload_helper'

module Fastlane
  module Actions
    class InstabugUploadToPlayStoreAction < Action
      def self.run(params)
        UI.message("Starting Instabug Play Store upload...")
        
        # Extract Instabug-specific parameters
        branch_name = params.delete(:branch_name)
        instabug_api_key = params.delete(:instabug_api_key)

        # Validate required parameters
        if branch_name.nil? || branch_name.empty?
          UI.user_error!("branch_name is required for Instabug reporting")
        end

        begin
          # Report upload start to Instabug
          Helper::InstabugStoresUploadHelper.report_status(
            branch_name: branch_name,
            api_key: instabug_api_key,
            status: "inprogress",
            step: "upload_to_the_store"
          )

          # Execute the actual upload to Play Store
          result = Actions::UploadToPlayStoreAction.run(params)
          
          # Report upload success to Instabug
          Helper::InstabugStoresUploadHelper.report_status(
            branch_name: branch_name,
            api_key: instabug_api_key,
            status: "success",
            step: "upload_to_the_store"
          )
          
          UI.success("Play Store upload completed successfully!")
          result
          
        rescue => e
          UI.error("Play Store upload failed: #{e.message}")

          # Report upload failure to Instabug
          Helper::InstabugStoresUploadHelper.report_status(
            branch_name: branch_name,
            api_key: instabug_api_key,
            status: "failure",
            step: "upload_to_the_store"
          )
          raise e
        end
      end

      def self.description
        "Upload to Play Store with Instabug metadata reporting"
      end

      def self.authors
        ["Instabug Company"]
      end

      def self.return_value
        "Returns the result from upload_to_play_store action"
      end

      def self.details
        "This action wraps the standard upload_to_play_store action and adds Instabug-specific metadata reporting. It tracks upload events per branch and provides better observability for engineering teams."
      end

      def self.available_options
        # Start with the original upload_to_play_store options
        options = Actions::UploadToPlayStoreAction.available_options
        
        # Add Instabug-specific options
        instabug_options = [
          FastlaneCore::ConfigItem.new(
            key: :branch_name,
            env_name: "INSTABUG_BRANCH_NAME",
            description: "The branch name for tracking uploads",
            optional: false,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :instabug_api_key,
            env_name: "INSTABUG_API_KEY",
            description: "Instabug API key for reporting upload events",
            optional: false,
            type: String,
            sensitive: true
          )
        ]
        
        # Combine both sets of options
        options + instabug_options
      end

      def self.is_supported?(platform)
        platform == :android
      end

      def self.example_code
        [
          'instabug_upload_to_play_store(
            branch_name: "main",
            instabug_api_key: "your-api-key",
            package_name: "com.example.app",
            aab: "path/to/your.aab",
            track: "internal",
            skip_upload_screenshots: true
          )'
        ]
      end

      def self.category
        :google_play_console
      end
    end
  end
end 