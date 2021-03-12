module Conjur
  module Plugin
    class Install

      def initialize(plugin_install_dir: './plugins/installed')
        @plugin_install_dir = plugin_install_dir
      end

      def call(name:, version: nil)
        @version = version
        # Ensure parent directory exists
        FileUtils.mkdir_p(@plugin_install_dir)

        `gem install '#{name}'#{version_argument} --install-dir '#{@plugin_install_dir}'`
      end

      def version_argument
        return nil unless @version

        " -v '#{@version}'"
      end
    end
  end
end
