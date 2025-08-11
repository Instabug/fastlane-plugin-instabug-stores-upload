require 'fastlane_core/ui/ui'
require 'net/http'
require 'uri'
require 'json'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?(:UI)

  module Helper
    class InstabugStoresUploadHelper
      # Default Base URL for Instabug API
      DEFAULT_INSTABUG_API_BASE_URL = "https://api.instabug.com".freeze

      def self.show_message
        UI.message("Hello from the instabug_stores_upload plugin helper!")
      end

      def self.report_status(branch_name:, api_key:, status:, step:, extras: {}, error_message: nil)
        return unless branch_name.start_with?('crash-fix/instabug-crash-')

        UI.message("📡 Reporting #{step} status to Instabug for #{branch_name}/#{status}")

        make_api_request(
          branch_name:,
          status:,
          api_key:,
          step:,
          extras:,
          error_message:
        )
      end

      # This helper method provides a clean and prioritized way to get the Android build output.
      # It checks for the most common output types in a specific order.
      # This is used to get the build path for the Android build artifact.
      def self.fetch_android_build_path(lane_context)
        all_aab_paths = lane_context[Actions::SharedValues::GRADLE_ALL_AAB_OUTPUT_PATHS]
        return all_aab_paths if all_aab_paths && !all_aab_paths.empty?

        aab_path = lane_context[Actions::SharedValues::GRADLE_AAB_OUTPUT_PATH]
        return aab_path if aab_path && !aab_path.empty?

        all_apk_paths = lane_context[Actions::SharedValues::GRADLE_ALL_APK_OUTPUT_PATHS]
        return all_apk_paths if all_apk_paths && !all_apk_paths.empty?

        apk_path = lane_context[Actions::SharedValues::GRADLE_APK_OUTPUT_PATH]
        return apk_path if apk_path && !apk_path.empty?

        return nil
      end

      def self.make_api_request(branch_name:, status:, api_key:, step:, extras: {}, error_message: nil)
        return unless api_key

        # Determine API base URL from env var or default
        base_url = ENV['INSTABUG_API_BASE_URL'] || DEFAULT_INSTABUG_API_BASE_URL
        uri = URI.parse("#{base_url}/api/web/public/agent_fastlane/status")

        payload = {
          branch_name:,
          status:,
          step:,
          extras:,
          error_message:
        }

        begin
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.read_timeout = 30
          http.open_timeout = 30

          request = Net::HTTP::Patch.new(uri.path)
          request['Content-Type'] = 'application/json'
          request['Authorization'] = "Bearer #{api_key}"
          request['User-Agent'] = "fastlane-plugin-instabug_stores_upload"
          request.body = payload.to_json

          response = http.request(request)

          case response.code.to_i
          when 200..299
            UI.success("✅ Successfully reported to Instabug")
          else
            UI.error("❌ Unknown error reporting to Instabug: #{response.code} #{response.message}")
          end
        rescue Net::TimeoutError
          UI.error("❌ Timeout while reporting to Instabug")
        rescue Net::OpenTimeout
          UI.error("❌ Connection timeout while reporting to Instabug")
        rescue StandardError => e
          UI.error("❌ Error reporting to Instabug: #{e.message}")
        end
      end
    end
  end
end
