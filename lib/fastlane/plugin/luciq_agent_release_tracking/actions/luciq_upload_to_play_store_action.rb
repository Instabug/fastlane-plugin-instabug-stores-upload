require 'fastlane/action'
require_relative '../helper/luciq_agent_release_tracking_helper'

module Fastlane
  module Actions
    class LuciqUploadToPlayStoreAction < Action
      def self.run(params)
        UI.message("Starting Luciq Play Store upload...")

        # Extract Luciq-specific parameters
        branch_name = params[:branch_name]
        luciq_api_key = params[:luciq_api_key]

        # Validate required parameters
        if branch_name.nil? || branch_name.empty?
          UI.user_error!("branch_name is required for Luciq reporting")
        end

        # Filter out Luciq-specific parameters before passing to upload_to_play_store
        filtered_params = Helper::LuciqAgentReleaseTrackingHelper.filter_luciq_params(params, Actions::UploadToPlayStoreAction)

        begin
          # Report upload start to Luciq
          Helper::LuciqAgentReleaseTrackingHelper.report_status(
            branch_name:,
            api_key: luciq_api_key,
            status: "inprogress",
            step: "upload_to_store"
          )

          # Execute the actual upload to Play Store
          result = Actions::UploadToPlayStoreAction.run(filtered_params)

          # Extract version information for Android
          version_code = detect_version_code(params)

          # Report upload success to Luciq
          Helper::LuciqAgentReleaseTrackingHelper.report_status(
            branch_name:,
            api_key: luciq_api_key,
            status: "success",
            step: "upload_to_store",
            extras: {
              version_code:
            }.compact
          )

          UI.success("Play Store upload completed successfully!")
          result
        rescue StandardError => e
          error_message = Helper::LuciqAgentReleaseTrackingHelper.extract_error_message(e.message, :upload_to_store)
          UI.error("Play Store upload failed: #{error_message}")

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
        "Upload to Play Store with Luciq agent metadata reporting"
      end

      def self.authors
        ["Luciq Company"]
      end

      def self.return_value
        "Returns the result from upload_to_play_store action"
      end

      def self.details
        "This action wraps the standard upload_to_play_store action and adds Luciq agent metadata reporting. It tracks upload events per branch and provides better observability for engineering teams."
      end

      def self.available_options
        # Start with the original upload_to_play_store options
        options = Actions::UploadToPlayStoreAction.available_options

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
        platform == :android
      end

      def self.example_code
        [
          'luciq_upload_to_play_store(
            branch_name: "main",
            luciq_api_key: "your-api-key",
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

      def self.detect_version_code(params)
        return params[:version_code] if params[:version_code]

        UI.message("Fetching latest version code from Google Play Console...")

        begin
          # Build parameters hash
          google_play_params = build_google_play_params(params)

          version_codes = Actions::GooglePlayTrackVersionCodesAction.run(google_play_params)

          if version_codes&.any?
            latest_version = version_codes.first
            UI.success("Found latest version code: #{latest_version}")
            latest_version
          else
            UI.error("No version codes found on Google Play")
            nil
          end
        rescue StandardError => e
          UI.error("Failed to fetch from Google Play: #{e.message}")
          nil
        end
      end

      # Build parameters for google_play_track_version_codes action
      def self.build_google_play_params(params)
        google_params = {
          package_name: params[:package_name],
          track: params[:track] || 'production'
        }

        # Add authentication parameters
        auth_keys = %i[key issuer json_key json_key_data root_url timeout]
        auth_keys.each do |key|
          google_params[key] = params[key]
        end

        google_params.compact
      end
    end
  end
end
