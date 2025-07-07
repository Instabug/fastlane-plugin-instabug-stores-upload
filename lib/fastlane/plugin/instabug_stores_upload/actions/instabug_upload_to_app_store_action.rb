require 'fastlane/action'
require_relative '../helper/instabug_stores_upload_helper'

module Fastlane
  module Actions
    class InstabugUploadToAppStoreAction < Action
      def self.run(params)
        UI.message("Starting Instabug App Store upload...")
        
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
            status: "inprogress"
          )

          # Execute the actual upload to App Store
          result = Actions::UploadToAppStoreAction.run(params)

          # Report upload success to Instabug
          Helper::InstabugStoresUploadHelper.report_status(
            branch_name: branch_name,
            api_key: instabug_api_key,
            status: "success"
          )

          UI.success("App Store upload completed successfully!")
          result
        rescue => e
          UI.error("App Store upload failed: #{e.message}")

          # Report upload failure to Instabug
          Helper::InstabugStoresUploadHelper.report_status(
            branch_name: branch_name,
            api_key: instabug_api_key,
            status: "failure"
          )
          raise e
        end
      end

      def self.description
        "Upload to App Store with Instabug metadata reporting"
      end

      def self.authors
        ["Instabug Company"]
      end

      def self.return_value
        "Returns the result from upload_to_app_store action"
      end

      def self.details
        "This action wraps the standard upload_to_app_store action and adds Instabug-specific metadata reporting. It tracks upload events per branch and provides better observability for engineering teams."
      end

      def self.available_options
        # Start with the original upload_to_app_store options
        options = Actions::UploadToAppStoreAction.available_options
        
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
        [:ios, :mac].include?(platform)
      end

      def self.example_code
        [
          'instabug_upload_to_app_store(
            branch_name: "main",
            instabug_api_key: "your-api-key",
            ipa: "path/to/your.ipa",
            skip_screenshots: true,
            skip_metadata: true
          )'
        ]
      end

      def self.category
        :app_store_connect
      end
    end
  end
end 