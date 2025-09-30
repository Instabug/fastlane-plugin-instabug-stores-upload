require 'fastlane/action'
require_relative '../helper/luciq_agent_release_tracking_helper'

module Fastlane
  module Actions
    class LuciqBuildAndroidAppAction < Action
      def self.run(params)
        UI.message("Starting Luciq Android build...")

        # Extract Luciq-specific parameters
        branch_name = params[:branch_name]
        luciq_api_key = params[:luciq_api_key]

        # Validate required parameters
        if branch_name.nil? || branch_name.empty?
          UI.user_error!("branch_name is required for Luciq reporting")
        end

        # Filter out Luciq-specific parameters before passing to gradle
        filtered_params = Helper::LuciqAgentReleaseTrackingHelper.filter_luciq_params(params, Actions::GradleAction)

        begin
          # Report build start to Luciq
          Helper::LuciqAgentReleaseTrackingHelper.report_status(
            branch_name:,
            api_key: luciq_api_key,
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

          # Report build success to Luciq
          Helper::LuciqAgentReleaseTrackingHelper.report_status(
            branch_name:,
            api_key: luciq_api_key,
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
          error_message = Helper::LuciqAgentReleaseTrackingHelper.extract_error_message(e.message, :build_app)
          UI.error("Android build failed: #{error_message}")

          # Report build failure to Luciq
          Helper::LuciqAgentReleaseTrackingHelper.report_status(
            branch_name:,
            api_key: luciq_api_key,
            status: "failure",
            step: "build_app",
            error_message:
          )
          raise e
        end
      end

      def self.description
        "Build Android app with Luciq agent metadata reporting"
      end

      def self.authors
        ["Luciq Company"]
      end

      def self.return_value
        "Returns the result from gradle action"
      end

      def self.details
        "This action wraps the standard gradle action and adds Luciq agent metadata reporting. It tracks build events per branch and provides better observability for engineering teams."
      end

      def self.available_options
        # Start with the original gradle options
        options = Actions::GradleAction.available_options

        # Add Luciq-specific options
        luciq_options = [
          FastlaneCore::ConfigItem.new(
            key: :branch_name,
            env_name: "LUCIQ_BRANCH_NAME",
            description: "The branch name for tracking builds",
            optional: false,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :luciq_api_key,
            env_name: "LUCIQ_API_KEY",
            description: "Luciq API key for reporting build events",
            optional: false,
            type: String,
            sensitive: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :luciq_api_base_url,
            env_name: "LUCIQ_API_BASE_URL",
            description: "Luciq API base URL (defaults to https://api.instabug.com)",
            optional: true,
            type: String,
            skip_type_validation: true # Since we don't extract this param
          )
        ]

        # Combine both sets of options
        options + luciq_options
      end

      def self.is_supported?(platform)
        platform == :android
      end

      def self.example_code
        [
          'luciq_build_android_app(
            branch_name: "main",
            luciq_api_key: "your-api-key",
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
