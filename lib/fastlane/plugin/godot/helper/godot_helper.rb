require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?(:UI)

  module Helper
    class GodotHelper
      # Full version string, e.g. "4.7.1.stable.official.a13da4feb"
      def self.godot_version(godot_binary)
        output = `#{godot_binary.shellescape} --version 2>/dev/null`.strip
        UI.user_error!("Could not run '#{godot_binary} --version' — is Godot installed and on the PATH?") if output.empty?
        output.lines.last.strip
      end

      # Export templates live in a directory named after the version's
      # release segment: "4.7.1.stable.official.a13da4feb" -> "4.7.1.stable"
      def self.template_directory_name(version_string)
        match = version_string.match(/^(\d+\.\d+(?:\.\d+)?\.[a-z0-9]+)/)
        UI.user_error!("Unrecognized Godot version string: '#{version_string}'") unless match
        match[1]
      end

      def self.templates_root
        if FastlaneCore::Helper.mac?
          File.expand_path('~/Library/Application Support/Godot/export_templates')
        else
          File.expand_path('~/.local/share/godot/export_templates')
        end
      end

      # Minimal parse of export_presets.cfg: the preset headers plus the
      # name/platform/export_path lines that follow each one.
      def self.parse_presets(cfg_path)
        UI.user_error!("No export_presets.cfg found at #{cfg_path} — create an export preset first (Project > Export in the Godot editor, or commit one)") unless File.exist?(cfg_path)

        presets = []
        current = nil
        File.foreach(cfg_path) do |line|
          case line
          when /^\[preset\.\d+\]\s*$/
            current = {}
            presets << current
          when /^\[preset\.\d+\.options\]\s*$/
            current = nil
          when /^name="(.*)"\s*$/
            current[:name] = Regexp.last_match(1) if current
          when /^platform="(.*)"\s*$/
            current[:platform] = Regexp.last_match(1) if current
          when /^export_path="(.*)"\s*$/
            current[:export_path] = Regexp.last_match(1) if current
          end
        end
        presets
      end

      def self.find_preset(cfg_path, preset_name)
        presets = parse_presets(cfg_path)
        preset = presets.find { |p| p[:name] == preset_name }
        unless preset
          available = presets.map { |p| "'#{p[:name]}' (#{p[:platform]})" }.join(', ')
          UI.user_error!("No export preset named '#{preset_name}' in #{cfg_path}. Available presets: #{available.empty? ? 'none' : available}")
        end
        preset
      end

      # Godot 4.7 installs the Android Gradle build template with no
      # .gdignore in android/ (and the install wipes android/, so one
      # placed there doesn't survive). Any editor or --import pass after
      # that writes *.import sidecars next to the template's drawables,
      # and Gradle's resource merger rejects them ("The file name must end
      # with .xml or .png"). Only res/ is affected — the export itself
      # legitimately packs the game's own sidecars into the asset-pack
      # directories. Returns how many were removed.
      def self.clear_android_resource_sidecars(project_path)
        sidecars = Dir.glob(File.join(project_path, 'android', 'build', 'res', '**', '*.import'))
        sidecars.each { |path| File.delete(path) }
        sidecars.size
      end

      # The template archive each platform's export requires, keyed by the
      # platform string Godot writes into export_presets.cfg.
      PLATFORM_TEMPLATE_FILES = {
        'iOS' => ['ios.zip'],
        'Android' => ['android_debug.apk', 'android_release.apk', 'android_source.zip'],
        'macOS' => ['macos.zip'],
        'Web' => ['web_release.zip', 'web_debug.zip']
      }.freeze

      # The engine version a project declares, e.g. "4.7" from
      # config/features=PackedStringArray("4.7", "GL Compatibility")
      def self.project_feature_version(project_path)
        project_file = File.join(project_path, 'project.godot')
        return nil unless File.exist?(project_file)
        File.foreach(project_file) do |line|
          match = line.match(/^config\/features=PackedStringArray\((.*)\)/)
          next unless match
          feature = match[1].scan(/"([^"]+)"/).flatten.find { |f| f.match?(/\A\d+\.\d+\z/) }
          return feature
        end
        nil
      end

      def self.verify_binary_matches_project!(version_string, project_path)
        declared = project_feature_version(project_path)
        return if declared.nil?
        binary_minor = version_string.split('.')[0, 2].join('.')
        return if binary_minor == declared
        UI.user_error!(
          "This project declares Godot #{declared} (config/features in project.godot) " \
          "but the resolved binary is #{template_directory_name(version_string)}. " \
          'Exporting across engine versions corrupts import caches and breaks scenes. ' \
          "Point godot_binary at a Godot #{declared} install, or pass skip_version_check: true if you know what you are doing"
        )
      end

      # Where the godot binary lives when it isn't simply on the PATH.
      COMMON_BINARY_LOCATIONS = [
        '/Applications/Godot.app/Contents/MacOS/Godot',
        '/opt/homebrew/bin/godot',
        '/usr/local/bin/godot',
        '/usr/bin/godot'
      ].freeze

      def self.discover_godot_binary(configured)
        return configured unless configured == 'godot'
        return configured unless `which godot 2>/dev/null`.strip.empty?
        found = ENV['GODOT'] || COMMON_BINARY_LOCATIONS.find { |path| File.executable?(path) }
        UI.user_error!("Could not find a Godot binary — none on the PATH, no GODOT environment variable, and nothing at: #{COMMON_BINARY_LOCATIONS.join(', ')}") unless found
        UI.message("Using Godot binary at #{found}")
        found
      end

      # Official export-templates archive for a stable version string.
      def self.template_download_url(version_string)
        release = template_directory_name(version_string)
        UI.user_error!("Only stable releases have predictable template downloads (got '#{release}') — install templates for prereleases manually") unless release.end_with?('.stable')
        base = release.sub(/\.stable\z/, '')
        "https://github.com/godotengine/godot/releases/download/#{base}-stable/Godot_v#{base}-stable_export_templates.tpz"
      end

      def self.verify_templates!(version_string, platform)
        dir = File.join(templates_root, template_directory_name(version_string))
        needed = PLATFORM_TEMPLATE_FILES[platform]
        return if needed.nil? # platform we don't know how to check — let Godot decide

        missing = needed.reject { |f| File.exist?(File.join(dir, f)) }
        return if missing.empty?

        UI.user_error!(
          "Godot #{template_directory_name(version_string)} export templates for #{platform} " \
          "are missing (#{missing.join(', ')} not found in #{dir}). " \
          'Download the templates bundle from https://godotengine.org/download and install it, ' \
          "or unzip the needed files from the .tpz archive into #{dir}"
        )
      end
    end
  end
end
