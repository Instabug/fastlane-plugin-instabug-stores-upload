require 'fastlane/action'
require_relative '../helper/luciq_agent_release_tracking_helper'

module Fastlane
  module Actions
    class LuciqBuildIosAppAction < Action
      def self.run(params)
        UI.message("Starting Luciq iOS build...")

        # Extract Luciq-specific parameters
        branch_name = params[:branch_name]
        luciq_api_key = params[:luciq_api_key]

        # Validate required parameters
        if branch_name.nil? || branch_name.empty?
          UI.user_error!("branch_name is required for Luciq reporting")
        end

        # Filter out Luciq-specific parameters before passing to build_ios_app
        filtered_params = Helper::LuciqAgentReleaseTrackingHelper.filter_luciq_params(params, Actions::BuildIosAppAction)

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

          # Execute the actual iOS build
          result = Actions::BuildIosAppAction.run(filtered_params)

          # Calculate build time in seconds
          build_time = (Time.now - build_start_time).round

          # Extract IPA path from Fastlane environment
          build_path = Actions.lane_context[SharedValues::IPA_OUTPUT_PATH]

          if build_path
            UI.success("IPA Output Path: #{build_path}")
          else
            UI.error("No IPA path found.")
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

          UI.success("iOS build completed successfully!")
          result
        rescue StandardError => e
          error_message = Helper::LuciqAgentReleaseTrackingHelper.extract_error_message(e.message, :build_app)
          UI.error("iOS build failed: #{error_message}")

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
        "Build iOS app with Luciq agent metadata reporting"
      end

      def self.authors
        ["Luciq Company"]
      end

      def self.return_value
        "Returns the result from build_ios_app action"
      end

      def self.details
        "This action wraps the standard build_ios_app action and adds Luciq agent metadata reporting. It tracks build events per branch and provides better observability for engineering teams."
      end

      def self.available_options
        # Start with the original build_ios_app options
        options = Actions::BuildIosAppAction.available_options

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
        [:ios, :mac].include?(platform)
      end

      def self.example_code
        [
          'luciq_build_ios_app(
            branch_name: "main",
            luciq_api_key: "your-api-key",
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
