describe Fastlane::Actions::GodotInitAction do
  def run_in(dir, icon: true)
    params = FastlaneCore::Configuration.create(
      described_class.available_options,
      { project_path: dir, icon: icon }
    )
    described_class.run(params)
  end

  let(:project) do
    dir = Dir.mktmpdir
    File.write(File.join(dir, 'project.godot'), "config_version=5\n")
    dir
  end

  after { FileUtils.remove_entry(project) }

  it 'refuses to scaffold outside a Godot project' do
    empty = Dir.mktmpdir
    expect { run_in(empty) }.to raise_error(FastlaneCore::Interface::FastlaneError, /No project\.godot/)
    FileUtils.remove_entry(empty)
  end

  it 'creates the full file set in an untouched project' do
    created = run_in(project)
    expect(created).to contain_exactly(
      'Gemfile', 'fastlane/Pluginfile', 'fastlane/Appfile', 'fastlane/Fastfile',
      'fastlane/.env.template', 'export_presets.cfg', 'build/.gdignore',
      'app_icon.png', '.gitignore'
    )
    expect(File.read(File.join(project, 'export_presets.cfg'))).to include('name="iOS"', 'name="Android"')
  end

  it 'writes a valid opaque PNG icon' do
    run_in(project)
    icon = File.binread(File.join(project, 'app_icon.png'))
    expect(icon[0, 8]).to eq("\x89PNG\r\n\x1a\n".b)
    # IHDR: width, height, bit depth 8, color type 2 (RGB, no alpha)
    expect(icon[16, 8].unpack('NN')).to eq([1024, 1024])
    expect(icon[24, 2].unpack('CC')).to eq([8, 2])
  end

  it 'skips the icon when icon: false' do
    created = run_in(project, icon: false)
    expect(created).not_to include('app_icon.png')
  end

  it 'never overwrites existing files' do
    appfile = File.join(project, 'fastlane', 'Appfile')
    FileUtils.mkdir_p(File.dirname(appfile))
    File.write(appfile, "app_identifier('com.real.game')\n")
    File.write(File.join(project, '.gitignore'), "build/\n")

    created = run_in(project)
    expect(created).not_to include('fastlane/Appfile', '.gitignore')
    expect(File.read(appfile)).to eq("app_identifier('com.real.game')\n")
  end

  it 'is idempotent — a second run creates nothing' do
    run_in(project)
    expect(run_in(project)).to be_empty
  end
end
