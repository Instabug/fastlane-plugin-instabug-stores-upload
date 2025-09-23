require 'spec_helper'

describe Fastlane::Actions::LuciqBuildAndroidAppAction do
  let(:valid_params) do
    {
      branch_name: 'crash-fix/instabug-crash-456',
      luciq_api_key: 'test-api-key',
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
      it 'reports inprogress, calls build action, and reports success with timing and path' do
        # Mock the lane context to return a build path
        allow(Fastlane::Actions).to receive(:lane_context).and_return({
          Fastlane::Actions::SharedValues::GRADLE_APK_OUTPUT_PATH => '/path/to/app.apk'
        })

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
              step: 'build_app',
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
          .with { |req|
            body = JSON.parse(req.body)
            body['status'] == 'success' &&
              body['branch_name'] == 'crash-fix/instabug-crash-456' &&
              body['step'] == 'build_app' &&
              body['extras']['build_path'] == ['/path/to/app.apk'] &&
              body['extras']['build_time'].kind_of?(Integer)
          }.once
      end

      it 'fails when no build artifact is found' do
        # Mock empty lane context
        allow(Fastlane::Actions).to receive(:lane_context).and_return({})

        expect(Fastlane::Actions::GradleAction).to receive(:run)
          .and_return('build_result')

        expect do
          described_class.run(valid_params)
        end.to raise_error(FastlaneCore::Interface::FastlaneError, /Could not find any generated APK or AAB/)
      end
    end

    context 'when build fails' do
      it 'reports failure and re-raises the error' do
        error = StandardError.new('Build failed')
        expect(Fastlane::Actions::GradleAction).to receive(:run)
          .and_raise(error)

        expect do
          described_class.run(valid_params)
        end.to raise_error(StandardError, 'Build failed')

        expect(WebMock).to have_requested(:patch, api_endpoint)
          .with(
            body: {
              branch_name: 'crash-fix/instabug-crash-456',
              status: 'failure',
              step: 'build_app',
              extras: {},
              error_message: 'Your build was triggered but failed during execution. This could be due to missing environment variables or incorrect build credentials. Check CI logs for full details.'
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
      it 'does not make API calls but still runs build' do
        params = valid_params.merge(branch_name: 'feature/new-feature')

        # Mock successful build with a valid build path to avoid validation error
        allow(Fastlane::Actions).to receive(:lane_context).and_return({
          Fastlane::Actions::SharedValues::GRADLE_APK_OUTPUT_PATH => '/path/to/app.apk'
        })

        expect(Fastlane::Actions::GradleAction).to receive(:run)
          .and_return('build_result')

        result = described_class.run(params)

        expect(result).to eq('build_result')
        expect(WebMock).not_to have_requested(:patch, api_endpoint)
      end
    end
  end

  describe '.fetch_android_build_path' do
    let(:lane_context) { {} }

    context 'when all AAB output paths are available' do
      it 'returns all AAB paths' do
        lane_context[Fastlane::Actions::SharedValues::GRADLE_ALL_AAB_OUTPUT_PATHS] = ['/path/to/app1.aab', '/path/to/app2.aab']

        result = described_class.fetch_android_build_path(lane_context)

        expect(result).to eq(['/path/to/app1.aab', '/path/to/app2.aab'])
      end
    end

    context 'when single AAB output path is available' do
      it 'returns single AAB path' do
        lane_context[Fastlane::Actions::SharedValues::GRADLE_AAB_OUTPUT_PATH] = '/path/to/app.aab'

        result = described_class.fetch_android_build_path(lane_context)

        expect(result).to eq('/path/to/app.aab')
      end
    end

    context 'when all APK output paths are available' do
      it 'returns all APK paths' do
        lane_context[Fastlane::Actions::SharedValues::GRADLE_ALL_APK_OUTPUT_PATHS] = ['/path/to/app1.apk', '/path/to/app2.apk']

        result = described_class.fetch_android_build_path(lane_context)

        expect(result).to eq(['/path/to/app1.apk', '/path/to/app2.apk'])
      end
    end

    context 'when single APK output path is available' do
      it 'returns single APK path' do
        lane_context[Fastlane::Actions::SharedValues::GRADLE_APK_OUTPUT_PATH] = '/path/to/app.apk'

        result = described_class.fetch_android_build_path(lane_context)

        expect(result).to eq('/path/to/app.apk')
      end
    end

    context 'when no build paths are available' do
      it 'returns nil' do
        result = described_class.fetch_android_build_path(lane_context)

        expect(result).to be_nil
      end
    end
  end

  describe 'metadata' do
    it 'has correct description' do
      expect(described_class.description).to eq('Build Android app with Luciq agent metadata reporting')
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
