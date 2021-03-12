module Conjur
  module Plugin
    class Uninstall

      def initialize(
        plugin_install_dir: './plugins/installed',
        plugin_enable_dir: './plugins/enabled',
        disable_plugin_cls: Disable
      )
        @plugin_install_dir = plugin_install_dir
        @plugin_enable_dir = plugin_enable_dir
        @disable_plugin_cls = disable_plugin_cls
      end

      def call(name:, version: nil)
        @version = version

        # Ensure the plugin is disabled
        @disable_plugin_cls.new(
          plugin_enable_dir: @plugin_enable_dir
        ).call(
          name: name,
          version: @version,
          force: true
        )

        # TODO: Need to run this with `GEM_HOME` env variable set
        `gem uninstall '#{name}'#{version_argument} --install-dir '#{@plugin_install_dir}'`
      end

      def version_argument
        return nil unless @version

        " -v '#{@version}'"
      end
    end
  end
end
