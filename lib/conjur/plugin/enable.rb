module Conjur
  module Plugin
    class Enable
      def initialize(
        plugin_install_dir: './plugins/installed',
        plugin_enable_dir: './plugins/enabled'
      )
        @plugin_install_dir = plugin_install_dir
        @plugin_enable_dir = plugin_enable_dir
      end

      def call(
        name:,
        version: nil
      )
        @name = name
        @version = version
        raise "Plugin '#{@name}' is not installed." unless plugin_spec

        # Ensure the enabled directory exists
        FileUtils.mkdir_p(@plugin_enable_dir)

        # TODO: Add check for plugin already enabled (symlink already exists)

        File.symlink(
          plugin_spec_path,
          File.join(@plugin_enable_dir, File.basename(plugin_spec_path))
        )
      end

      def plugin_spec
        @plugin_spec ||= Gem::Specification.load(plugin_spec_path)
      end

      def plugin_spec_path
        # TODO: account for a specific version
        Dir["#{@plugin_install_dir}/specifications/#{@name}-*.gemspec"].first.to_s
      end
    end
  end
end
