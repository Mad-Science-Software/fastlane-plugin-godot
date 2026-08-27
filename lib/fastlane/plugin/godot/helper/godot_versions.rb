require 'fastlane_core/ui/ui'

module Fastlane
  module Helper
    # Read/write version numbers in export_presets.cfg. Godot stores them
    # per-preset under platform-specific keys:
    #   iOS:     application/short_version (name), application/version (code)
    #   Android: version/name (name), version/code (code)
    class GodotVersions
      VERSION_NAME_KEYS = ['application/short_version', 'version/name'].freeze
      VERSION_CODE_KEYS = ['application/version', 'version/code'].freeze

      def self.read(cfg_path)
        UI.user_error!("No export_presets.cfg at #{cfg_path}") unless File.exist?(cfg_path)
        names = []
        codes = []
        File.foreach(cfg_path) do |line|
          key, value = split_assignment(line)
          next unless key
          names << value if VERSION_NAME_KEYS.include?(key)
          codes << value if VERSION_CODE_KEYS.include?(key)
        end
        UI.user_error!("No version keys found in #{cfg_path} — add application/short_version + application/version (iOS) or version/name + version/code (Android) to a preset") if names.empty? && codes.empty?
        warn_on_mismatch('version name', names)
        warn_on_mismatch('build number', codes)
        { version_name: names.first, version_code: codes.first&.to_i }
      end

      # Writes the given values into every preset that has the keys, keeping
      # platforms in sync. Returns the number of lines changed.
      def self.write(cfg_path, version_name: nil, version_code: nil)
        UI.user_error!("No export_presets.cfg at #{cfg_path}") unless File.exist?(cfg_path)
        changed = 0
        rewritten = File.foreach(cfg_path).map do |line|
          key, = split_assignment(line)
          if version_name && VERSION_NAME_KEYS.include?(key)
            changed += 1
            "#{key}=\"#{version_name}\"\n"
          elsif version_code && VERSION_CODE_KEYS.include?(key)
            changed += 1
            quoted = key.start_with?('application/') ? "\"#{version_code}\"" : version_code.to_s
            "#{key}=#{quoted}\n"
          else
            line
          end
        end
        UI.user_error!("No version keys found to update in #{cfg_path}") if changed.zero?
        File.write(cfg_path, rewritten.join)
        changed
      end

      def self.bump(current, part)
        UI.user_error!('Cannot bump: no current version name in any preset') if current.nil? || current.empty?
        segments = current.split('.').map(&:to_i)
        segments += [0] * (3 - segments.length) if segments.length < 3
        case part
        when 'major' then [segments[0] + 1, 0, 0]
        when 'minor' then [segments[0], segments[1] + 1, 0]
        when 'patch' then [segments[0], segments[1], segments[2] + 1]
        else UI.user_error!("Unknown bump '#{part}' — use major, minor, or patch")
        end.join('.')
      end

      def self.from_git(project_path)
        tag = `git -C #{project_path.shellescape} describe --tags --abbrev=0 2>/dev/null`.strip
        UI.user_error!('git-derived versioning needs at least one tag (e.g. v1.0.0)') if tag.empty?
        commit_count = `git -C #{project_path.shellescape} rev-list --count HEAD 2>/dev/null`.strip
        UI.user_error!('Could not count commits — is this a git repository?') if commit_count.empty?
        { version_name: tag.sub(/\Av/, ''), version_code: commit_count.to_i }
      end

      def self.split_assignment(line)
        match = line.match(/^([a-z_\/]+)="?([^"\n]*)"?\s*$/)
        match ? [match[1], match[2]] : nil
      end
      private_class_method :split_assignment

      def self.warn_on_mismatch(label, values)
        UI.important("Presets disagree on #{label} (#{values.uniq.join(' vs ')}) — godot_set_version will re-sync them") if values.uniq.length > 1
      end
      private_class_method :warn_on_mismatch
    end
  end
end
