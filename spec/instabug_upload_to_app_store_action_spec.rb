require 'spec_helper'

describe Fastlane::Actions::InstabugUploadToAppStoreAction do
  let(:valid_params) do
    {
      branch_name: 'crash-fix/instabug-crash-123',
      instabug_api_key: 'test-api-key',
      ipa: 'test.ipa',
      skip_screenshots: true
    }
  end

  let(:api_endpoint) { 'https://api.instabug.com/api/web/public/agent_fastlane/status' }

  before do
    stub_request(:patch, api_endpoint)
      .to_return(status: 200, body: '{}', headers: {})
  end

  describe '#run' do
    context 'when upload succeeds' do
      it 'reports inprogress, calls upload action, and reports success with version detection' do
        # Mock IPA file analysis
        allow(File).to receive(:exist?).with('test.ipa').and_return(true)
        allow(FastlaneCore::IpaFileAnalyser).to receive(:fetch_app_version).with('test.ipa').and_return('1.2.3')

        expect(Fastlane::Actions::UploadToAppStoreAction).to receive(:run)
          .with(hash_including(ipa: 'test.ipa', skip_screenshots: true))
          .and_return('upload_result')

        result = described_class.run(valid_params)

        expect(result).to eq('upload_result')
        expect(WebMock).to have_requested(:patch, api_endpoint)
          .with(
            body: {
              branch_name: 'crash-fix/instabug-crash-123',
              status: 'inprogress',
              step: 'upload_to_store',
              extras: {},
              error_message: nil
            }.to_json,
            headers: {
              'Content-Type' => 'application/json',
              'Authorization' => 'Bearer test-api-key',
              'User-Agent' => 'fastlane-plugin-instabug_stores_upload'
            }
          ).once

        expect(WebMock).to have_requested(:patch, api_endpoint)
          .with(
            body: {
              branch_name: 'crash-fix/instabug-crash-123',
              status: 'success',
              step: 'upload_to_store',
              extras: {
                version_string: '1.2.3'
              },
              error_message: nil
            }.to_json,
            headers: {
              'Content-Type' => 'application/json',
              'Authorization' => 'Bearer test-api-key',
              'User-Agent' => 'fastlane-plugin-instabug_stores_upload'
            }
          ).once
      end

      it 'uses app_version parameter when provided' do
        params_with_version = valid_params.merge(app_version: '2.0.0')

        expect(Fastlane::Actions::UploadToAppStoreAction).to receive(:run)
          .with(hash_including(ipa: 'test.ipa', skip_screenshots: true, app_version: '2.0.0'))
          .and_return('upload_result')

        result = described_class.run(params_with_version)

        expect(result).to eq('upload_result')
        expect(WebMock).to have_requested(:patch, api_endpoint)
          .with { |req|
            body = JSON.parse(req.body)
            body['status'] == 'success' &&
              body['extras']['version_string'] == '2.0.0'
          }.once
      end

      it 'handles IPA extraction failure gracefully' do
        allow(File).to receive(:exist?).with('test.ipa').and_return(true)
        allow(FastlaneCore::IpaFileAnalyser).to receive(:fetch_app_version).with('test.ipa').and_raise(StandardError.new('IPA analysis failed'))

        expect(Fastlane::Actions::UploadToAppStoreAction).to receive(:run)
          .and_return('upload_result')

        result = described_class.run(valid_params)

        expect(result).to eq('upload_result')
        expect(WebMock).to have_requested(:patch, api_endpoint)
          .with { |req|
            body = JSON.parse(req.body)
            body['status'] == 'success' &&
              body['extras'].empty?
          }.once
      end

      it 'handles missing IPA file gracefully' do
        allow(File).to receive(:exist?).with('test.ipa').and_return(false)

        expect(Fastlane::Actions::UploadToAppStoreAction).to receive(:run)
          .and_return('upload_result')

        result = described_class.run(valid_params)

        expect(result).to eq('upload_result')
        expect(WebMock).to have_requested(:patch, api_endpoint)
          .with { |req|
            body = JSON.parse(req.body)
            body['status'] == 'success' &&
              body['extras'].empty?
          }.once
      end
    end

    context 'when upload fails' do
      it 'reports failure and re-raises the error' do
        error = StandardError.new('Upload failed')
        expect(Fastlane::Actions::UploadToAppStoreAction).to receive(:run)
          .and_raise(error)

        expect do
          described_class.run(valid_params)
        end.to raise_error(StandardError, 'Upload failed')

        expect(WebMock).to have_requested(:patch, api_endpoint)
          .with(
            body: {
              branch_name: 'crash-fix/instabug-crash-123',
              status: 'failure',
              step: 'upload_to_store',
              extras: {},
              error_message: 'Upload failed'
            }.to_json
          )
      end
    end

    context 'when branch_name is missing' do
      it 'raises user error' do
        params = valid_params.merge(branch_name: nil)

        expect do
          described_class.run(params)
        end.to raise_error(FastlaneCore::Interface::FastlaneError, 'branch_name is required for Instabug reporting')
      end
    end

    context 'when branch_name is empty' do
      it 'raises user error' do
        params = valid_params.merge(branch_name: '')

        expect do
          described_class.run(params)
        end.to raise_error(FastlaneCore::Interface::FastlaneError, 'branch_name is required for Instabug reporting')
      end
    end

    context 'when branch name does not match instabug pattern' do
      it 'does not make API calls but still runs upload' do
        params = valid_params.merge(branch_name: 'feature/new-feature')

        expect(Fastlane::Actions::UploadToAppStoreAction).to receive(:run)
          .and_return('upload_result')

        result = described_class.run(params)

        expect(result).to eq('upload_result')
        expect(WebMock).not_to have_requested(:patch, api_endpoint)
      end
    end
  end

  describe '.detect_app_version' do
    let(:params) { { ipa: 'test.ipa' } }

    context 'when app_version is provided in parameters' do
      it 'returns the parameter value' do
        params_with_version = params.merge(app_version: '1.5.0')

        result = described_class.detect_app_version(params_with_version)

        expect(result).to eq('1.5.0')
      end
    end

    context 'when app_version is not provided' do
      it 'extracts from IPA file when available' do
        allow(File).to receive(:exist?).with('test.ipa').and_return(true)
        allow(FastlaneCore::IpaFileAnalyser).to receive(:fetch_app_version).with('test.ipa').and_return('3.2.1')

        result = described_class.detect_app_version(params)

        expect(result).to eq('3.2.1')
      end

      it 'returns nil when IPA extraction fails' do
        allow(File).to receive(:exist?).with('test.ipa').and_return(true)
        allow(FastlaneCore::IpaFileAnalyser).to receive(:fetch_app_version).with('test.ipa').and_raise(StandardError.new('Failed'))

        result = described_class.detect_app_version(params)

        expect(result).to be_nil
      end

      it 'returns nil when IPA file does not exist' do
        allow(File).to receive(:exist?).with('test.ipa').and_return(false)

        result = described_class.detect_app_version(params)

        expect(result).to be_nil
      end

      it 'returns nil when no IPA path is provided' do
        params_without_ipa = {}

        result = described_class.detect_app_version(params_without_ipa)

        expect(result).to be_nil
      end

      it 'returns nil when version string is empty' do
        allow(File).to receive(:exist?).with('test.ipa').and_return(true)
        allow(FastlaneCore::IpaFileAnalyser).to receive(:fetch_app_version).with('test.ipa').and_return('')

        result = described_class.detect_app_version(params)

        expect(result).to be_nil
      end
    end
  end

  describe 'metadata' do
    it 'has correct description' do
      expect(described_class.description).to eq('Upload to App Store with Instabug metadata reporting')
    end

    it 'supports iOS and Mac platforms' do
      expect(described_class.is_supported?(:ios)).to be true
      expect(described_class.is_supported?(:mac)).to be true
      expect(described_class.is_supported?(:android)).to be false
    end

    it 'has correct category' do
      expect(described_class.category).to eq(:app_store_connect)
    end
  end
end
