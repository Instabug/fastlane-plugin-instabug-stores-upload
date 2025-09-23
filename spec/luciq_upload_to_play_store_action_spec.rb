require 'spec_helper'

describe Fastlane::Actions::LuciqUploadToPlayStoreAction do
  let(:valid_params) do
    {
      branch_name: 'crash-fix/instabug-crash-456',
      luciq_api_key: 'test-api-key',
      package_name: 'com.example.app',
      aab: 'test.aab',
      track: 'internal',
      json_key: 'path/to/key.json'
    }
  end

  let(:api_endpoint) { 'https://api.instabug.com/api/web/public/agent_fastlane/status' }

  before do
    stub_request(:patch, api_endpoint)
      .to_return(status: 200, body: '{}', headers: {})

    # Mock the GooglePlayTrackVersionCodesAction to avoid actual API calls
    allow(Fastlane::Actions::GooglePlayTrackVersionCodesAction).to receive(:run)
      .and_return(['123', '122', '121'])
  end

  describe '#run' do
    context 'when upload succeeds' do
      it 'reports inprogress, calls upload action, and reports success' do
        expect(Fastlane::Actions::UploadToPlayStoreAction).to receive(:run)
          .with(hash_including(package_name: 'com.example.app', aab: 'test.aab', track: 'internal'))
          .and_return('upload_result')

        result = described_class.run(valid_params)

        expect(result).to eq('upload_result')
        expect(WebMock).to have_requested(:patch, api_endpoint)
          .with(
            body: {
              branch_name: 'crash-fix/instabug-crash-456',
              status: 'inprogress',
              step: 'upload_to_store',
              extras: {},
              error_message: nil
            }.to_json,
            headers: {
              'Content-Type' => 'application/json',
              'Authorization' => 'Bearer test-api-key',
              'User-Agent' => 'fastlane-plugin-luciq_agent_release_tracking'
            }
          ).once

        expect(WebMock).to have_requested(:patch, api_endpoint)
          .with(
            body: {
              branch_name: 'crash-fix/instabug-crash-456',
              status: 'success',
              step: 'upload_to_store',
              extras: { version_code: '123' },
              error_message: nil
            }.to_json,
            headers: {
              'Content-Type' => 'application/json',
              'Authorization' => 'Bearer test-api-key',
              'User-Agent' => 'fastlane-plugin-luciq_agent_release_tracking'
            }
          ).once
      end

      it 'uses version_code from parameters when provided' do
        params_with_version = valid_params.merge(version_code: '456')

        expect(Fastlane::Actions::UploadToPlayStoreAction).to receive(:run)
          .and_return('upload_result')

        result = described_class.run(params_with_version)

        expect(result).to eq('upload_result')
        expect(WebMock).to have_requested(:patch, api_endpoint)
          .with(
            body: hash_including(
              extras: { version_code: '456' }
            )
          ).once
      end

      it 'handles Google Play API failure gracefully' do
        allow(Fastlane::Actions::GooglePlayTrackVersionCodesAction).to receive(:run)
          .and_raise(StandardError.new('API Error'))

        expect(Fastlane::Actions::UploadToPlayStoreAction).to receive(:run)
          .and_return('upload_result')

        result = described_class.run(valid_params)

        expect(result).to eq('upload_result')
        expect(WebMock).to have_requested(:patch, api_endpoint)
          .with(
            body: hash_including(
              status: 'success',
              extras: {}
            )
          ).once
      end

      it 'handles empty version codes from Google Play' do
        allow(Fastlane::Actions::GooglePlayTrackVersionCodesAction).to receive(:run)
          .and_return([])

        expect(Fastlane::Actions::UploadToPlayStoreAction).to receive(:run)
          .and_return('upload_result')

        result = described_class.run(valid_params)

        expect(result).to eq('upload_result')
        expect(WebMock).to have_requested(:patch, api_endpoint)
          .with(
            body: hash_including(
              status: 'success',
              extras: {}
            )
          ).once
      end
    end

    context 'when upload fails' do
      it 'reports failure and re-raises the error' do
        error = StandardError.new('Upload failed')
        expect(Fastlane::Actions::UploadToPlayStoreAction).to receive(:run)
          .and_raise(error)

        expect do
          described_class.run(valid_params)
        end.to raise_error(StandardError, 'Upload failed')

        expect(WebMock).to have_requested(:patch, api_endpoint)
          .with(
            body: {
              branch_name: 'crash-fix/instabug-crash-456',
              status: 'failure',
              step: 'upload_to_store',
              extras: {},
              error_message: 'Something went wrong while uploading your build. Check your Fastlane run for more details.'
            }.to_json
          )
      end
    end

    context 'when branch_name is missing' do
      it 'raises user error' do
        params = valid_params.merge(branch_name: nil)

        expect do
          described_class.run(params)
        end.to raise_error(FastlaneCore::Interface::FastlaneError, 'branch_name is required for Luciq reporting')
      end
    end

    context 'when branch_name is empty' do
      it 'raises user error' do
        params = valid_params.merge(branch_name: '')

        expect do
          described_class.run(params)
        end.to raise_error(FastlaneCore::Interface::FastlaneError, 'branch_name is required for Luciq reporting')
      end
    end

    context 'when branch name does not match instabug pattern' do
      it 'does not make API calls but still runs upload' do
        params = valid_params.merge(branch_name: 'feature/new-feature')

        expect(Fastlane::Actions::UploadToPlayStoreAction).to receive(:run)
          .and_return('upload_result')

        # Should still try to detect version code even for non-matching branches
        expect(Fastlane::Actions::GooglePlayTrackVersionCodesAction).to receive(:run)
          .and_return(['123'])

        result = described_class.run(params)

        expect(result).to eq('upload_result')
        expect(WebMock).not_to have_requested(:patch, api_endpoint)
      end
    end
  end

  describe '.detect_version_code' do
    let(:params) do
      {
        package_name: 'com.example.app',
        track: 'production',
        json_key: 'path/to/key.json'
      }
    end

    context 'when version_code is provided in parameters' do
      it 'returns the parameter value' do
        params_with_version = params.merge(version_code: '789')

        result = described_class.detect_version_code(params_with_version)

        expect(result).to eq('789')
        expect(Fastlane::Actions::GooglePlayTrackVersionCodesAction).not_to have_received(:run)
      end
    end

    context 'when version_code is not in parameters' do
      it 'fetches from Google Play Console' do
        allow(Fastlane::Actions::GooglePlayTrackVersionCodesAction).to receive(:run)
          .with(hash_including(package_name: 'com.example.app', track: 'production'))
          .and_return(['456', '455', '454'])

        result = described_class.detect_version_code(params)

        expect(result).to eq('456')
      end

      it 'returns nil when Google Play returns empty array' do
        allow(Fastlane::Actions::GooglePlayTrackVersionCodesAction).to receive(:run)
          .and_return([])

        result = described_class.detect_version_code(params)

        expect(result).to be_nil
      end

      it 'returns nil when Google Play API fails' do
        allow(Fastlane::Actions::GooglePlayTrackVersionCodesAction).to receive(:run)
          .and_raise(StandardError.new('API Error'))

        result = described_class.detect_version_code(params)

        expect(result).to be_nil
      end
    end
  end

  describe 'metadata' do
    it 'has correct description' do
      expect(described_class.description).to eq('Upload to Play Store with Luciq agent metadata reporting')
    end

    it 'supports Android platform only' do
      expect(described_class.is_supported?(:android)).to be true
      expect(described_class.is_supported?(:ios)).to be false
      expect(described_class.is_supported?(:mac)).to be false
    end

    it 'has correct category' do
      expect(described_class.category).to eq(:google_play_console)
    end
  end
end
