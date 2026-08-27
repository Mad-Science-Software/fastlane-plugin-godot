require 'zlib'

module Fastlane
  module Helper
    # File templates for godot_init. Placeholder values are ALL-CAPS or
    # com.example so nothing accidentally ships as-is.
    class GodotScaffold
      GEMFILE = <<~RUBY.freeze
        source 'https://rubygems.org'

        gem 'fastlane'

        plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
        eval_gemfile(plugins_path) if File.exist?(plugins_path)
      RUBY

      PLUGINFILE = <<~RUBY.freeze
        gem 'fastlane-plugin-godot'
      RUBY

      APPFILE = <<~RUBY.freeze
        # Your game's bundle identifier (must match the export preset).
        app_identifier('com.example.mygame')

        # Your 10-character Apple Developer team ID.
        team_id('YOURTEAMID')
      RUBY

      FASTFILE = <<~RUBY.freeze
        default_platform(:ios)

        platform :ios do
          desc 'Export from Godot and build a signed .ipa'
          lane :build do
            app_store_connect_api_key(
              key_id: ENV.fetch('ASC_KEY_ID'),
              issuer_id: ENV.fetch('ASC_ISSUER_ID'),
              key_filepath: File.expand_path(ENV.fetch('ASC_KEY_PATH'))
            )

            xcodeproj = godot_export(preset: 'iOS')

            # Reuse-or-create the distribution certificate and App Store
            # profile; classic (non-cloud) signing works with an App Manager
            # App Store Connect API key.
            get_certificates
            get_provisioning_profile

            build_app(
              project: xcodeproj,
              scheme: File.basename(xcodeproj, '.xcodeproj'),
              output_directory: 'build/ios',
              export_method: 'app-store',
              export_options: {
                signingStyle: 'manual',
                signingCertificate: 'Apple Distribution',
                provisioningProfiles: {
                  CredentialsManager::AppfileConfig.try_fetch_value(:app_identifier) =>
                    lane_context[SharedValues::SIGH_NAME]
                }
              },
              # Works around godotengine/godot#110052 (Godot writes a
              # distribution identity into an automatic-signing config).
              xcargs: 'CODE_SIGN_IDENTITY="Apple Development" -allowProvisioningUpdates'
            )
          end

          desc 'Build and upload to TestFlight'
          lane :beta do
            build
            upload_to_testflight
          end
        end

        platform :android do
          desc 'Export a debug-signed APK'
          lane :build do
            godot_export(preset: 'Android', debug: true)
          end
        end
      RUBY

      ENV_TEMPLATE = <<~TEXT.freeze
        # Copy to fastlane/.env and fill in — fastlane loads it automatically.
        # Never commit the real .env; commit only this template.
        ASC_KEY_ID=ABC123DEFG
        ASC_ISSUER_ID=12345678-1234-1234-1234-123456789012
        ASC_KEY_PATH=~/.appstoreconnect/AuthKey_ABC123DEFG.p8
      TEXT

      GITIGNORE = <<~TEXT.freeze
        # fastlane: local credentials and build products
        fastlane/.env
        fastlane/report.xml
        build/
        vendor/
        .bundle/
      TEXT

      GITIGNORE_ENTRIES = ['fastlane/.env', 'fastlane/report.xml', 'build/'].freeze

      EXPORT_PRESETS = <<~TEXT.freeze
        [preset.0]

        name="iOS"
        platform="iOS"
        runnable=true
        dedicated_server=false
        custom_features=""
        export_filter="all_resources"
        include_filter=""
        exclude_filter=""
        export_path="build/ios/Game.xcodeproj"
        script_export_mode=2

        [preset.0.options]

        application/app_store_team_id="YOURTEAMID"
        application/bundle_identifier="com.example.mygame"
        application/short_version="0.1.0"
        application/version="1"
        application/min_ios_version="15.0"
        application/export_project_only=true
        icons/icon_1024x1024="res://app_icon.png"
        orientation/portrait=true
        orientation/upside_down=false
        orientation/landscape_left=false
        orientation/landscape_right=false

        [preset.1]

        name="Android"
        platform="Android"
        runnable=true
        dedicated_server=false
        custom_features=""
        export_filter="all_resources"
        include_filter=""
        exclude_filter=""
        export_path="build/android/Game.apk"
        script_export_mode=2

        [preset.1.options]

        gradle_build/use_gradle_build=false
        architectures/arm64-v8a=true
        version/code=1
        version/name="0.1.0"
        package/unique_name="com.example.mygame"
        package/name=""
        package/signed=true
        launcher_icons/main_192x192="res://app_icon.png"
        screen/immersive_mode=true
      TEXT

      # Minimal valid 1024x1024 opaque PNG (Apple rejects alpha in the
      # marketing icon): flat two-tone placeholder, obviously temporary.
      def self.placeholder_icon_png(size = 1024)
        background = [40, 90, 100].pack('C3')
        foreground = [235, 180, 70].pack('C3')
        low = size / 4
        high = 3 * size / 4
        raw = +''.b
        size.times do |y|
          raw << "\x00".b
          size.times do |x|
            raw << (x >= low && x < high && y >= low && y < high ? foreground : background)
          end
        end
        chunk = lambda do |tag, data|
          [data.bytesize].pack('N') + tag + data + [Zlib.crc32(tag + data)].pack('N')
        end
        header = [size, size, 8, 2, 0, 0, 0].pack('NNC5')
        "\x89PNG\r\n\x1a\n".b +
          chunk.call('IHDR'.b, header) +
          chunk.call('IDAT'.b, Zlib::Deflate.deflate(raw, Zlib::BEST_COMPRESSION)) +
          chunk.call('IEND'.b, ''.b)
      end
    end
  end
end
