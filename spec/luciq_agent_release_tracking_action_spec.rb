describe Fastlane::Actions::LuciqAgentReleaseTrackingAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The luciq_agent_release_tracking plugin is working!")

      Fastlane::Actions::LuciqAgentReleaseTrackingAction.run(nil)
    end
  end
end
