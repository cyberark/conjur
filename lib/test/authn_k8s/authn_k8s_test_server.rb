require 'rack'
require 'faye/websocket'
require 'pathname'
require 'rack/handler/puma'

Faye::WebSocket.load_adapter('puma')

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

    def self.run_server_instance(test_server)
        port = 1234

        Rack::Handler::Puma.run test_server, :Port => port, :Host => "0.0.0.0", :workers => 0 do |launcher|
            AuthnK8sTestServer.log("Server running with port=#{port}, @subpath=#{test_server.subpath}")

            yield(launcher) if block_given?
        end
    end

    # Runs the test server and blocks until there's an interrupt
    def self.run(...)
        # TODO: find out how to get random ports
        test_server = self.new(...)
        self.run_server_instance(test_server)
    end

    # Runs the test server in a non-main thread, then executes block in main thread. This function cleans up the test server when the block completes execution or raises an exception
    def self.run_async(...)
        if !block_given?
            raise "run_async requires a block"
        end

        test_server = self.new(...)
        launcher = nil
        Thread.new do
            self.run_server_instance(test_server) do |_launcher|
                launcher = _launcher
            end
        end

        begin
            sleep(0.1)
            yield(test_server)
        ensure
            # clean up
            launcher.stop if launcher
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
            # log_event([:message, type, message])

            @copied_content = AuthnK8sTestServer.match_script(message).captures[2]
            # AuthnK8sTestServer.log("Updated @copied_content: \n#{copied_content}")
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
