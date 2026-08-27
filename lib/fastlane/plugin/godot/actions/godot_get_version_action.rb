require 'fastlane/action'
require_relative '../helper/godot_versions'

module Fastlane
  module Actions
    module SharedValues
      GODOT_VERSION_NAME = :GODOT_VERSION_NAME
      GODOT_VERSION_CODE = :GODOT_VERSION_CODE
    end

    class GodotGetVersionAction < Action
      def self.run(params)
        cfg_path = File.join(File.expand_path(params[:project_path]), 'export_presets.cfg')
        versions = Helper::GodotVersions.read(cfg_path)
        UI.message("Version #{versions[:version_name]} (build #{versions[:version_code]})")
        Actions.lane_context[SharedValues::GODOT_VERSION_NAME] = versions[:version_name]
        Actions.lane_context[SharedValues::GODOT_VERSION_CODE] = versions[:version_code]
        versions
      end

      def self.description
        'Read the version name and build number from export_presets.cfg'
      end

      def self.return_value
        'Hash with :version_name (e.g. "1.2.0") and :version_code (integer build number)'
      end

      def self.authors
        ['Mad Science Software']
      end

      def self.output
        [
          ['GODOT_VERSION_NAME', 'Version name, e.g. "1.2.0"'],
          ['GODOT_VERSION_CODE', 'Build number / version code']
        ]
      end

      def self.available_options
        [
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
