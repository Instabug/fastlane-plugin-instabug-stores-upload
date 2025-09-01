require 'fastlane/action'
require_relative '../helper/instabug_stores_upload_helper'

module Fastlane
  module Actions
    class InstabugBuildAndroidAppAction < Action
      def self.run(params)
        UI.message("Starting Instabug Android build...")

        # Extract Instabug-specific parameters
        branch_name = params[:branch_name]
        instabug_api_key = params[:instabug_api_key]

        # Validate required parameters
        if branch_name.nil? || branch_name.empty?
          UI.user_error!("branch_name is required for Instabug reporting")
        end

        # Filter out Instabug-specific parameters before passing to gradle
        filtered_params = Helper::InstabugStoresUploadHelper.filter_instabug_params(params, Actions::GradleAction)

        begin
          # Report build start to Instabug
          Helper::InstabugStoresUploadHelper.report_status(
            branch_name:,
            api_key: instabug_api_key,
            status: "inprogress",
            step: "build_app"
          )

          # Start timing the build
          build_start_time = Time.now

          # Execute the actual Android build using gradle
          result = Actions::GradleAction.run(filtered_params)

          # Calculate build time in seconds
          build_time = (Time.now - build_start_time).round

          # Extract Android build path (APK or AAB)
          build_path = fetch_android_build_path(Actions.lane_context)

          if build_path.nil? || build_path.empty?
            UI.user_error!("Could not find any generated APK or AAB. Please check your gradle settings.")
          else
            UI.success("Successfully found build artifact(s) at: #{build_path}")
          end

          # Report build success to Instabug
          Helper::InstabugStoresUploadHelper.report_status(
            branch_name:,
            api_key: instabug_api_key,
            status: "success",
            step: "build_app",
            extras: {
              build_time:,
              build_path: Array(build_path)
            }
          )

          UI.success("Android build completed successfully!")
          result
        rescue StandardError => e
          error_message = Helper::InstabugStoresUploadHelper.extract_error_message(e.message, :build_app)
          UI.error("Android build failed: #{error_message}")

          # Report build failure to Instabug
          Helper::InstabugStoresUploadHelper.report_status(
            branch_name:,
            api_key: instabug_api_key,
            status: "failure",
            step: "build_app",
            error_message:
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
          ),
          FastlaneCore::ConfigItem.new(
            key: :instabug_api_base_url,
            env_name: "INSTABUG_API_BASE_URL",
            description: "Instabug API base URL (defaults to https://api.instabug.com)",
            optional: true,
            type: String,
            skip_type_validation: true # Since we don't extract this param
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

      # This helper method provides a clean and prioritized way to get the Android build output.
      # It checks for the most common output types in a specific order.
      # This is used to get the build path for the Android build artifact.
      def self.fetch_android_build_path(lane_context)
        build_keys = [
          SharedValues::GRADLE_ALL_APK_OUTPUT_PATHS,
          SharedValues::GRADLE_APK_OUTPUT_PATH,
          SharedValues::GRADLE_ALL_AAB_OUTPUT_PATHS,
          SharedValues::GRADLE_AAB_OUTPUT_PATH
        ]
        build_keys.each do |build_key|
          build_path = lane_context[build_key]
          return build_path if build_path && !build_path.empty?
        end

        nil
      end
    end
  end
end
