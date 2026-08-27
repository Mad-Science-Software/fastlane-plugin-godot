require 'fastlane/action'
require_relative '../helper/godot_scaffold'

module Fastlane
  module Actions
    class GodotInitAction < Action
      def self.run(params)
        project_path = File.expand_path(params[:project_path])
        UI.user_error!("No project.godot in #{project_path} — run this from (or point project_path at) a Godot project") unless File.exist?(File.join(project_path, 'project.godot'))

        created = []
        skipped = []
        write = lambda do |relative_path, content, binary: false|
          target = File.join(project_path, relative_path)
          if File.exist?(target)
            skipped << relative_path
          else
            FileUtils.mkdir_p(File.dirname(target))
            binary ? File.binwrite(target, content) : File.write(target, content)
            created << relative_path
          end
        end

        scaffold = Helper::GodotScaffold
        write.call('Gemfile', scaffold::GEMFILE)
        write.call('fastlane/Pluginfile', scaffold::PLUGINFILE)
        write.call('fastlane/Appfile', scaffold::APPFILE)
        write.call('fastlane/Fastfile', scaffold::FASTFILE)
        write.call('fastlane/.env.template', scaffold::ENV_TEMPLATE)
        write.call('export_presets.cfg', scaffold::EXPORT_PRESETS)
        write.call('build/.gdignore', '')
        # Bundler's common `path vendor/bundle` setup would otherwise get the
        # fastlane gems imported and PACKED INTO THE GAME.
        write.call('vendor/.gdignore', '')
        write.call('.bundle/.gdignore', '')
        write.call('app_icon.png', scaffold.placeholder_icon_png, binary: true) if params[:icon]

        if Helper::GodotScaffold.ensure_etc2_astc!(project_path)
          created << 'project.godot (enabled textures/vram_compression/import_etc2_astc — required for Android export)'
        end

        gitignore = File.join(project_path, '.gitignore')
        if File.exist?(gitignore)
          existing = File.read(gitignore)
          missing = scaffold::GITIGNORE_ENTRIES.reject { |entry| existing.include?(entry) }
          UI.important("Your .gitignore is missing: #{missing.join(', ')} — add them so credentials and build products stay out of git") unless missing.empty?
          skipped << '.gitignore'
        else
          write.call('.gitignore', scaffold::GITIGNORE)
        end

        created.each { |path| UI.success("created #{path}") }
        skipped.each { |path| UI.message("kept existing #{path}") }

        unless created.empty?
          UI.important('Placeholders to fill in before building:')
          UI.important('  - fastlane/Appfile: bundle identifier and team ID')
          UI.important('  - export_presets.cfg: bundle identifier, team ID, export_path names')
          UI.important('  - copy fastlane/.env.template to fastlane/.env and add your App Store Connect API key')
          UI.important('  - app_icon.png is an obvious placeholder — replace it before shipping') if params[:icon]
        end
        created
      end

      def self.description
        'Scaffold the files a Godot project needs for fastlane mobile releases (never overwrites existing files)'
      end

      def self.return_value
        'Array of relative paths that were created'
      end

      def self.authors
        ['Mad Science Software']
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :project_path,
                                       env_name: 'FL_GODOT_PROJECT_PATH',
                                       description: 'Directory containing project.godot',
                                       type: String,
                                       default_value: '.'),
          FastlaneCore::ConfigItem.new(key: :icon,
                                       env_name: 'FL_GODOT_INIT_ICON',
                                       description: 'Also create a placeholder 1024x1024 app_icon.png (iOS export fails without an icon)',
                                       type: Boolean,
                                       default_value: true)
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
