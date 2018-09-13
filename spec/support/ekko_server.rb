require 'rubygems'
require 'rack'

module MyApp
  module Test
    class Server
      def call(env)

        puts "***** HI THIS IS THE SERVER"
        [ 200, {}, "WOOOOO" ]
        
=begin        
        @root = File.expand_path(File.dirname(__FILE__))
        path = Rack::Utils.unescape(env['PATH_INFO'])
        path += 'index.html' if path == '/'
        file = @root + "#{path}"

        params = Rack::Utils.parse_nested_query(env['QUERY_STRING'])

        if File.exists?(file)
          [ 200, {"Content-Type" => "text/html"}, File.read(file) ]
        else
          [ 404, {'Content-Type' => 'text/plain'}, 'file not found' ]
        end
=end
      end
    end
  end
end
