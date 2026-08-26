lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'fastlane/plugin/godot/version'

Gem::Specification.new do |spec|
  spec.name = 'fastlane-plugin-godot'
  spec.version = Fastlane::Godot::VERSION
  spec.authors = ['Mad Science Software']
  spec.email = ['jamesyoungwrites@gmail.com']

  spec.summary = 'Export and ship Godot Engine games with fastlane'
  spec.description = 'Godot-specific fastlane actions: headless engine exports, ' \
                     'export template verification, and Xcode project handling for ' \
                     'shipping Godot games to the app stores.'
  spec.homepage = 'https://github.com/Mad-Science-Software/fastlane-plugin-godot'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1'

  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/releases"

  spec.files = Dir['lib/**/*'] + %w[README.md LICENSE]
  spec.require_paths = ['lib']
end
