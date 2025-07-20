require 'spec_helper'

describe Fastlane::Actions::InstabugBuildAndroidAppAction do
  let(:valid_params) do
    {
      branch_name: 'crash-fix/instabug-crash-456',
      instabug_api_key: 'test-api-key',
      task: 'assembleRelease',
      project_dir: 'android/',
      properties: {
        'android.injected.signing.store.file' => 'keystore.jks',
        'android.injected.signing.store.password' => 'password'
      }
    }
  end

  let(:api_endpoint) { 'https://api.instabug.com/api/web/public/agent_fastlane/status' }

  before do
    stub_request(:patch, api_endpoint)
      .to_return(status: 200, body: '{}', headers: {})
  end

  describe '#run' do
    context 'when build succeeds' do
      it 'reports inprogress, calls build action, and reports success' do
        expect(Fastlane::Actions::GradleAction).to receive(:run)
          .with(hash_including(task: 'assembleRelease', project_dir: 'android/'))
          .and_return('build_result')

        result = described_class.run(valid_params)

        expect(result).to eq('build_result')
        expect(WebMock).to have_requested(:patch, api_endpoint)
          .with(
            body: {
              branch_name: 'crash-fix/instabug-crash-456',
              status: 'inprogress',
              step: 'build_app'
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
              step: 'build_app'
            }.to_json,
            headers: {
              'Content-Type' => 'application/json',
              'Authorization' => 'Bearer test-api-key',
              'User-Agent' => 'fastlane-plugin-instabug-stores-upload'
            }
          ).once
      end
    end

    context 'when build fails' do
      it 'reports failure and re-raises the error' do
        error = StandardError.new('Build failed')
        expect(Fastlane::Actions::GradleAction).to receive(:run)
          .and_raise(error)

        expect {
          described_class.run(valid_params)
        }.to raise_error(StandardError, 'Build failed')

        expect(WebMock).to have_requested(:patch, api_endpoint)
          .with(
            body: {
              branch_name: 'crash-fix/instabug-crash-456',
              status: 'failure',
              step: 'build_app'
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
      it 'does not make API calls but still runs build' do
        params = valid_params.merge(branch_name: 'feature/new-feature')
        
        expect(Fastlane::Actions::GradleAction).to receive(:run)
          .and_return('build_result')

        result = described_class.run(params)

        expect(result).to eq('build_result')
        expect(WebMock).not_to have_requested(:patch, api_endpoint)
      end
    end
  end

  describe 'metadata' do
    it 'has correct description' do
      expect(described_class.description).to eq('Build Android app with Instabug metadata reporting')
    end

    it 'supports Android platform only' do
      expect(described_class.is_supported?(:android)).to be true
      expect(described_class.is_supported?(:ios)).to be false
      expect(described_class.is_supported?(:mac)).to be false
    end

    it 'has correct category' do
      expect(described_class.category).to eq(:building)
    end
  end
end 