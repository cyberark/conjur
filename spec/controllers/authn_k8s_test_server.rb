require 'rack'
require 'faye/websocket'
require 'pathname'

Faye::WebSocket.load_adapter('thin')

class AuthnK8sTestServer
    attr_reader :copied_content
    attr_reader :subpath

    def initialize(subpath)
        @subpath = Pathname.new(subpath).to_s
    end

    def self.run(...)
        # TODO: find out how to get random ports
        Rack::Handler::Thin.run self.new(...), :Port => 1234, :Host => "0.0.0.0" do |server|
            puts "server running with port=#{server.port}, @subpath=#{server.app.subpath}"

        end
    end

    def self.run_async(...)
        Thread.new do
            self.run(...)
        end
    end

    def ws_call(env)
        ws = Faye::WebSocket.new(env)
        r = Rack::Request.new(env)

        stdin = r.params["stdin"] == "true"
        
        ws.on :open do |event|
            p [:open]
            next if stdin

            ws.send("well then :)".bytes.unshift(1))
            ws.close(1000)
        end
        
        ws.on :message do |event|
            type, *message_bytes = event.data.bytes
            message = message_bytes.pack('c*')
            p [:message, type, message]

            path = "AAAA"
            tmp_cert = "AAAA"
            log_file = "AAAA"
            content = "AAAA"
            mode = "AAAA"
            
            escaped = Regexp.escape <<~BASH_SCRIPT
            #!/bin/sh
            set -e
            
            cleanup() {
              rm -f "#{tmp_cert}"
            }
            trap cleanup EXIT
            
            set_file_content() {
              cat > "#{tmp_cert}" <<EOF
            #{content}
            EOF
            
              chmod "#{mode}" "#{tmp_cert}"
              mv "#{tmp_cert}" "#{path}"
            }
            
            set_file_content > "#{log_file}" 2>&1
            BASH_SCRIPT
            escaped = escaped.gsub("AAAA", "(.*)")
            

            @copied_content = message.match(Regexp.new(escaped)).captures[2]
            p [:cert, @copied_content]
            ws.close(1000)
        end
    
    
        ws.on :close do |event|
          p [:close, event.code, event.reason]
          ws = nil
        end
    
        # Return async Rack response
        ws.rack_response
    end

    def call(env)
        req = Rack::Request.new(env)
        puts "[authn-k8s test server] Handling request: #{req.request_method} path=#{req.fullpath}"

        return ws_call(env) if Faye::WebSocket.websocket?(env)

        if req.fullpath == "#{subpath}/api/v1"
            [ 200, {"Content-Type" => "application/json"}, [File.read("./spec/controllers/good:api.v1.json")] ]
        elsif req.fullpath == "#{subpath}/api"
            [ 200, {"Content-Type" => "application/json"}, [File.read("./spec/controllers/good:api.json")] ]
        elsif req.fullpath == "#{subpath}/apis"
            [ 200, {"Content-Type" => "application/json"}, [File.read("./spec/controllers/good:apis.json")] ]
        elsif req.fullpath.start_with?("#{subpath}/apis/")
            [ 200, {"Content-Type" => "application/json"}, [File.read("./spec/controllers/good:apis.all.json")] ]
        elsif req.fullpath == "#{subpath}/api/v1/namespaces/default/pods/bash-8449b79d7-c2fwd"
            [ 200, {"Content-Type" => "application/json"}, [File.read("./spec/controllers/good:api.v1.getpod.json")] ]
        elsif req.fullpath == "#{subpath}/api/v1/namespaces?labelSelector=field.cattle.io%2FprojectId%3Dp-q7s7z&fieldSelector=metadata.name%3Ddefault"
            [ 200, {"Content-Type" => "application/json"}, [File.read("./spec/controllers/good:api.v1.getnamespaces.json")] ]
        elsif req.fullpath.start_with?("#{subpath}/api/v1/namespaces?")
            [ 200, {"Content-Type" => "application/json"}, [File.read("./spec/controllers/bad:api.v1.getnamespaces.json")] ]
        elsif req.fullpath == "#{subpath}/unauthorized"
            [ 401, {"Content-Type" => "application/json"}, [File.read("./unauthorized.json")] ]
        else
            [ 200, {'Content-Type' => "application/json"}, [''] ]
        end
    end
end
