# https://raw.github.com/merb/merb/master/merb-core/lib/merb-core/rack/middleware/path_prefix.rb
module Conjur
  module Rack
    class PathPrefix
      EMPTY_STRING = ""
      SLASH = "/"
      
      # @api private
      def initialize(app, path_prefix = nil)
        @app = app
        @path_prefix = /^#{Regexp.escape(path_prefix)}/
      end

      # @api plugin
      def call(env)
        strip_path_prefix(env) 
        @app.call(env)
      end

      # @api private
      def strip_path_prefix(env)
        ['PATH_INFO', 'REQUEST_URI'].each do |path_key|
          if env[path_key] =~ @path_prefix
            env[path_key].sub!(@path_prefix, EMPTY_STRING)
            env[path_key] = SLASH if env[path_key].empty?
          end
        end
      end
    end
  end
end