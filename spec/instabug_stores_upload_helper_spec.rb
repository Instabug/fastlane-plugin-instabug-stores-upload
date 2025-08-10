require 'spec_helper'
require 'webmock/rspec'

describe Fastlane::Helper::InstabugStoresUploadHelper do
  describe '.fetch_android_build_path' do
    let(:lane_context) { {} }

    context 'when all AAB output paths are available' do
      it 'returns all AAB paths with highest priority' do
        lane_context[Fastlane::Actions::SharedValues::GRADLE_ALL_AAB_OUTPUT_PATHS] = ['/path/to/app1.aab', '/path/to/app2.aab']
        lane_context[Fastlane::Actions::SharedValues::GRADLE_AAB_OUTPUT_PATH] = '/path/to/single.aab'
        lane_context[Fastlane::Actions::SharedValues::GRADLE_ALL_APK_OUTPUT_PATHS] = ['/path/to/app.apk']
        lane_context[Fastlane::Actions::SharedValues::GRADLE_APK_OUTPUT_PATH] = '/path/to/single.apk'

        result = described_class.fetch_android_build_path(lane_context)

        expect(result).to eq(['/path/to/app1.aab', '/path/to/app2.aab'])
      end
    end

    context 'when single AAB output path is available' do
      it 'returns single AAB path when all AAB paths are not available' do
        lane_context[Fastlane::Actions::SharedValues::GRADLE_AAB_OUTPUT_PATH] = '/path/to/app.aab'
        lane_context[Fastlane::Actions::SharedValues::GRADLE_ALL_APK_OUTPUT_PATHS] = ['/path/to/app.apk']
        lane_context[Fastlane::Actions::SharedValues::GRADLE_APK_OUTPUT_PATH] = '/path/to/single.apk'

        result = described_class.fetch_android_build_path(lane_context)

        expect(result).to eq('/path/to/app.aab')
      end
    end

    context 'when all APK output paths are available' do
      it 'returns all APK paths when AAB paths are not available' do
        lane_context[Fastlane::Actions::SharedValues::GRADLE_ALL_APK_OUTPUT_PATHS] = ['/path/to/app1.apk', '/path/to/app2.apk']
        lane_context[Fastlane::Actions::SharedValues::GRADLE_APK_OUTPUT_PATH] = '/path/to/single.apk'

        result = described_class.fetch_android_build_path(lane_context)

        expect(result).to eq(['/path/to/app1.apk', '/path/to/app2.apk'])
      end
    end

    context 'when single APK output path is available' do
      it 'returns single APK path when other paths are not available' do
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

    context 'when paths are empty strings' do
      it 'returns nil for empty AAB path' do
        lane_context[Fastlane::Actions::SharedValues::GRADLE_AAB_OUTPUT_PATH] = ''

        result = described_class.fetch_android_build_path(lane_context)

        expect(result).to be_nil
      end

      it 'returns nil for empty APK path' do
        lane_context[Fastlane::Actions::SharedValues::GRADLE_APK_OUTPUT_PATH] = ''

        result = described_class.fetch_android_build_path(lane_context)

        expect(result).to be_nil
      end
    end

    context 'when paths are empty arrays' do
      it 'returns nil for empty all AAB paths' do
        lane_context[Fastlane::Actions::SharedValues::GRADLE_ALL_AAB_OUTPUT_PATHS] = []

        result = described_class.fetch_android_build_path(lane_context)

        expect(result).to be_nil
      end

      it 'returns nil for empty all APK paths' do
        lane_context[Fastlane::Actions::SharedValues::GRADLE_ALL_APK_OUTPUT_PATHS] = []

        result = described_class.fetch_android_build_path(lane_context)

        expect(result).to be_nil
      end
    end
  end

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
              'User-Agent' => 'fastlane-plugin-instabug-stores-upload'
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
