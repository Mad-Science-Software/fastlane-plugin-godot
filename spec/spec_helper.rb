$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'tempfile'
require 'tmpdir'

require 'fastlane'
require 'fastlane/plugin/godot'

RSpec.configure do |config|
  config.expect_with(:rspec) { |expectations| expectations.syntax = :expect }
end
