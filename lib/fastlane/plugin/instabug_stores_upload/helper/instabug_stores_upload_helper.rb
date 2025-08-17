require 'fastlane_core/ui/ui'
require 'net/http'
require 'uri'
require 'json'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?(:UI)

  module Helper
    class InstabugStoresUploadHelper
      # Base URL for Instabug API we will need to adjust it for STs
      INSTABUG_API_BASE_URL = "https://api.instabug.com".freeze

      def self.show_message
        UI.message("Hello from the instabug_stores_upload plugin helper!")
      end

      def self.report_status(branch_name:, api_key:, status:, step:)
        return unless branch_name.start_with?('crash-fix/instabug-crash-')
        
        UI.message("📡 Reporting #{step} status to Instabug for #{branch_name}/#{status}")
        
        make_api_request(
          branch_name: branch_name,
          status: status,
          api_key: api_key,
          step: step
        )
      end

      private

      def self.make_api_request(branch_name:, status:, api_key:, step:)
        return unless api_key

        uri = URI.parse("#{INSTABUG_API_BASE_URL}/api/web/public/agent_fastlane/status") 
        
        payload = {
          branch_name: branch_name,
          status: status,
          step: step
        }
        
        begin
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.read_timeout = 30
          http.open_timeout = 30
          
          request = Net::HTTP::Patch.new(uri.path)
          request['Content-Type'] = 'application/json'
          request['Authorization'] = "Bearer #{api_key}"
          request['User-Agent'] = "fastlane-plugin-instabug-stores-upload"
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
