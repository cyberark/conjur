# Collect messages and return them
# Log certain things to a logger
#
#
#
require 'uri'
require 'websocket'
require 'rubygems/package'

require 'active_support/time'
require 'websocket-client-simple'
require 'pry'

#require 'util/error_class'
#require 'util/web_socket/stream_state'
#require 'util/web_socket/with_attributes'
#require 'util/web_socket/with_message_saving'
#require 'util/web_socket/stream_state'

module WebSocket
  module Client
    module Simple
      class Client
        alias_method :send_msg, :send
      end
    end
  end
end

module Authentication
  module AuthnK8s
    CommandTimedOut = ::Util::ErrorClass.new(
      "Command timed out in container '{0}' of pod '{1}'"
    )
    
    class KubectlExec
      # logger: an object responding to `debug`
      # kubeclient: Kubeclient::Client from "kubeclient" gem
      #
      def initialize(
        pod_name:,
        pod_namespace:,
        logger:,
        kubeclient:,
        container: 'authentication',
        timeout: 1.seconds
      )
        @pod_name = pod_name
        @pod_namespace = pod_namespace
        @container = container
        @timeout = timeout
        @logger = logger
        @kubeclient = kubeclient
      end

      def execute(cmds, body: "", stdin: false)
        ws = websocket_client(cmds, stdin)

        add_websocket_event_handlers(ws, stdin)
        #add_simple_event_handlers(ws, stdin)

        url = server_url(cmds, stdin)
        ws.connect(url, headers: headers)

        # JT: I *think* the connection is not being established until this
        # method exists, which means the open callback never gets hit and
        # the CommandTimeOut error is raised before a connection is established.
        

        ws.send_msg("\n") #TODO: remove or add comment why this is needed
        wait_for_close_message(ws)
        
        puts "*** puts newline"
        
        raise CommandTimedOut, @container, @pod_name unless closed?(ws)
        
        # TODO: raise an `WebsocketServerFailure` here in the case of ws :error
        ws.messages
      end
      
      def copy(path, content, mode)
        exec(
          [ 'tar', 'xvf', '-', '-C', '/' ],
          stdin: true,
          body: generate_file_tar_string(path, content, mode)
        )
      end

      private

      def closed?(ws)
        ws.stream_state.closed?
      end

      def add_simple_event_handlers(ws, stdin)
        ws.on :open do
          puts "*** OPEN!"
          ws.send_msg("hello world")
        end
        
        ws.on :message do |msg|
          puts "*** MESSAGE!"
          puts msg.to_s
        end

        ws.on :error do |e|
          puts "*** ERROR!"
          puts e
        end
      end

      def add_websocket_event_handlers(ws, stdin)
        # NOTE: `logger` here calls the method `logger` created by
        # `WithAttributes`, and returns @logger (the one from KubectlExec)  In
        # this way we avoid the "self" problems inherent in the callback blocks
        #
        
        ws.on(:message) do |msg|
          puts "*** MESSAGE!"
          p msg
          # if msg.type == 'binary'
          if msg.type == 'text'
            ws.save_message(ws.msg_data(msg))
            #TODO fix pod_name
            ws.logger.debug("Pod #{@pod_name}, stream #{ws.stream(msg)}: #{ws.msg_data(msg)}")
          elsif msg.type == 'close'
            ws.stream_state.close
            ws.logger.debug("Pod: #{@pod_name}, message: close, data: #{ws.msg_data(msg)}")
          end
        end

        ws.on :open do
          puts "*** OPEN!"
          hs = ws.handshake

          if hs.error
            emit(:error, ws.messages)
          else
            puts "WORKED"
            ws.logger.debug("Pod #{@pod_name} : channel open")

            if stdin
              data = ws.channel('stdin').chr + body
              ws.send_msg(data)
              ws.send_msg(nil, type: :close)
            end
          end
        end

        ws.on(:close) do |e|
          puts "*** CLOSE!"
          ws.stream_state.close
          ws.logger.debug("Pod #{@pod_name} : channel closed")
        end

        ws.on(:error) do |e|
          puts "*** ERROR!"
          puts e.inspect
          ws.stream_state.close
          ws.logger.debug("Pod #{@pod_name} error: #{e.inspect}")
          ws.save_message(e.inspect, stream: "error")
        end
      end

      def wait_for_close_message(ws)
        (@timeout / 0.1).to_i.times do
          puts "*** wait for close..."
          break if closed?(ws)
          sleep 0.1
        end
      end

      # Decorates the websocket gem's default client with the ability to save
      # messages, and to hold objects that can be used within the callback
      # blocks, to allow features like logging
      #
      def websocket_client(cmds, stdin)
        url = server_url(cmds, stdin)
        #ws = WebSocket::Client::Simple.connect(url, headers: headers)
        ws = WebSocket::Client::Simple::Client.new
        ws = Util::WebSocket::WithMessageSaving.new(ws)
        Util::WebSocket::WithAttributes.new(ws, websocket_client_attrs)
      end

      def websocket_client_attrs
        stream_state = Util::WebSocket::StreamState.new
        {logger: @logger, pod_name: @pod_name, stream_state: stream_state}
      end

      def query_string(cmds, stdin)
        stdin_part = stdin ? ['stdin=true'] : []
        cmds_part = cmds.map { |c| "command=#{CGI.escape(c)}" }
        (base_query_string_parts + stdin_part + cmds_part).join("&")
      end

      def base_query_string_parts
        [ "container=#{CGI.escape(@container)}", "stderr=true", "stdout=true" ]
      end

      def server_url(cmds, stdin)
        api_uri = @kubeclient.api_endpoint
        base_url = "ws://#{api_uri.host}:#{api_uri.port}"
        path = "/api/v1/namespaces/#{@pod_namespace}/pods/#{@pod_name}/exec"
        query = query_string(cmds, stdin)
        "#{base_url}#{path}?#{query}"
        #TODO: remove
        base_url
      end

      def headers
        @kubeclient.headers.clone
      end

      def generate_file_tar_string(path, content, mode)
        tarfile = StringIO.new("")
        Gem::Package::TarWriter.new(tarfile) do |tar|
          tar.add_file(path, mode) do |tf|
            tf.write(content)
          end
        end

        tarfile.string
      end

    end
  end
end
