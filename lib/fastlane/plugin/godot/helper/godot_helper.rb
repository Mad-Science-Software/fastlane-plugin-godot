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

      # The template archive each platform's export requires, keyed by the
      # platform string Godot writes into export_presets.cfg.
      PLATFORM_TEMPLATE_FILES = {
        'iOS' => ['ios.zip'],
        'Android' => ['android_debug.apk', 'android_release.apk', 'android_source.zip'],
        'macOS' => ['macos.zip'],
        'Web' => ['web_release.zip', 'web_debug.zip']
      }.freeze

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
