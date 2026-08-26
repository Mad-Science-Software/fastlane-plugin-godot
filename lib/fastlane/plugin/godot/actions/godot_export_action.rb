require 'fastlane/action'
require 'shellwords'
require_relative '../helper/godot_helper'

module Fastlane
  module Actions
    class GodotExportAction < Action
      def self.run(params)
        godot = params[:godot_binary]
        project_path = File.expand_path(params[:project_path])
        preset_name = params[:preset]

        UI.user_error!("No project.godot in #{project_path}") unless File.exist?(File.join(project_path, 'project.godot'))

        version = Helper::GodotHelper.godot_version(godot)
        UI.message("Godot #{version}")

        cfg_path = File.join(project_path, 'export_presets.cfg')
        preset = Helper::GodotHelper.find_preset(cfg_path, preset_name)
        Helper::GodotHelper.verify_templates!(version, preset[:platform])

        output_path = params[:output_path] || preset[:export_path]
        UI.user_error!("Preset '#{preset_name}' has no export_path and no output_path was given") if output_path.nil? || output_path.empty?
        absolute_output = File.expand_path(output_path, project_path)
        FileUtils.mkdir_p(File.dirname(absolute_output))

        if params[:import_first]
          UI.message('Importing project resources (stale import caches abort exports)…')
          Actions.sh("#{godot.shellescape} --headless --path #{project_path.shellescape} --import")
        end

        export_flag = params[:debug] ? '--export-debug' : '--export-release'
        command = [
          godot.shellescape,
          '--headless',
          '--path', project_path.shellescape,
          export_flag, preset_name.shellescape,
          absolute_output.shellescape
        ]
        command << '--verbose' if params[:verbose]

        UI.message("Exporting preset '#{preset_name}' (#{preset[:platform]}) -> #{absolute_output}")
        Actions.sh(command.join(' '))

        # Godot has historically exited 0 on some export failures; trust the artifact, not the exit code.
        UI.user_error!("Export claimed success but produced nothing at #{absolute_output}") unless File.exist?(absolute_output)

        UI.success("Exported #{preset[:platform]} build: #{absolute_output}")
        Actions.lane_context[SharedValues::GODOT_EXPORT_OUTPUT] = absolute_output
        absolute_output
      end

      def self.description
        'Export a Godot project headlessly using an export preset'
      end

      def self.return_value
        'Absolute path to the exported artifact (for iOS, the generated Xcode project)'
      end

      def self.authors
        ['Mad Science Software']
      end

      def self.output
        [['GODOT_EXPORT_OUTPUT', 'Absolute path to the exported artifact']]
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :preset,
                                       env_name: 'FL_GODOT_PRESET',
                                       description: 'Name of the export preset in export_presets.cfg',
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :project_path,
                                       env_name: 'FL_GODOT_PROJECT_PATH',
                                       description: 'Directory containing project.godot',
                                       type: String,
                                       default_value: '.'),
          FastlaneCore::ConfigItem.new(key: :godot_binary,
                                       env_name: 'FL_GODOT_BINARY',
                                       description: 'Path to the Godot binary',
                                       type: String,
                                       default_value: 'godot'),
          FastlaneCore::ConfigItem.new(key: :output_path,
                                       env_name: 'FL_GODOT_OUTPUT_PATH',
                                       description: 'Where to write the exported artifact (defaults to the preset export_path), relative to the project',
                                       type: String,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :debug,
                                       env_name: 'FL_GODOT_DEBUG',
                                       description: 'Export a debug build instead of a release build',
                                       type: Boolean,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :import_first,
                                       env_name: 'FL_GODOT_IMPORT_FIRST',
                                       description: 'Run a headless --import before exporting (a stale import cache aborts exports)',
                                       type: Boolean,
                                       default_value: true),
          FastlaneCore::ConfigItem.new(key: :verbose,
                                       env_name: 'FL_GODOT_VERBOSE',
                                       description: 'Pass --verbose to Godot',
                                       type: Boolean,
                                       default_value: false)
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end

  module Actions
    module SharedValues
      GODOT_EXPORT_OUTPUT = :GODOT_EXPORT_OUTPUT
    end
  end
end
