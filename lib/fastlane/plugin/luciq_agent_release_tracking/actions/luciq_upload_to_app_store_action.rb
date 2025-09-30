require 'fastlane/action'
require 'fastlane_core/ipa_file_analyser'
require_relative '../helper/luciq_agent_release_tracking_helper'

module Fastlane
  module Actions
    class LuciqUploadToAppStoreAction < Action
      def self.run(params)
        UI.message("Starting Luciq App Store upload...")

        # Extract Luciq-specific parameters
        branch_name = params[:branch_name]
        luciq_api_key = params[:luciq_api_key]

        # Validate required parameters
        if branch_name.nil? || branch_name.empty?
          UI.user_error!("branch_name is required for Luciq reporting")
        end

        # Filter out Luciq-specific parameters before passing to upload_to_app_store
        filtered_params = Helper::LuciqAgentReleaseTrackingHelper.filter_luciq_params(params, Actions::UploadToAppStoreAction)

        begin
          # Report upload start to Luciq
          Helper::LuciqAgentReleaseTrackingHelper.report_status(
            branch_name:,
            api_key: luciq_api_key,
            status: "inprogress",
            step: "upload_to_store"
          )

          # Execute the actual upload to App Store
          result = Actions::UploadToAppStoreAction.run(filtered_params)

          # Extract version information for iOS
          version_string = detect_app_version(params)

          # Report upload success to Luciq
          Helper::LuciqAgentReleaseTrackingHelper.report_status(
            branch_name:,
            api_key: luciq_api_key,
            status: "success",
            step: "upload_to_store",
            extras: {
              version_string:
            }.compact
          )

          UI.success("App Store upload completed successfully!")
          result
        rescue StandardError => e
          error_message = Helper::LuciqAgentReleaseTrackingHelper.extract_error_message(e.message, :upload_to_store)

          UI.error("App Store upload failed: #{error_message}")

          # Report upload failure to Luciq
          Helper::LuciqAgentReleaseTrackingHelper.report_status(
            branch_name:,
            api_key: luciq_api_key,
            status: "failure",
            step: "upload_to_store",
            error_message:
          )
          raise e
        end
      end

      def self.description
        "Upload to App Store with Luciq agent metadata reporting"
      end

      def self.authors
        ["Luciq Company"]
      end

      def self.return_value
        "Returns the result from upload_to_app_store action"
      end

      def self.details
        "This action wraps the standard upload_to_app_store action and adds Luciq agent metadata reporting. It tracks upload events per branch and provides better observability for engineering teams."
      end

      def self.available_options
        # Start with the original upload_to_app_store options
        options = Actions::UploadToAppStoreAction.available_options

        # Add Luciq-specific options
        luciq_options = [
          FastlaneCore::ConfigItem.new(
            key: :branch_name,
            env_name: "LUCIQ_BRANCH_NAME",
            description: "The branch name for tracking uploads",
            optional: false,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :luciq_api_key,
            env_name: "LUCIQ_API_KEY",
            description: "Luciq API key for reporting upload events",
            optional: false,
            type: String,
            sensitive: true
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
          'luciq_upload_to_app_store(
            branch_name: "main",
            luciq_api_key: "your-api-key",
            ipa: "path/to/your.ipa",
            skip_screenshots: true,
            skip_metadata: true
          )'
        ]
      end

      def self.category
        :app_store_connect
      end

      # Detect app version
      def self.detect_app_version(params)
        return params[:app_version] if params[:app_version]

        ipa = params[:ipa] || Actions.lane_context[SharedValues::IPA_OUTPUT_PATH]
        return nil unless ipa && File.exist?(ipa)

        begin
          version = FastlaneCore::IpaFileAnalyser.fetch_app_version(ipa)

          if version.to_s.strip.empty?
            UI.error("Could not extract version from IPA")
            return nil
          end

          UI.success("Found app version: #{version}")
          version
        rescue StandardError => e
          UI.verbose("Could not extract version from IPA: #{e.message}")
          nil
        end
      end
    end
  end
end
