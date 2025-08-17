require 'fastlane/action'
require_relative '../helper/instabug_stores_upload_helper'

module Fastlane
  module Actions
    class InstabugBuildAndroidAppAction < Action
      def self.run(params)
        UI.message("Starting Instabug Android build...")
        
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

          # Execute the actual Android build using gradle
          result = Actions::GradleAction.run(params)

          # Report build success to Instabug
          Helper::InstabugStoresUploadHelper.report_status(
            branch_name: branch_name,
            api_key: instabug_api_key,
            status: "success",
            step: "build_app"
          )

          UI.success("Android build completed successfully!")
          result
        rescue => e
          UI.error("Android build failed: #{e.message}")

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
        "Build Android app with Instabug metadata reporting"
      end

      def self.authors
        ["Instabug Company"]
      end

      def self.return_value
        "Returns the result from gradle action"
      end

      def self.details
        "This action wraps the standard gradle action and adds Instabug-specific metadata reporting. It tracks build events per branch and provides better observability for engineering teams."
      end

      def self.available_options
        # Start with the original gradle options
        options = Actions::GradleAction.available_options
        
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
        platform == :android
      end

      def self.example_code
        [
          'instabug_build_android_app(
            branch_name: "main",
            instabug_api_key: "your-api-key",
            task: "assembleRelease",
            project_dir: "android/",
            properties: {
              "android.injected.signing.store.file" => "keystore.jks",
              "android.injected.signing.store.password" => "password",
              "android.injected.signing.key.alias" => "key0",
              "android.injected.signing.key.password" => "password"
            }
          )'
        ]
      end

      def self.category
        :building
      end
    end
  end
end 