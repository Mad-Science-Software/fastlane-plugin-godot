describe Fastlane::Helper::GodotHelper do
  describe '.template_directory_name' do
    it 'maps a release version string to its template directory' do
      expect(described_class.template_directory_name('4.7.1.stable.official.a13da4feb')).to eq('4.7.1.stable')
    end

    it 'handles versions without a patch component' do
      expect(described_class.template_directory_name('4.7.stable.official.deadbeef')).to eq('4.7.stable')
    end

    it 'handles prerelease statuses' do
      expect(described_class.template_directory_name('4.8.beta2.official.cafebabe')).to eq('4.8.beta2')
    end

    it 'rejects garbage' do
      expect { described_class.template_directory_name('not-a-version') }
        .to raise_error(FastlaneCore::Interface::FastlaneError)
    end
  end

  describe '.parse_presets' do
    let(:cfg) do
      file = Tempfile.new('export_presets.cfg')
      file.write(<<~CFG)
        [preset.0]

        name="iOS"
        platform="iOS"
        runnable=true
        export_filter="all_resources"
        export_path="build/ios/Crunch.xcodeproj"

        [preset.0.options]

        application/bundle_identifier="com.example.game"
        export_path="decoy/should_not_be_read"

        [preset.1]

        name="Android"
        platform="Android"
        export_path=""
      CFG
      file.close
      file
    end

    after { cfg.unlink }

    it 'extracts name, platform, and export_path per preset' do
      presets = described_class.parse_presets(cfg.path)
      expect(presets).to eq([
        { name: 'iOS', platform: 'iOS', export_path: 'build/ios/Crunch.xcodeproj' },
        { name: 'Android', platform: 'Android', export_path: '' }
      ])
    end

    it 'ignores option-section keys that shadow preset keys' do
      presets = described_class.parse_presets(cfg.path)
      expect(presets.first[:export_path]).to eq('build/ios/Crunch.xcodeproj')
    end

    it 'errors helpfully when the file is missing' do
      expect { described_class.parse_presets('/nonexistent/export_presets.cfg') }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /create an export preset/)
    end
  end

  describe '.find_preset' do
    it 'errors with the available preset names when not found' do
      file = Tempfile.new('export_presets.cfg')
      file.write("[preset.0]\n\nname=\"iOS\"\nplatform=\"iOS\"\n")
      file.close
      expect { described_class.find_preset(file.path, 'Nope') }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /Available presets: 'iOS' \(iOS\)/)
      file.unlink
    end
  end

  describe '.clear_android_resource_sidecars' do
    it 'removes .import sidecars under the build template resources only' do
      Dir.mktmpdir do |project|
        drawable = File.join(project, 'android', 'build', 'res', 'drawable')
        asset_pack = File.join(project, 'android', 'build', 'assetPackInstallTime', 'src', 'main', 'assets')
        FileUtils.mkdir_p(drawable)
        FileUtils.mkdir_p(asset_pack)
        File.write(File.join(drawable, 'splash_icon.webp'), '')
        File.write(File.join(drawable, 'splash_icon.webp.import'), '')
        File.write(File.join(asset_pack, 'app_icon.png.import'), '')

        expect(described_class.clear_android_resource_sidecars(project)).to eq(1)
        expect(File.exist?(File.join(drawable, 'splash_icon.webp'))).to be(true)
        expect(File.exist?(File.join(drawable, 'splash_icon.webp.import'))).to be(false)
        expect(File.exist?(File.join(asset_pack, 'app_icon.png.import'))).to be(true)
      end
    end

    it 'is a no-op without an Android build template' do
      Dir.mktmpdir do |project|
        expect(described_class.clear_android_resource_sidecars(project)).to eq(0)
      end
    end
  end
end
