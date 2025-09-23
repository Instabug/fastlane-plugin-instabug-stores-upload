require 'fastlane_core/ui/ui'
require 'net/http'
require 'uri'
require 'json'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?(:UI)

  module Helper
    class LuciqAgentReleaseTrackingHelper
      # Default Base URL for Luciq API
      DEFAULT_LUCIQ_API_BASE_URL = "https://api.instabug.com".freeze
      LUCIQ_KEYS = %i[branch_name luciq_api_key luciq_api_base_url].freeze
      FASTLANE_ERROR_MESSAGE = {
        build_app: "Your build was triggered but failed during execution. This could be due to missing environment variables or incorrect build credentials. Check CI logs for full details.",
        upload_to_store: "Something went wrong while uploading your build. Check your Fastlane run for more details."
      }

      # Extract the important part of an error message
      def self.extract_error_message(error_message, step)
        return error_message unless error_message.kind_of?(String)

        lines = error_message.split("\n")
        start_index = lines.find_index { |line| line.strip.start_with?("* What went wrong:") }
        end_index   = lines.find_index { |line| line.strip.start_with?("* Try:") }

        if start_index && end_index && end_index > start_index
          extracted_lines = lines[(start_index + 1)...end_index].map(&:strip).reject(&:empty?)
          return extracted_lines.join(" ")[0, 250] unless extracted_lines.empty?
        end

        # Fallback message
        FASTLANE_ERROR_MESSAGE[step]
      end

      def self.show_message
        UI.message("Hello from the luciq_agent_release_tracking plugin helper!")
      end

      # Filters out Luciq-specific parameters from the params configuration
      # and returns a new FastlaneCore::Configuration object with only the target action's parameters
      def self.filter_luciq_params(params, target_action_class)
        filtered_config = {}
        params.available_options.each do |option|
          key = option.key
          filtered_config[key] = params[key] unless LUCIQ_KEYS.include?(key)
        end

        FastlaneCore::Configuration.create(target_action_class.available_options, filtered_config)
      end

      def self.report_status(branch_name:, api_key:, status:, step:, extras: {}, error_message: nil)
        return unless branch_name.start_with?('crash-fix/instabug-crash-')

        UI.message("📡 Reporting #{step} status to Luciq for #{branch_name}/#{status}")

        make_api_request(
          branch_name:,
          status:,
          api_key:,
          step:,
          extras:,
          error_message:
        )
      end

      def self.make_api_request(branch_name:, status:, api_key:, step:, extras: {}, error_message: nil)
        return unless api_key

        # Determine API base URL from env var or default
        base_url = ENV['LUCIQ_API_BASE_URL'] || DEFAULT_LUCIQ_API_BASE_URL
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
          request['User-Agent'] = "fastlane-plugin-luciq_agent_release_tracking"
          request.body = payload.to_json

          response = http.request(request)

          case response.code.to_i
          when 200..299
            UI.success("✅ Successfully reported to Luciq")
          else
            UI.error("❌ Unknown error reporting to Luciq: #{response.code} #{response.message}")
          end
        rescue Net::TimeoutError
          UI.error("❌ Timeout while reporting to Luciq")
        rescue Net::OpenTimeout
          UI.error("❌ Connection timeout while reporting to Luciq")
        rescue StandardError => e
          UI.error("❌ Error reporting to Luciq: #{e.message}")
        end
      end
    end
  end
end
