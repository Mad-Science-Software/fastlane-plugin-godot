require 'fastlane/action'
require 'shellwords'
require_relative '../helper/godot_helper'

module Fastlane
  module Actions
    class GodotInstallTemplatesAction < Action
      def self.run(params)
        godot = Helper::GodotHelper.discover_godot_binary(params[:godot_binary])
        version = Helper::GodotHelper.godot_version(godot)
        release = Helper::GodotHelper.template_directory_name(version)
        target_dir = File.join(Helper::GodotHelper.templates_root, release)

        wanted = params[:platform] == 'all' ? Helper::GodotHelper::PLATFORM_TEMPLATE_FILES.values.flatten : Helper::GodotHelper::PLATFORM_TEMPLATE_FILES[params[:platform]]
        UI.user_error!("Unknown platform '#{params[:platform]}' — use one of: #{Helper::GodotHelper::PLATFORM_TEMPLATE_FILES.keys.join(', ')}, all") if wanted.nil?

        missing = wanted.reject { |f| File.exist?(File.join(target_dir, f)) }
        missing = wanted if params[:force]
        if missing.empty?
          UI.success("Export templates for #{params[:platform]} (#{release}) already installed")
          return target_dir
        end

        url = Helper::GodotHelper.template_download_url(version)
        archive = File.join(Dir.mktmpdir('godot-templates'), 'templates.tpz')
        UI.message("Downloading #{url} (the full bundle is large — one-time per engine version)")
        Actions.sh("curl -fL --progress-bar -o #{archive.shellescape} #{url.shellescape}", log: false)

        FileUtils.mkdir_p(target_dir)
        extract_dir = File.join(File.dirname(archive), 'extracted')
        members = missing.map { |f| "templates/#{f}".shellescape }.join(' ')
        Actions.sh("unzip -o -q #{archive.shellescape} #{members} -d #{extract_dir.shellescape}", log: false)
        missing.each do |file|
          FileUtils.mv(File.join(extract_dir, 'templates', file), File.join(target_dir, file))
          UI.success("installed #{file}")
        end
        FileUtils.rm_rf(File.dirname(archive))
        target_dir
      end

      def self.description
        "Download and install the export templates matching the Godot binary's version, for one platform or all"
      end

      def self.return_value
        'Path to the version-specific export-templates directory'
      end

      def self.authors
        ['Mad Science Software']
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :platform,
                                       env_name: 'FL_GODOT_TEMPLATE_PLATFORM',
                                       description: "Which platform's templates to install: iOS, Android, macOS, Web, or all",
                                       type: String,
                                       default_value: 'all'),
          FastlaneCore::ConfigItem.new(key: :godot_binary,
                                       env_name: 'FL_GODOT_BINARY',
                                       description: 'Path to the Godot binary',
                                       type: String,
                                       default_value: 'godot'),
          FastlaneCore::ConfigItem.new(key: :force,
                                       env_name: 'FL_GODOT_TEMPLATE_FORCE',
                                       description: 'Reinstall even when already present',
                                       type: Boolean,
                                       default_value: false)
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
