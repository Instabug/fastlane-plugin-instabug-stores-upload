require 'spec_helper'
require 'webmock/rspec'

describe Fastlane::Helper::InstabugStoresUploadHelper do
  describe '.report_status' do
    let(:api_endpoint) { 'https://api.instabug.com/api/web/public/agent_fastlane/status' }

    before do
      stub_request(:patch, api_endpoint)
        .to_return(status: 200, body: '{}', headers: {})
    end

    context 'when branch name matches instabug pattern' do
      it 'makes API request for instabug crash branch' do
        described_class.report_status(
          branch_name: 'crash-fix/instabug-crash-123',
          api_key: 'test-key',
          status: 'success',
          step: 'build_app'
        )

        expect(WebMock).to have_requested(:patch, api_endpoint)
          .with(
            body: {
              branch_name: 'crash-fix/instabug-crash-123',
              status: 'success',
              step: 'build_app',
              extras: {},
              error_message: nil
            }.to_json,
            headers: {
              'Content-Type' => 'application/json',
              'Authorization' => 'Bearer test-key',
              'User-Agent' => 'fastlane-plugin-instabug_stores_upload'
            }
          ).once
      end
    end

    context 'when branch name does not match instabug pattern' do
      it 'does not make API request' do
        described_class.report_status(
          branch_name: 'feature/new-feature',
          api_key: 'test-key',
          status: 'success',
          step: 'build_app'
        )

        expect(WebMock).not_to have_requested(:patch, api_endpoint)
      end
    end

    context 'when no api_key is provided' do
      it 'does not make API request' do
        described_class.report_status(
          branch_name: 'crash-fix/instabug-crash-123',
          api_key: nil,
          status: 'success',
          step: 'build_app'
        )

        expect(WebMock).not_to have_requested(:patch, api_endpoint)
      end
    end
  end
end
