module Conjur
  module Plugin
    class RequirePaths
      def initialize(
        plugin_install_dir: './plugins/installed',
        plugin_enable_dir: './plugins/enabled'
      )
        @plugin_install_dir = plugin_install_dir
        @plugin_enable_dir = plugin_enable_dir
      end

      def call
        Dir["#{@plugin_enable_dir}/*.gemspec"].map do |plugin|
          spec = Gem::Specification.load(plugin)

          File.join(
            @plugin_install_dir,
            'gems',
            "#{spec.name}-#{spec.version}",
            spec.require_path
          )
        end
      end
    end
  end
end
