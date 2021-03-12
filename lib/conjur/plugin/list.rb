module Conjur
  module Plugin
    class List
      def initialize(
        plugin_install_dir: './plugins/installed',
        plugin_enable_dir: './plugins/enabled',
        print_stream: $stdout
      )
        @plugin_install_dir = plugin_install_dir
        @plugin_enable_dir = plugin_enable_dir
        @print_stream = print_stream
      end

      def call
        print_installed_plugins
        @print_stream.puts # empty line
        print_enabled_plugins
      end

      private

      def print_installed_plugins
        @print_stream.puts "Installed Plugins: "
        results = Dir["#{@plugin_install_dir}/specifications/*.gemspec"]

        @print_stream.puts '  (None)' if results.empty?

        results.each do |plugin|
          spec = Gem::Specification.load(plugin)

          @print_stream.puts " - name: #{spec.name}"
          @print_stream.puts "   version: #{spec.version}"
          @print_stream.puts "   author: #{spec.author} <#{spec.email}>"
        end
      end

      def print_enabled_plugins
        @print_stream.puts "Enabled Plugins: "
        results = Dir["#{@plugin_enable_dir}/*.gemspec"]
        
        @print_stream.puts '  (None)' if results.empty?

        results.each do |plugin|
          spec = Gem::Specification.load(plugin)

          @print_stream.puts " - name: #{spec.name} (#{spec.version})"
        end
      end
    end
  end
end
