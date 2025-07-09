require 'spec_helper'

describe Fastlane::Actions::InstabugUploadToPlayStoreAction do
  let(:valid_params) do
    {
      branch_name: 'crash-fix/instabug-crash-456',
      instabug_api_key: 'test-api-key',
      package_name: 'com.example.app',
      aab: 'test.aab',
      track: 'internal'
    }
  end

  let(:api_endpoint) { 'https://api.instabug.com/api/web/public/agent_fastlane/status' }

  before do
    stub_request(:patch, api_endpoint)
      .to_return(status: 200, body: '{}', headers: {})
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
              step: 'upload_to_the_store'
            }.to_json,
            headers: {
              'Content-Type' => 'application/json',
              'Authorization' => 'Bearer test-api-key',
              'User-Agent' => 'fastlane-plugin-instabug-stores-upload'
            }
          ).once

        expect(WebMock).to have_requested(:patch, api_endpoint)
          .with(
            body: {
              branch_name: 'crash-fix/instabug-crash-456',
              status: 'success',
              step: 'upload_to_the_store'
            }.to_json,
            headers: {
              'Content-Type' => 'application/json',
              'Authorization' => 'Bearer test-api-key',
              'User-Agent' => 'fastlane-plugin-instabug-stores-upload'
            }
          ).once
      end
    end

    context 'when upload fails' do
      it 'reports failure and re-raises the error' do
        error = StandardError.new('Upload failed')
        expect(Fastlane::Actions::UploadToPlayStoreAction).to receive(:run)
          .and_raise(error)

        expect {
          described_class.run(valid_params)
        }.to raise_error(StandardError, 'Upload failed')

        expect(WebMock).to have_requested(:patch, api_endpoint)
          .with(
            body: {
              branch_name: 'crash-fix/instabug-crash-456',
              status: 'failure',
              step: 'upload_to_the_store'
            }.to_json
          )
      end
    end

    context 'when branch_name is missing' do
      it 'raises user error' do
        params = valid_params.merge(branch_name: nil)

        expect {
          described_class.run(params)
        }.to raise_error(FastlaneCore::Interface::FastlaneError, 'branch_name is required for Instabug reporting')
      end
    end

    context 'when branch_name is empty' do
      it 'raises user error' do
        params = valid_params.merge(branch_name: '')

        expect {
          described_class.run(params)
        }.to raise_error(FastlaneCore::Interface::FastlaneError, 'branch_name is required for Instabug reporting')
      end
    end

    context 'when branch name does not match instabug pattern' do
      it 'does not make API calls but still runs upload' do
        params = valid_params.merge(branch_name: 'feature/new-feature')
        
        expect(Fastlane::Actions::UploadToPlayStoreAction).to receive(:run)
          .and_return('upload_result')

        result = described_class.run(params)

        expect(result).to eq('upload_result')
        expect(WebMock).not_to have_requested(:patch, api_endpoint)
      end
    end
  end

  describe 'metadata' do
    it 'has correct description' do
      expect(described_class.description).to eq('Upload to Play Store with Instabug metadata reporting')
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