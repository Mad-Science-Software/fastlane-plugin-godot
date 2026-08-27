describe Fastlane::Helper::GodotVersions do
  let(:cfg) do
    file = Tempfile.new('export_presets.cfg')
    file.write(<<~CFG)
      [preset.0]

      name="iOS"
      platform="iOS"
      export_path="build/ios/Game.xcodeproj"

      [preset.0.options]

      application/short_version="0.1.0"
      application/version="1"
      application/min_ios_version="15.0"

      [preset.1]

      name="Android"
      platform="Android"

      [preset.1.options]

      version/code=1
      version/name="0.1.0"
    CFG
    file.close
    file
  end

  after { cfg.unlink }

  describe '.read' do
    it 'reads name and code from the presets' do
      expect(described_class.read(cfg.path)).to eq(version_name: '0.1.0', version_code: 1)
    end

    it 'errors on a file with no version keys' do
      bare = Tempfile.new('bare.cfg')
      bare.write("[preset.0]\n\nname=\"iOS\"\n")
      bare.close
      expect { described_class.read(bare.path) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /No version keys/)
      bare.unlink
    end
  end

  describe '.write' do
    it 'updates all version keys across presets, preserving quoting style' do
      changed = described_class.write(cfg.path, version_name: '1.2.0', version_code: 7)
      expect(changed).to eq(4)
      content = File.read(cfg.path)
      expect(content).to include('application/short_version="1.2.0"')
      expect(content).to include('application/version="7"')
      expect(content).to include('version/name="1.2.0"')
      expect(content).to include("version/code=7\n")
      expect(content).to include('application/min_ios_version="15.0"')
    end

    it 'can update only the build number' do
      described_class.write(cfg.path, version_code: 9)
      expect(described_class.read(cfg.path)).to eq(version_name: '0.1.0', version_code: 9)
    end
  end

  describe '.bump' do
    it { expect(described_class.bump('0.1.0', 'patch')).to eq('0.1.1') }
    it { expect(described_class.bump('0.1.5', 'minor')).to eq('0.2.0') }
    it { expect(described_class.bump('1.2.3', 'major')).to eq('2.0.0') }
    it { expect(described_class.bump('1.2', 'patch')).to eq('1.2.1') }
  end

  describe '.from_git' do
    it 'names the real problem when outside a git repository' do
      dir = Dir.mktmpdir
      expect { described_class.from_git(dir) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /needs a git repository/)
      FileUtils.remove_entry(dir)
    end

    it 'derives version from the latest tag and build from the commit count' do
      dir = Dir.mktmpdir
      system('git', 'init', '-q', dir)
      system('git', '-C', dir, 'config', 'user.email', 'test@example.com')
      system('git', '-C', dir, 'config', 'user.name', 'Test')
      File.write(File.join(dir, 'a'), '1')
      system('git', '-C', dir, 'add', '.')
      system('git', '-C', dir, 'commit', '-qm', 'one')
      system('git', '-C', dir, 'tag', 'v1.4.0')
      File.write(File.join(dir, 'b'), '2')
      system('git', '-C', dir, 'add', '.')
      system('git', '-C', dir, 'commit', '-qm', 'two')

      expect(described_class.from_git(dir)).to eq(version_name: '1.4.0', version_code: 2)
      FileUtils.remove_entry(dir)
    end
  end
end

describe Fastlane::Actions::GodotSetVersionAction do
  def project_with_presets
    dir = Dir.mktmpdir
    File.write(File.join(dir, 'project.godot'), "config_version=5\n")
    File.write(File.join(dir, 'export_presets.cfg'), <<~CFG)
      [preset.0]

      name="iOS"
      platform="iOS"

      [preset.0.options]

      application/short_version="0.1.0"
      application/version="1"
    CFG
    dir
  end

  def run_set(dir, args)
    params = FastlaneCore::Configuration.create(
      described_class.available_options,
      { project_path: dir }.merge(args)
    )
    described_class.run(params)
  end

  it 'applies a semantic bump and increments the build' do
    dir = project_with_presets
    result = run_set(dir, version: 'minor', build_number: 'increment')
    expect(result).to eq(version_name: '0.2.0', version_code: 2)
    FileUtils.remove_entry(dir)
  end

  it 'rejects garbage versions' do
    dir = project_with_presets
    expect { run_set(dir, version: 'huge') }
      .to raise_error(FastlaneCore::Interface::FastlaneError, /major\/minor\/patch/)
    FileUtils.remove_entry(dir)
  end

  it 'requires something to do' do
    dir = project_with_presets
    expect { run_set(dir, {}) }
      .to raise_error(FastlaneCore::Interface::FastlaneError, /Nothing to do/)
    FileUtils.remove_entry(dir)
  end

  it 'rejects from_git combined with explicit values' do
    dir = project_with_presets
    expect { run_set(dir, from_git: true, version: '1.0.0') }
      .to raise_error(FastlaneCore::Interface::FastlaneError, /not both/)
    FileUtils.remove_entry(dir)
  end
end
