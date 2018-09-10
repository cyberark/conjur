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

      def save_message(msg)
        strm ||= stream_name(msg)
        raise "Unexpected channel: #{channel(msg)}" unless strm
        @messages[strm.to_sym] << msg_data(msg)
      end

      def save_string(str, stream: nil)
        @messages[stream] << str
      end

      def stream_name(msg)
        stream_names[channel_from_message(msg)]
      end

      def msg_data(msg)
        msg.data[1..-1]
      end

      def channel(stream_name)
        stream_names.index(stream_name)
      end

      private

      def channel_from_message(msg)
        return channel('error') unless msg.respond_to?(:data)
        msg.data[0..0].bytes.first
      end

      def stream_names
        %w[stdin stdout stderr error resize]
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
        url = server_url(cmds, stdin)
        headers = @kubeclient.headers.clone
        WebSocket::Client::Simple.connect(url, headers: headers)

        add_websocket_event_handlers(ws, body, stdin)

        wait_for_close_message(ws)

        raise CommandTimedOut.new(@container, @pod_name) unless @stream_state.closed?
        
        # TODO: raise an `WebsocketServerFailure` here in the case of ws :error

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

      def add_websocket_event_handlers(ws, body, stdin)
        # These callbacks have access to local variables, but we can't use the
        # instance variables because 'self' is not KubectlExec. Make some local
        # vars to pass the instance variables in.
        pod_name = @pod_name
        logger = @logger
        messages = @messages
        stream_state = @stream_state
        
        ws.on(:message) do |msg|
          if msg.type == :binary
            messages.save_message(msg)
            logger.debug("Pod #{pod_name}, stream #{messages.stream_name(msg)}: #{messages.msg_data(msg)}")
          elsif msg.type == :close
            logger.debug("Pod: #{pod_name}, message: close, data: #{messages.msg_data(msg)}")
            close
          end
        end

        ws.on :open do
          hs = ws.handshake

          if hs.error
            emit(:error, messages.messages)
          else
            logger.debug("Pod #{pod_name} : channel open")

            if stdin
              data = messages.channel('stdin').chr + body
              ws.send_msg(data)
              ws.send_msg(nil, type: :close)
            end
          end
        end

        ws.on(:close) do |e|
          stream_state.close
          logger.debug("Pod #{pod_name} : channel closed")
        end

        ws.on(:error) do |e|
          stream_state.close
          logger.debug("Pod #{pod_name} error : #{e.inspect}")
          
          messages.save_string(e.inspect, stream: :error)
        end
      end

      def wait_for_close_message(ws)
        (@timeout / 0.1).to_i.times do
          break if @stream_state.closed?
          sleep 0.1
        end
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
        base_url = "wss://#{api_uri.host}:#{api_uri.port}"
        path = "/api/v1/namespaces/#{@pod_namespace}/pods/#{@pod_name}/exec"
        query = query_string(cmds, stdin)
        "#{base_url}#{path}?#{query}"
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
