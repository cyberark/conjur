require 'rack'
require 'faye/websocket'
require 'pathname'

Faye::WebSocket.load_adapter('thin')

class AuthnK8sTestServer
    attr_reader :copied_content
    attr_reader :subpath
    attr_reader :bearer_token

    def initialize(subpath: "", bearer_token: "")
        @subpath = Pathname.new(subpath).to_s
        @bearer_token = bearer_token
    end

    def self.read_response_file(relative_path)
        File.read(File.join(File.dirname(__FILE__), relative_path))
    end

    def self.log(...)
        print("[authn-k8s test server] ")
        puts(...)
    end

    def self.run(...)
        # TODO: find out how to get random ports
        test_server = self.new(...)
        Rack::Handler::Thin.run test_server, :Port => 1234, :Host => "0.0.0.0" do |server|
            Thread.current[:authn_k8s_test_server] = test_server
            AuthnK8sTestServer.log("Server running with port=#{server.port}, @subpath=#{server.app.subpath}")
        end
    end

    def self.run_async(...)
        Thread.new do
            self.run(...)
        end
    end

    def self.match_script(str)
        path = "AAAA"
        tmp_cert = "AAAA"
        log_file = "AAAA"
        content = "AAAA"
        mode = "AAAA"

        escaped = <<~BASH_SCRIPT
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
        escaped = Regexp.escape escaped
        escaped = escaped.gsub("AAAA", "(.*)")

        str.match(Regexp.new(escaped, Regexp::MULTILINE))
    end

    def ws_call(env)
        ws = Faye::WebSocket.new(env)
        r = Rack::Request.new(env)

        stdin = r.params["stdin"] == "true"

        def log_event(*args)
            AuthnK8sTestServer.log("Web socket event for request: #{args.flatten(1)}")
        end
        
        ws.on :open do |event|
            log_event([:open])
            next if stdin

            # Below is an example of the server writing to the client via websockets
            # ws.send("well then :)".bytes.unshift(1))
            ws.close(1000)
        end
        
        ws.on :message do |event|
            type, *message_bytes = event.data.bytes
            message = message_bytes.pack('c*')
            log_event([:message, type])

            @copied_content = AuthnK8sTestServer.match_script(message).captures[2]
            ws.close(1000)
        end
    
    
        ws.on :close do |event|
            log_event([:close, event.code, event.reason])
          ws = nil
        end
    
        # Return async Rack response
        ws.rack_response
    end

    def call(env)
        req = Rack::Request.new(env)
        AuthnK8sTestServer.log("Handling request: #{req.request_method} path=#{req.fullpath}")

        if env['HTTP_AUTHORIZATION'] != "Bearer #{bearer_token}"
            return [ 401, {"Content-Type" => "application/json"}, [AuthnK8sTestServer.read_response_file("unauthorized.json")] ]
        end

        return ws_call(env) if Faye::WebSocket.websocket?(env)

        if req.path == "#{subpath}/api/v1"
            [ 200, {"Content-Type" => "application/json"}, [AuthnK8sTestServer.read_response_file("good:api.v1.json")] ]
        elsif req.path == "#{subpath}/api"
            [ 200, {"Content-Type" => "application/json"}, [AuthnK8sTestServer.read_response_file("good:api.json")] ]
        elsif req.path == "#{subpath}/apis"
            [ 200, {"Content-Type" => "application/json"}, [AuthnK8sTestServer.read_response_file("good:apis.json")] ]
        elsif req.path.start_with?("#{subpath}/apis/")
            [ 200, {"Content-Type" => "application/json"}, [AuthnK8sTestServer.read_response_file("good:apis.all.json")] ]
        elsif req.path == "#{subpath}/api/v1/namespaces/default/pods/bash-8449b79d7-c2fwd"
            [ 200, {"Content-Type" => "application/json"}, [AuthnK8sTestServer.read_response_file("good:api.v1.getpod.json")] ]
        elsif req.path.start_with?("#{subpath}/api/v1/namespaces/default/pods/")
            [ 404, {"Content-Type" => "application/json"}, [AuthnK8sTestServer.read_response_file("bad:api.v1.getpod.json")] ]
        elsif req.fullpath == "#{subpath}/api/v1/namespaces?labelSelector=field.cattle.io%2FprojectId%3Dp-q7s7z&fieldSelector=metadata.name%3Ddefault"
            [ 200, {"Content-Type" => "application/json"}, [AuthnK8sTestServer.read_response_file("good:api.v1.getnamespaces.json")] ]
        elsif req.path.start_with?("#{subpath}/api/v1/namespaces")
            [ 200, {"Content-Type" => "application/json"}, [AuthnK8sTestServer.read_response_file("bad:api.v1.getnamespaces.json")] ]
        else
            [ 200, {'Content-Type' => "application/json"}, ['{}'] ]
        end
    end
end
