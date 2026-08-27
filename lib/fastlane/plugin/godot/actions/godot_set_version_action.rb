require 'fastlane/action'
require_relative '../helper/godot_versions'
require_relative 'godot_get_version_action'

module Fastlane
  module Actions
    class GodotSetVersionAction < Action
      def self.run(params)
        project_path = File.expand_path(params[:project_path])
        cfg_path = File.join(project_path, 'export_presets.cfg')

        if params[:from_git]
          UI.user_error!('Pass either from_git or version/build_number, not both') if params[:version] || params[:build_number]
          target = Helper::GodotVersions.from_git(project_path)
        else
          UI.user_error!('Nothing to do — pass version:, build_number:, or from_git: true') unless params[:version] || params[:build_number]
          current = Helper::GodotVersions.read(cfg_path)
          target = { version_name: nil, version_code: nil }
          if (requested = params[:version])
            target[:version_name] =
              if %w[major minor patch].include?(requested)
                Helper::GodotVersions.bump(current[:version_name], requested)
              elsif requested.match?(/\A\d+\.\d+(\.\d+)?\z/)
                requested
              else
                UI.user_error!("version must be X.Y[.Z] or major/minor/patch, got '#{requested}'")
              end
          end
          if (requested = params[:build_number])
            target[:version_code] =
              if requested == 'increment'
                (current[:version_code] || 0) + 1
              elsif requested.match?(/\A\d+\z/)
                requested.to_i
              else
                UI.user_error!("build_number must be an integer or 'increment', got '#{requested}'")
              end
          end
        end

        Helper::GodotVersions.write(cfg_path, version_name: target[:version_name], version_code: target[:version_code])
        applied = Helper::GodotVersions.read(cfg_path)
        UI.success("Version is now #{applied[:version_name]} (build #{applied[:version_code]})")
        Actions.lane_context[SharedValues::GODOT_VERSION_NAME] = applied[:version_name]
        Actions.lane_context[SharedValues::GODOT_VERSION_CODE] = applied[:version_code]
        applied
      end

      def self.description
        'Write the version name and build number into every preset in export_presets.cfg, keeping platforms in sync'
      end

      def self.return_value
        'Hash with the applied :version_name and :version_code'
      end

      def self.authors
        ['Mad Science Software']
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :version,
                                       env_name: 'FL_GODOT_VERSION',
                                       description: "Explicit version ('1.2.0') or a semantic bump: major, minor, patch",
                                       type: String,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :build_number,
                                       env_name: 'FL_GODOT_BUILD_NUMBER',
                                       description: "Explicit build number or 'increment'",
                                       type: String,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :from_git,
                                       env_name: 'FL_GODOT_VERSION_FROM_GIT',
                                       description: 'Derive version from the latest git tag (v1.2.0 -> 1.2.0) and build number from the commit count',
                                       type: Boolean,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :project_path,
                                       env_name: 'FL_GODOT_PROJECT_PATH',
                                       description: 'Directory containing project.godot',
                                       type: String,
                                       default_value: '.')
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
