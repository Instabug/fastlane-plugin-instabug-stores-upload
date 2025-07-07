describe Fastlane::Actions::InstabugStoresUploadAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The instabug-stores-upload plugin is working!")

      Fastlane::Actions::InstabugStoresUploadAction.run(nil)
    end
  end
end
