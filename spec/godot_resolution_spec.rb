describe Fastlane::Helper::GodotHelper do
  describe '.project_feature_version' do
    def project_with_features(features_line)
      dir = Dir.mktmpdir
      File.write(File.join(dir, 'project.godot'), <<~GODOT)
        config_version=5

        [application]

        config/name="Game"
        #{features_line}
      GODOT
      dir
    end

    it 'extracts the engine version from config/features' do
      dir = project_with_features('config/features=PackedStringArray("4.7", "GL Compatibility")')
      expect(described_class.project_feature_version(dir)).to eq('4.7')
      FileUtils.remove_entry(dir)
    end

    it 'returns nil when no features are declared' do
      dir = project_with_features('')
      expect(described_class.project_feature_version(dir)).to be_nil
      FileUtils.remove_entry(dir)
    end
  end

  describe '.verify_binary_matches_project!' do
    it 'passes on a matching major.minor' do
      dir = Dir.mktmpdir
      File.write(File.join(dir, 'project.godot'), 'config/features=PackedStringArray("4.7")')
      expect { described_class.verify_binary_matches_project!('4.7.1.stable.official.a13da4feb', dir) }.not_to raise_error
      FileUtils.remove_entry(dir)
    end

    it 'fails loudly on a mismatch, naming both versions' do
      dir = Dir.mktmpdir
      File.write(File.join(dir, 'project.godot'), 'config/features=PackedStringArray("4.6")')
      expect { described_class.verify_binary_matches_project!('4.7.1.stable.official.a13da4feb', dir) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /declares Godot 4\.6.*4\.7\.1\.stable/m)
      FileUtils.remove_entry(dir)
    end

    it 'stays quiet when the project declares nothing' do
      dir = Dir.mktmpdir
      File.write(File.join(dir, 'project.godot'), "config_version=5\n")
      expect { described_class.verify_binary_matches_project!('4.7.1.stable.official.abc', dir) }.not_to raise_error
      FileUtils.remove_entry(dir)
    end
  end

  describe '.template_download_url' do
    it 'builds the official release URL for a stable version' do
      expect(described_class.template_download_url('4.7.1.stable.official.a13da4feb'))
        .to eq('https://github.com/godotengine/godot/releases/download/4.7.1-stable/Godot_v4.7.1-stable_export_templates.tpz')
    end

    it 'refuses prereleases' do
      expect { described_class.template_download_url('4.8.beta2.official.cafebabe') }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /prereleases/)
    end
  end

  describe '.discover_godot_binary' do
    it 'returns an explicit path untouched' do
      expect(described_class.discover_godot_binary('/custom/godot')).to eq('/custom/godot')
    end
  end
end
