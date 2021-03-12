module Conjur
  module Plugin
    class Disable
      def initialize(
        plugin_enable_dir: './plugins/enabled'
      )
        @plugin_enable_dir = plugin_enable_dir
      end

      def call(
        name:,
        version: nil,
        force: false
      )
        @name = name
        @version = version
        raise "Plugin '#{@name}' is not enabled." unless enabled_spec || force

        File.delete(enabled_spec_path) if File.exist?(enabled_spec_path)
      end

      def enabled_spec
        @enabled_spec ||= Gem::Specification.load(enabled_spec_path)
      end

      def enabled_spec_path
        # TODO: account for a specific version
        Dir["#{@plugin_enable_dir}/#{@name}-*.gemspec"].first.to_s
      end
    end
  end
end
