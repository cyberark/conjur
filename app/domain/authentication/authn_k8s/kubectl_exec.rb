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

    class Messages
      attr_reader :messages
      
      def initialize
        @messages = Hash.new { |hash,key| hash[key] = [] }
      end

      def save_message(msg, stream: nil)
        strm ||= stream(msg)
        raise "Unexpected channel: #{channel(msg)}" unless strm
        @messages[strm.to_sym] << msg
      end

      def stream(msg)
        stream_name(channel_from_message(msg))
      end

      def msg_data(msg)
        msg.data[1..-1]
      end

      # NOTE: yes, a hash would be more efficient, but it doesn't matter
      #
      def channel(stream_name)
        stream_names.index(stream_name)
      end

      def stream_name(channel)
        stream_names[channel]
      end

      private

      def channel_from_message(msg)
        # THIS LINE WAS THE FIX
        return channel('error') unless msg.respond_to?(:data)
        msg.data[0..0].bytes.first
      end

      def stream_names
        %[stdin stdout stderr error resize]
      end
    end

    class StreamState
      def initialize
        @closed = false
      end

      def close
        @closed = true
      end

      def closed?
        @closed
      end
    end
    
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
        timeout: 5.seconds
      )
        @pod_name = pod_name
        @pod_namespace = pod_namespace
        @container = container
        @timeout = timeout
        @logger = logger
        @kubeclient = kubeclient

        @messages = Messages.new
        @stream_state = StreamState.new
      end

      def execute(cmds, body: "", stdin: false)
        ws = websocket_client(cmds, stdin)

        add_websocket_event_handlers(ws, stdin)
        #add_simple_event_handlers(ws, stdin)

        #url = server_url(cmds, stdin)
        #ws.connect(url, headers: headers)

        # JT: I *think* the connection is not being established until this
        # method exists, which means the open callback never gets hit and
        # the CommandTimeOut error is raised before a connection is established.

        puts "*** puts newline"
        
        ws.send_msg("\n") #TODO: remove or add comment why this is needed
        wait_for_close_message(ws)

        raise CommandTimedOut.new(@container, @pod_name) unless @stream_state.closed?
        
        # TODO: raise an `WebsocketServerFailure` here in the case of ws :error
#        ws.messages

        @messages.messages
      end
      
      def copy(path, content, mode)
        execute(
          [ 'tar', 'xvf', '-', '-C', '/' ],
          stdin: true,
          body: generate_file_tar_string(path, content, mode)
        )
      end

      private
=begin
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
=end
      def add_websocket_event_handlers(ws, stdin)
        # These callbacks have access to local variables, but we can't use the
        # instance variables because 'self' is not KubectlExec. Make some local
        # vars to pass the instance variables in.
        logger = @logger
        messages = @messages
        stream_state = @stream_state
        
        ws.on(:message) do |msg|
          if msg.type == :binary
            puts "* BINARY!"
            messages.save_message(ws.msg_data(msg))
            logger.debug("Pod #{@pod_name}, stream #{messages.stream(msg)}: #{messages.msg_data(msg)}")
          elsif msg.type == :close
            puts "* CLOSED!"
            stream_state.close
            logger.debug("Pod: #{@pod_name}, message: close, data: #{messages.msg_data(msg)}")
          end
        end

        ws.on :open do
          puts "*** OPEN!"
          
          hs = ws.handshake

          if hs.error
            puts "handshake err: #{hs.error}"
            emit(:error, messages.messages)
          else
            puts "*** IT WORKED!"
            logger.debug("Pod #{@pod_name} : channel open")

            if stdin
              data = messages.channel('stdin').chr + body
              ws.send_msg(data)
              ws.send_msg(nil, type: :close)
            end
          end
        end

        ws.on(:close) do |e|
          puts "*** CLOSE!"
          
          stream_state.close
          logger.debug("Pod #{@pod_name} : channel closed")
        end

        ws.on(:error) do |e|
          puts "*** ERROR!"
          puts e.inspect
          
          stream_state.close
          logger.debug("Pod #{@pod_name} error: #{e.inspect}")
          
          messages.save_message(e.inspect, stream: "error")
        end
      end

      def wait_for_close_message(ws)
        (@timeout / 0.1).to_i.times do
          puts "*** wait for close..."
          break if @stream_state.closed?
          sleep 0.1
        end
      end

      # Decorates the websocket gem's default client with the ability to save
      # messages, and to hold objects that can be used within the callback
      # blocks, to allow features like logging
      #
      def websocket_client(cmds, stdin)
        url = server_url(cmds, stdin)

        puts "*** connecting to: #{url}"
        
        WebSocket::Client::Simple.connect(url, headers: headers)
        #ws = WebSocket::Client::Simple::Client.new
#        ws = Util::WebSocket::WithMessageSaving.new(ws)
        #        Util::WebSocket::WithAttributes.new(ws, websocket_client_attrs)
      end

#      def websocket_client_attrs
#        stream_state = Util::WebSocket::StreamState.new
#        {logger: @logger, pod_name: @pod_name, stream_state: stream_state}
#      end

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
        base_url = "wss://#{api_uri.host}:#{api_uri.port}"
        path = "/api/v1/namespaces/#{@pod_namespace}/pods/#{@pod_name}/exec"
        query = query_string(cmds, stdin)
        "#{base_url}#{path}?#{query}"
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
