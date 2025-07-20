require 'fastlane/action'
require_relative '../helper/instabug_stores_upload_helper'

module Fastlane
  module Actions
    class InstabugBuildIosAppAction < Action
      def self.run(params)
        UI.message("Starting Instabug iOS build...")
        
        # Extract Instabug-specific parameters
        branch_name = params.delete(:branch_name)
        instabug_api_key = params.delete(:instabug_api_key)
        
        # Validate required parameters
        if branch_name.nil? || branch_name.empty?
          UI.user_error!("branch_name is required for Instabug reporting")
        end
        
        begin
          # Report build start to Instabug
          Helper::InstabugStoresUploadHelper.report_status(
            branch_name: branch_name,
            api_key: instabug_api_key,
            status: "inprogress",
            step: "build_app"
          )

          # Execute the actual iOS build
          result = Actions::BuildIosAppAction.run(params)

          # Report build success to Instabug
          Helper::InstabugStoresUploadHelper.report_status(
            branch_name: branch_name,
            api_key: instabug_api_key,
            status: "success",
            step: "build_app"
          )

          UI.success("iOS build completed successfully!")
          result
        rescue => e
          UI.error("iOS build failed: #{e.message}")

          # Report build failure to Instabug
          Helper::InstabugStoresUploadHelper.report_status(
            branch_name: branch_name,
            api_key: instabug_api_key,
            status: "failure",
            step: "build_app"
          )
          raise e
        end
      end

      def self.description
        "Build iOS app with Instabug metadata reporting"
      end

      def self.authors
        ["Instabug Company"]
      end

      def self.return_value
        "Returns the result from build_ios_app action"
      end

      def self.details
        "This action wraps the standard build_ios_app action and adds Instabug-specific metadata reporting. It tracks build events per branch and provides better observability for engineering teams."
      end

      def self.available_options
        # Start with the original build_ios_app options
        options = Actions::BuildIosAppAction.available_options
        
        # Add Instabug-specific options
        instabug_options = [
          FastlaneCore::ConfigItem.new(
            key: :branch_name,
            env_name: "INSTABUG_BRANCH_NAME",
            description: "The branch name for tracking builds",
            optional: false,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :instabug_api_key,
            env_name: "INSTABUG_API_KEY",
            description: "Instabug API key for reporting build events",
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
          'instabug_build_ios_app(
            branch_name: "main",
            instabug_api_key: "your-api-key",
            workspace: "MyApp.xcworkspace",
            scheme: "MyApp",
            export_method: "app-store",
            configuration: "Release"
          )'
        ]
      end

      def self.category
        :building
      end
    end
  end
end 