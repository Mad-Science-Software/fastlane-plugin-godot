require 'fastlane/plugin/godot/version'

module Fastlane
  module Godot
    # Return all .rb files inside the "actions" and "helper" directories
    def self.all_classes
      Dir[File.expand_path('**/{actions,helper}/*.rb', File.dirname(__FILE__))]
    end
  end
end

# By default, fastlane loads all actions and helpers of a plugin at once
Fastlane::Godot.all_classes.each do |current|
  require current
end
