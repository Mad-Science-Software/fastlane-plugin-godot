describe Fastlane::Actions::GodotExportAction do
  describe 'metadata' do
    it 'declares a description' do
      expect(described_class.description).to match(/Export a Godot project/)
    end

    it 'supports every lane platform (the Godot preset decides the target)' do
      expect(described_class.is_supported?(:ios)).to be(true)
      expect(described_class.is_supported?(:android)).to be(true)
    end

    it 'requires only the preset option' do
      required = described_class.available_options.reject(&:optional).reject { |o| o.default_value || o.default_value == false }
      expect(required.map(&:key)).to eq([:preset])
    end

    it 'defaults the Android build template flag off' do
      option = described_class.available_options.find { |o| o.key == :install_android_build_template }
      expect(option.default_value).to be(false)
    end
  end

  describe '#run' do
    it 'fails fast when there is no project.godot' do
      params = FastlaneCore::Configuration.create(
        described_class.available_options,
        { preset: 'iOS', project_path: Dir.mktmpdir }
      )
      expect { described_class.run(params) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /No project\.godot/)
    end
  end
end
